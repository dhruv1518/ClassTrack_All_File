import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _locationAccess = false;
  String _selectedLanguage = "English";

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Choose Language",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF264653))),
              Divider(),
              ListTile(
                title: Text("English"),
                onTap: () {
                  setState(() => _selectedLanguage = "English");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text("हिन्दी"),
                onTap: () {
                  setState(() => _selectedLanguage = "हिन्दी");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text("Español"),
                onTap: () {
                  setState(() => _selectedLanguage = "Espalier");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      activeColor: Color(0xFF2A9D8F),
      secondary: Icon(icon, color: Color(0xFF2A9D8F)),
      title: Text(title,
          style: TextStyle(color: Color(0xFF264653), fontWeight: FontWeight.w500)),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F2EC), // same beige background
      appBar: AppBar(
        backgroundColor: Color(0xFF264653), // dark navy
        title: Text("Settings", style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        children: [
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: "Dark Mode",
            value: _darkMode,
            onChanged: (val) => setState(() => _darkMode = val),
          ),
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: "Enable Notifications",
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
          ),
          _buildSwitchTile(
            icon: Icons.location_on_outlined,
            title: "Allow Location Access",
            value: _locationAccess,
            onChanged: (val) => setState(() => _locationAccess = val),
          ),
          ListTile(
            leading: Icon(Icons.language, color: Color(0xFF2A9D8F)),
            title: Text("Language",
                style: TextStyle(color: Color(0xFF264653), fontWeight: FontWeight.w500)),
            subtitle: Text(_selectedLanguage, style: TextStyle(color: Colors.grey[700])),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            onTap: _showLanguagePicker,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.security, color: Color(0xFF2A9D8F)),
            title: Text("Privacy & Security",
                style: TextStyle(color: Color(0xFF264653), fontWeight: FontWeight.w500)),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Privacy Settings coming soon")));
            },
          ),
          ListTile(
            leading: Icon(Icons.backup_outlined, color: Color(0xFF2A9D8F)),
            title: Text("Backup & Restore",
                style: TextStyle(color: Color(0xFF264653), fontWeight: FontWeight.w500)),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Backup feature coming soon")));
            },
          ),
        ],
      ),
    );
  }
}
