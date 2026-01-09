import 'package:flutter/material.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({Key? key}) : super(key: key);

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  String _language = 'English';
  String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final kDarkBlue = Color(0xFF1B3C53);
    final kBlueGray = Color(0xFF456882);

    return Scaffold(
      backgroundColor: const Color(0xFFF3EFEC),
      appBar: AppBar(
        backgroundColor: kDarkBlue,
        elevation: 0,
        title: const Text("Settings",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          _buildSectionHeader("Appearance", kBlueGray),
          SwitchListTile(
            title: Text('Dark Mode',
                style: TextStyle(fontWeight: FontWeight.w600, color: kBlueGray)),
            value: _darkMode,
            onChanged: (val) {
              setState(() {
                _darkMode = val;
              });
              // Hook in global theme switch here if needed
            },
            secondary: Icon(Icons.brightness_6, color: kBlueGray),
          ),
          Divider(height: 32),

          _buildSectionHeader("Notifications", kBlueGray),
          SwitchListTile(
            title: Text('Enable Notifications',
                style: TextStyle(fontWeight: FontWeight.w600, color: kBlueGray)),
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
            secondary: Icon(Icons.notifications_active, color: kBlueGray),
          ),
          Divider(height: 32),

          _buildSectionHeader("Preferences", kBlueGray),
          ListTile(
            leading: Icon(Icons.language, color: kBlueGray),
            title: Text("Language",
                style: TextStyle(fontWeight: FontWeight.w600, color: kBlueGray)),
            subtitle: Text(_language),
            trailing: Icon(Icons.keyboard_arrow_right, color: kBlueGray),
            onTap: () => _showLanguageDialog(),
          ),

          Divider(height: 32),

          _buildSectionHeader("About", kBlueGray),
          ListTile(
            leading: Icon(Icons.info_outline, color: kBlueGray),
            title: Text("App Version",
                style: TextStyle(fontWeight: FontWeight.w600, color: kBlueGray)),
            subtitle: Text(_appVersion),
          ),

          SizedBox(height: 40),

          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // Logout handler
                Navigator.of(context).popUntil((route) => route.isFirst);
                // Add actual logout functionality here
              },
              icon: Icon(Icons.logout),
              label: Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      child: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: color)),
    );
  }

  void _showLanguageDialog() {
    showDialog(
        context: context,
        builder: (_) {
          return SimpleDialog(
            title: Text("Select Language"),
            children: [
              SimpleDialogOption(
                child: Text("English"),
                onPressed: () {
                  setState(() {
                    _language = "English";
                  });
                  Navigator.pop(context);
                },
              ),
              SimpleDialogOption(
                child: Text("Hindi"),
                onPressed: () {
                  setState(() {
                    _language = "Hindi";
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }
}
