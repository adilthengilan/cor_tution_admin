import 'package:flutter/material.dart';
import 'package:corona_lms_webapp/main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  String _language = 'English';
  
  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
    'Arabic',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyApp.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: MyApp.borderColor)),
        title: Text(
          'Settings',
          style: TextStyle(
            color: MyApp.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MyApp.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: MyApp.primaryColor.withOpacity(0.1),
                    child: Text(
                      'E',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: MyApp.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Esther Howard',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: MyApp.textPrimaryColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Primary Administrator',
                          style: TextStyle(
                            color: MyApp.textSecondaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'esther.howard@academy.edu',
                          style: TextStyle(
                            color: MyApp.textSecondaryColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyApp.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Appearance section
            _buildSectionHeader('Appearance & Locales'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MyApp.borderColor),
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'Force Light Theme',
                    subtitle: 'Keep the minimal light SaaS colors',
                    trailing: Switch(
                      value: !_darkMode,
                      onChanged: (value) {
                        setState(() {
                          _darkMode = !value;
                        });
                      },
                      activeColor: MyApp.primaryColor,
                    ),
                  ),
                  Divider(height: 1, color: MyApp.borderColor),
                  _buildSettingItem(
                    icon: Icons.language_outlined,
                    title: 'Portal Language',
                    subtitle: 'Select default localization',
                    trailing: DropdownButton<String>(
                      value: _language,
                      underline: const SizedBox(),
                      onChanged: (value) {
                        setState(() {
                          _language = value!;
                        });
                      },
                      items: _languages.map((language) {
                        return DropdownMenuItem<String>(
                          value: language,
                          child: Text(language, style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Notifications section
            _buildSectionHeader('Notification Prefs'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MyApp.borderColor),
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    icon: Icons.email_outlined,
                    title: 'Email Communications',
                    subtitle: 'Receive reports and course digests',
                    trailing: Switch(
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() {
                          _emailNotifications = value;
                        });
                      },
                      activeColor: MyApp.primaryColor,
                    ),
                  ),
                  Divider(height: 1, color: MyApp.borderColor),
                  _buildSettingItem(
                    icon: Icons.notifications_outlined,
                    title: 'Push Notifications',
                    subtitle: 'Receive instant web browser alerts',
                    trailing: Switch(
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() {
                          _pushNotifications = value;
                        });
                      },
                      activeColor: MyApp.primaryColor,
                    ),
                  ),
                  Divider(height: 1, color: MyApp.borderColor),
                  _buildSettingItem(
                    icon: Icons.sms_outlined,
                    title: 'SMS Alerts',
                    subtitle: 'Receive urgent mobile OTP and notices',
                    trailing: Switch(
                      value: _smsNotifications,
                      onChanged: (value) {
                        setState(() {
                          _smsNotifications = value;
                        });
                      },
                      activeColor: MyApp.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Security section
            _buildSectionHeader('Security & Access'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MyApp.borderColor),
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Configure your login security details',
                    trailing: Icon(Icons.chevron_right, color: MyApp.textSecondaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: MyApp.textPrimaryColor,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MyApp.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: MyApp.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: MyApp.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: MyApp.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}