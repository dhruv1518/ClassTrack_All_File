import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _locationAccess = false;
  String _selectedLanguage = "English";

  void _showLanguagePicker() {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: tp.cardBg,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Choose Language",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tp.primaryText,
                ),
              ),
              Divider(color: tp.dividerColor),
              ListTile(
                title: Text("English", style: TextStyle(color: tp.primaryText)),
                onTap: () {
                  setState(() => _selectedLanguage = "English");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text("हिन्दी", style: TextStyle(color: tp.primaryText)),
                onTap: () {
                  setState(() => _selectedLanguage = "हिन्दी");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text("Español", style: TextStyle(color: tp.primaryText)),
                onTap: () {
                  setState(() => _selectedLanguage = "Español");
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
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    return SwitchListTile(
      activeColor: tp.accentTeal,
      secondary: Icon(icon, color: tp.accentTeal),
      title: Text(
        title,
        style: TextStyle(color: tp.primaryText, fontWeight: FontWeight.w500),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: tp.scaffoldBg,
      appBar: AppBar(
        backgroundColor: tp.appBarBg,
        title: Text("Settings", style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        children: [
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: "Dark Mode",
            value: tp.isDarkMode,
            onChanged: (_) => tp.toggleDarkMode(),
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
            leading: Icon(Icons.language, color: tp.accentTeal),
            title: Text(
              "Language",
              style: TextStyle(
                color: tp.primaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _selectedLanguage,
              style: TextStyle(color: tp.secondaryText),
            ),
            trailing: Icon(Icons.chevron_right, color: tp.inactiveColor),
            onTap: _showLanguagePicker,
          ),
          Divider(color: tp.dividerColor),
          ListTile(
            leading: Icon(Icons.security, color: tp.accentTeal),
            title: Text(
              "Privacy & Security",
              style: TextStyle(
                color: tp.primaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: tp.inactiveColor),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Privacy Settings coming soon")),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.backup_outlined, color: tp.accentTeal),
            title: Text(
              "Backup & Restore",
              style: TextStyle(
                color: tp.primaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: tp.inactiveColor),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Backup feature coming soon")),
              );
            },
          ),
        ],
      ),
    );
  }
}
