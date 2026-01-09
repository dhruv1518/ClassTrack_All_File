import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart'; // Commented out - not needed
import 'settings_page.dart';
import 'support_page.dart';
import 'login.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.email)
          .get();
      setState(() {
        _profileImageUrl = doc.data()?['profileImageUrl'] as String?;
      });
    } catch (e) {
      // ignore any error, show no image
    }
    setState(() => _loading = false);
  }

  // ❌ COMMENTED OUT: Image picker functionality
  /*
  Future<void> _pickImage() async {
    setState(() => _loading = true);

    try {
      Uint8List? fileBytes;

      if (kIsWeb) {
        // Web implementation
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);

        if (image == null) {
          setState(() => _loading = false);
          return;
        }

        fileBytes = await image.readAsBytes();
      } else {
        // Mobile implementation using image_picker
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 75,
        );

        if (image == null) {
          setState(() => _loading = false);
          return;
        }

        fileBytes = await image.readAsBytes();
      }

      if (fileBytes != null) {
        setState(() {
          _profileImage = fileBytes;
        });

        // Upload to Firebase Storage
        String fileName = "profiles/${widget.email}_profile.jpg";
        try {
          var ref = FirebaseStorage.instance.ref().child(fileName);
          await ref.putData(fileBytes);
          String downloadUrl = await ref.getDownloadURL();

          // Save to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.email)
              .set({'profileImageUrl': downloadUrl}, SetOptions(merge: true));

          setState(() {
            _profileImageUrl = downloadUrl;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile image updated successfully!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _loading = false);
  }
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
    setState(() => _editMode = false);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.email)
          .set({
        'name': _nameController.text,
        'enrollment': _enrollmentController.text,
        'email': _emailController.text,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account details saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving details: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => StudentLoginPage()),
          (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out')),
    );
  }

  void _showChangePasswordDialog() {
    TextEditingController oldPassCtrl = TextEditingController();
    TextEditingController newPassCtrl = TextEditingController();
    TextEditingController confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassCtrl,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassCtrl,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPassCtrl,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('Update', style: TextStyle(color: Colors.white)),
            onPressed: () {
              if (newPassCtrl.text != confirmPassCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match'), backgroundColor: Colors.red),
                );
              } else if (newPassCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New password too short'), backgroundColor: Colors.red),
                );
              } else {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password changed successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A9D8F)),
          ),
        ],
      ),
    );
  }

  Widget _featureTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A9D8F).withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF2A9D8F), size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: Color(0xFF264653),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B3C53),
        title: const Text('Student Account', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.check : Icons.edit, color: Colors.white),
            tooltip: _editMode ? 'Save' : 'Edit',
            onPressed: _editMode ? _saveChanges : _toggleEditMode,
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(fontSize: 16)),
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
                  // ❌ COMMENTED OUT: Use _profileImage
                  // backgroundImage: _profileImage != null
                  //     ? MemoryImage(_profileImage!)
                  //     : (_profileImageUrl != null
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : const AssetImage('images/profile2.jpeg') as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 6,
                  child: GestureDetector(
                    // ❌ COMMENTED OUT: Use _pickImage
                    // onTap: _pickImage,
                    onTap: _showImageUploadDisabledMessage, // ✅ Shows disabled message instead
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey, // ✅ Changed to grey to show it's disabled
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 21,
                color: Color(0xFF264653),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _emailController.text,
              style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 15),
            ),
          ),
          const SizedBox(height: 20),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _editMode
                      ? TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  )
                      : Row(
                    children: [
                      const Icon(Icons.person_outline, color: Color(0xFF2A9D8F)),
                      const SizedBox(width: 12),
                      const Text('Name: ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653))),
                      Expanded(
                        child: Text(_nameController.text,
                            style: const TextStyle(color: Color(0xFF7A7A7A))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _editMode
                      ? TextField(
                    controller: _enrollmentController,
                    decoration: const InputDecoration(labelText: 'Enrollment no.'),
                  )
                      : Row(
                    children: [
                      const Icon(Icons.badge_outlined, color: Color(0xFFE9C46A)),
                      const SizedBox(width: 12),
                      const Text('Enrollment: ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653))),
                      Expanded(
                        child: Text(_enrollmentController.text,
                            style: const TextStyle(color: Color(0xFF7A7A7A))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _editMode
                      ? TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  )
                      : Row(
                    children: [
                      const Icon(Icons.alternate_email, color: Color(0xFF264653)),
                      const SizedBox(width: 12),
                      const Text('Email: ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653))),
                      Expanded(
                        child: Text(_emailController.text,
                            style: const TextStyle(color: Color(0xFF7A7A7A))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Account Features',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF264653)),
          ),
          const SizedBox(height: 4),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                _featureTile(
                  icon: Icons.lock_outline,
                  title: "Change Password",
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(),
                _featureTile(
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SettingsPage()),
                    );
                  },
                ),
                const Divider(),
                _featureTile(
                  icon: Icons.support_agent_outlined,
                  title: "Support",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SupportPage()),
                    );
                  },
                ),
                const Divider(),
                _featureTile(
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
