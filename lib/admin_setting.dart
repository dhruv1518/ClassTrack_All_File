import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'admin_login_page.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({Key? key}) : super(key: key);

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _notificationsEnabled = true;
  String _language = 'English';
  String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: tp.scaffoldBg,
      appBar: AppBar(
        backgroundColor: tp.appBarBg,
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          _buildSectionHeader("Appearance", tp.secondaryText),
          SwitchListTile(
            title: Text(
              'Dark Mode',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: tp.secondaryText,
              ),
            ),
            value: tp.isDarkMode,
            onChanged: (_) => tp.toggleDarkMode(),
            secondary: Icon(Icons.brightness_6, color: tp.secondaryText),
          ),
          Divider(height: 32, color: tp.dividerColor),

          _buildSectionHeader("Notifications", tp.secondaryText),
          SwitchListTile(
            title: Text(
              'Enable Notifications',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: tp.secondaryText,
              ),
            ),
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
            secondary: Icon(
              Icons.notifications_active,
              color: tp.secondaryText,
            ),
          ),
          Divider(height: 32, color: tp.dividerColor),

          _buildSectionHeader("Preferences", tp.secondaryText),
          ListTile(
            leading: Icon(Icons.language, color: tp.secondaryText),
            title: Text(
              "Language",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: tp.secondaryText,
              ),
            ),
            subtitle: Text(
              _language,
              style: TextStyle(color: tp.inactiveColor),
            ),
            trailing: Icon(Icons.keyboard_arrow_right, color: tp.secondaryText),
            onTap: () => _showLanguageDialog(),
          ),

          Divider(height: 32, color: tp.dividerColor),

          _buildSectionHeader("About", tp.secondaryText),
          ListTile(
            leading: Icon(Icons.info_outline, color: tp.secondaryText),
            title: Text(
              "App Version",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: tp.secondaryText,
              ),
            ),
            subtitle: Text(
              _appVersion,
              style: TextStyle(color: tp.inactiveColor),
            ),
          ),

          SizedBox(height: 40),

          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => AdminLoginPage()),
                  (route) => false,
                );
              },
              icon: Icon(Icons.logout),
              label: Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: color,
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) {
        return SimpleDialog(
          backgroundColor: tp.cardBg,
          title: Text(
            "Select Language",
            style: TextStyle(color: tp.primaryText),
          ),
          children: [
            SimpleDialogOption(
              child: Text("English", style: TextStyle(color: tp.primaryText)),
              onPressed: () {
                setState(() {
                  _language = "English";
                });
                Navigator.pop(context);
              },
            ),
            SimpleDialogOption(
              child: Text("Hindi", style: TextStyle(color: tp.primaryText)),
              onPressed: () {
                setState(() {
                  _language = "Hindi";
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
