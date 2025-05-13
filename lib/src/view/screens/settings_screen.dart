// import 'package:flutter/material.dart';

// class SettingsScreen extends StatefulWidget {
//   const SettingsScreen({Key? key}) : super(key: key);

//   @override
//   State<SettingsScreen> createState() => _SettingsScreenState();
// }

// class _SettingsScreenState extends State<SettingsScreen> {
//   bool _darkMode = false;
//   bool _emailNotifications = true;
//   bool _pushNotifications = true;
//   bool _smsNotifications = false;
//   String _language = 'English';
  
//   final List<String> _languages = [
//     'English',
//     'Spanish',
//     'French',
//     'German',
//     'Chinese',
//     'Japanese',
//     'Arabic',
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text(
//           'Settings',
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications_outlined, color: Colors.black),
//             onPressed: () {},
//           ),
//           const SizedBox(width: 8),
//           const CircleAvatar(
//             backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=13'),
//           ),
//           const SizedBox(width: 16),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Profile section
//             Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   const CircleAvatar(
//                     radius: 40,
//                     backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=13'),
//                   ),
//                   const SizedBox(width: 24),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Esther Howard',
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Administrator',
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 16,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'esther.howard@example.com',
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   ElevatedButton(
//                     onPressed: () {},
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF3B82F6),
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text('Edit Profile'),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),
            
//             // Appearance section
//             _buildSectionHeader('Appearance'),
//             const SizedBox(height: 16),
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   _buildSettingItem(
//                     icon: Icons.dark_mode,
//                     title: 'Dark Mode',
//                     subtitle: 'Use dark theme for the application',
//                     trailing: Switch(
//                       value: _darkMode,
//                       onChanged: (value) {
//                         setState(() {
//                           _darkMode = value;
//                         });
//                       },
//                       activeColor: const Color(0xFF3B82F6),
//                     ),
//                   ),
//                   _buildDivider(),
//                   _buildSettingItem(
//                     icon: Icons.language,
//                     title: 'Language',
//                     subtitle: 'Select your preferred language',
//                     trailing: DropdownButton<String>(
//                       value: _language,
//                       underline: const SizedBox(),
//                       onChanged: (value) {
//                         setState(() {
//                           _language = value!;
//                         });
//                       },
//                       items: _languages.map((language) {
//                         return DropdownMenuItem<String>(
//                           value: language,
//                           child: Text(language),
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),
            
//             // Notifications section
//             _buildSectionHeader('Notifications'),
//             const SizedBox(height: 16),
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   _buildSettingItem(
//                     icon: Icons.email,
//                     title: 'Email Notifications',
//                     subtitle: 'Receive notifications via email',
//                     trailing: Switch(
//                       value: _emailNotifications,
//                       onChanged: (value) {
//                         setState(() {
//                           _emailNotifications = value;
//                         });
//                       },
//                       activeColor: const Color(0xFF3B82F6),
//                     ),
//                   ),
//                   _buildDivider(),
//                   _buildSettingItem(
//                     icon: Icons.notifications,
//                     title: 'Push Notifications',
//                     subtitle: 'Receive push notifications',
//                     trailing: Switch(
//                       value: _pushNotifications,
//                       onChanged: (value) {
//                         setState(() {
//                           _pushNotifications = value;
//                         });
//                       },
//                       activeColor: const Color(0xFF3B82F6),
//                     ),
//                   ),
//                   _buildDivider(),
//                   _buildSettingItem(
//                     icon: Icons.sms,
//                     title: 'SMS Notifications',
//                     subtitle: 'Receive notifications via SMS',
//                     trailing: Switch(
//                       value: _smsNotifications,
//                       onChanged: (value) {
//                         setState(() {
//                           _smsNotifications = value;
//                         });
//                       },
//                       activeColor: const Color(0xFF3B82F6),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),
            
//             // Security section
//             _buildSectionHeader('Security'),
//             const SizedBox(height: 16),
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 10,
//                     offset: const Offset(0