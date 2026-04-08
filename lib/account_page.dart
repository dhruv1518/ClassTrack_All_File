import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'settings_page.dart';
import 'pomodoro_page.dart';
import 'login.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'analytics_service.dart';
import 'auth_service.dart';

// ❌ COMMENTED OUT: Image picker imports
// import 'package:image_picker/image_picker.dart';
// import 'dart:io' if (dart.library.html) 'dart:html' as platform;

class AccountPage extends StatefulWidget {
  final String name;
  final String enrollment;
  final String email;

  const AccountPage({
    super.key,
    required this.name,
    required this.enrollment,
    required this.email,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late TextEditingController _nameController;
  late TextEditingController _enrollmentController;
  late TextEditingController _emailController;

  // ❌ COMMENTED OUT: Profile image variables
  // Uint8List? _profileImage;
  String? _profileImageUrl;
  bool _editMode = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _enrollmentController = TextEditingController(text: widget.enrollment);
    _emailController = TextEditingController(text: widget.email);
    _fetchProfileImage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _enrollmentController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileImage() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        var doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        setState(() {
          _profileImageUrl = doc.data()?['profileImageUrl'] as String?;
        });
      }
    } catch (e) {
      // ignore any error, show no image
    }
    setState(() => _loading = false);
  }

  // ❌ COMMENTED OUT: Image picker functionality
  /*
  Future<void> _pickImage() async { ... }
  */

  // ✅ PLACEHOLDER: Show message when camera is tapped
  void _showImageUploadDisabledMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image upload is currently disabled'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _toggleEditMode() => setState(() => _editMode = !_editMode);

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Capture messenger & navigator BEFORE any async gap to avoid
    // `_dependents.isEmpty is not true` crash when context is stale.
    final messenger = ScaffoldMessenger.of(context);

    final newEmail = _emailController.text.trim();
    final currentEmail = user.email ?? '';
    final emailChanged = newEmail != currentEmail && newEmail.isNotEmpty;

    // If email is changing, require re-authentication first
    if (emailChanged) {
      final password = await _showReAuthDialog();
      if (password == null) return; // User cancelled

      try {
        // Re-authenticate
        final credential = EmailAuthProvider.credential(
          email: currentEmail,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);

        // Send verification to new email (email won't change until verified)
        await user.verifyBeforeUpdateEmail(newEmail);

        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'A verification email has been sent to your new address. '
              'Your email will update after you verify it.',
            ),
            duration: Duration(seconds: 5),
          ),
        );

        // Revert the email field to the current email since it hasn't changed yet
        _emailController.text = currentEmail;
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String msg = 'Failed to update email.';
        if (e.code == 'wrong-password') {
          msg = 'Incorrect password. Please try again.';
        } else if (e.code == 'invalid-credential') {
          msg = 'Incorrect password. Please try again.';
        } else if (e.code == 'too-many-requests') {
          msg = 'Too many attempts. Please try again later.';
        } else if (e.code == 'invalid-email') {
          msg = 'The new email address is invalid.';
        }
        messenger.showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
        return;
      }
    }

    // Save name and enrollment to Firestore (always allowed)
    if (!mounted) return;
    setState(() => _editMode = false);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'enrollment': _enrollmentController.text.trim(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Account details saved')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error saving details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Shows a dialog asking for the current password for re-authentication.
  /// Returns the password string, or null if the user cancelled.
  Future<String?> _showReAuthDialog() async {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    final passwordCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tp.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Confirm Password',
          style: TextStyle(color: tp.primaryText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'To change your email, please enter your current password.',
              style: TextStyle(color: tp.secondaryText),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              autofocus: true,
              style: TextStyle(color: tp.primaryText),
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: tp.secondaryText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.lock_outline, color: tp.secondaryText),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: tp.secondaryText)),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: tp.appBarBg),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            onPressed: () {
              if (passwordCtrl.text.isNotEmpty) {
                Navigator.of(context).pop(passwordCtrl.text);
              }
            },
          ),
        ],
      ),
    );
    passwordCtrl.dispose();
    return result;
  }

  Future<void> _logout() async {
    // Stop and reset Pomodoro timer so the next student starts fresh
    PomodoroTimerController.resetForNewUser();
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => StudentLoginPage()),
      (route) => false,
    );
  }

  // ── Student Self-View Analytics ──
  void _openStudentAnalytics() async {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data() ?? {};

    final score = AnalyticsService.computeEngagementScore(data);
    final label = AnalyticsService.engagementLabel(score);
    final logins = (data['totalLogins'] as int?) ?? 0;
    final tasks = (data['totalTasksCompleted'] as int?) ?? 0;
    final notes = (data['totalNotesCreated'] as int?) ?? 0;
    final pomodoro = (data['totalPomodoroSessions'] as int?) ?? 0;
    final streak = (data['currentStreak'] as int?) ?? 0;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: tp.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tp.inactiveColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'My Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tp.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your engagement score: $score/100 — $label',
              style: TextStyle(fontSize: 14, color: tp.secondaryText),
            ),
            const SizedBox(height: 20),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat(tp, Icons.login, '$logins', 'Logins'),
                _miniStat(tp, Icons.task_alt, '$tasks', 'Tasks'),
                _miniStat(tp, Icons.note_add, '$notes', 'Notes'),
                _miniStat(tp, Icons.timer, '$pomodoro', 'Pomodoro'),
              ],
            ),
            const SizedBox(height: 16),

            // Streak
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tp.accentTeal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orangeAccent,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$streak day streak!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: tp.primaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Privacy note
            Text(
              'Only aggregate counts are stored. Your notes, tasks, '
              'and calendar content remain fully private.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: tp.inactiveColor),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(
    ThemeProvider tp,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, color: tp.accentTeal, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: tp.primaryText,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: tp.secondaryText)),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    TextEditingController oldPassCtrl = TextEditingController();
    TextEditingController newPassCtrl = TextEditingController();
    TextEditingController confirmPassCtrl = TextEditingController();
    bool _isUpdating = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: tp.cardBg,
          title: Text(
            'Change Password',
            style: TextStyle(color: tp.primaryText),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassCtrl,
                style: TextStyle(color: tp.primaryText),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(color: tp.secondaryText),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassCtrl,
                style: TextStyle(color: tp.primaryText),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: tp.secondaryText),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                style: TextStyle(color: tp.primaryText),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: TextStyle(color: tp.secondaryText),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: _isUpdating
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: _isUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Update', style: TextStyle(color: Colors.white)),
              onPressed: _isUpdating
                  ? null
                  : () async {
                      if (newPassCtrl.text != confirmPassCtrl.text) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('New passwords do not match'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (newPassCtrl.text.length < 6) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'New password must be at least 6 characters',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setDialogState(() => _isUpdating = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null || user.email == null)
                          throw Exception('Not logged in');
                        // Re-authenticate with current password
                        final credential = EmailAuthProvider.credential(
                          email: user.email!,
                          password: oldPassCtrl.text,
                        );
                        await user.reauthenticateWithCredential(credential);
                        // Update to new password
                        await user.updatePassword(newPassCtrl.text);
                        Navigator.of(dialogContext).pop();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password changed successfully'),
                          ),
                        );
                      } on FirebaseAuthException catch (e) {
                        setDialogState(() => _isUpdating = false);
                        String msg = 'Failed to change password';
                        if (e.code == 'wrong-password')
                          msg = 'Current password is incorrect';
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => _isUpdating = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: tp.accentTeal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureTile({
    required ThemeProvider tp,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: tp.accentTeal.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: tp.accentTeal, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: tp.primaryText,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: tp.inactiveColor),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: tp.scaffoldBg,
      appBar: AppBar(
        backgroundColor: tp.appBarBg,
        title: const Text(
          'Student Account',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _editMode ? Icons.check : Icons.edit,
              color: Colors.white,
            ),
            tooltip: _editMode ? 'Save' : 'Edit',
            onPressed: _editMode ? _saveChanges : _toggleEditMode,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(fontSize: 16, color: tp.secondaryText),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : const AssetImage('images/profile2.jpeg')
                                  as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 6,
                        child: GestureDetector(
                          onTap: _showImageUploadDisabledMessage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tp.inactiveColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: tp.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _nameController.text,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 21,
                      color: tp.primaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _emailController.text,
                    style: TextStyle(color: tp.secondaryText, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 20),

                Card(
                  color: tp.cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _editMode
                            ? TextField(
                                controller: _nameController,
                                style: TextStyle(color: tp.primaryText),
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  labelStyle: TextStyle(
                                    color: tp.secondaryText,
                                  ),
                                ),
                              )
                            : Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    color: tp.accentTeal,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Name: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: tp.primaryText,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _nameController.text,
                                      style: TextStyle(color: tp.secondaryText),
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 12),
                        _editMode
                            ? TextField(
                                controller: _enrollmentController,
                                style: TextStyle(color: tp.primaryText),
                                decoration: InputDecoration(
                                  labelText: 'Enrollment no.',
                                  labelStyle: TextStyle(
                                    color: tp.secondaryText,
                                  ),
                                ),
                              )
                            : Row(
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    color: tp.accentAmber,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Enrollment: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: tp.primaryText,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _enrollmentController.text,
                                      style: TextStyle(color: tp.secondaryText),
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 12),
                        _editMode
                            ? TextField(
                                controller: _emailController,
                                style: TextStyle(color: tp.primaryText),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: TextStyle(
                                    color: tp.secondaryText,
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              )
                            : Row(
                                children: [
                                  Icon(
                                    Icons.alternate_email,
                                    color: tp.primaryText,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Email: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: tp.primaryText,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _emailController.text,
                                      style: TextStyle(color: tp.secondaryText),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  'Account Features',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: tp.primaryText,
                  ),
                ),
                const SizedBox(height: 4),

                Card(
                  color: tp.cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      _featureTile(
                        tp: tp,
                        icon: Icons.analytics_outlined,
                        title: "My Analytics",
                        onTap: () {
                          _openStudentAnalytics();
                        },
                      ),
                      Divider(color: tp.dividerColor),
                      _featureTile(
                        tp: tp,
                        icon: Icons.lock_outline,
                        title: "Change Password",
                        onTap: _showChangePasswordDialog,
                      ),
                      Divider(color: tp.dividerColor),
                      _featureTile(
                        tp: tp,
                        icon: Icons.settings_outlined,
                        title: "Settings",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SettingsPage()),
                          );
                        },
                      ),
                      Divider(color: tp.dividerColor),

                      _featureTile(
                        tp: tp,
                        icon: Icons.logout,
                        title: "Log Out",
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
