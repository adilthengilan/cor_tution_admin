import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corona_lms_webapp/main.dart';

class NotificationsScreen extends StatefulWidget {
  final String userRole; // 'admin', 'teacher', 'student'
  final String userId;
  final String userName;
  final String classId;

  const NotificationsScreen({
    Key? key,
    required this.userRole,
    required this.userId,
    required this.userName,
    required this.classId,
  }) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add notification to Firebase
  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    required String priority,
    required List<String> recipients,
  }) async {
    try {
      await _firestore
          .collection('classes')
          .doc('notifications')
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'type': type,
        'priority': priority,
        'sender': widget.userName,
        'recipients': recipients,
        'time': FieldValue.serverTimestamp(),
        'isRead': false,
        'readBy': [], // Initialize empty readBy array
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification sent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send notification')),
        );
      }
    }
  }

  // Mark notification as read (updated to use readBy array)
  Future<void> markAsRead(String docId) async {
    try {
      final docRef = _firestore
          .collection('classes')
          .doc(widget.classId)
          .collection('notifications')
          .doc(docId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          List<String> readBy = List<String>.from(data['readBy'] ?? []);

          if (!readBy.contains(widget.userId)) {
            readBy.add(widget.userId);
            transaction.update(docRef, {
              'readBy': readBy,
              'isRead': readBy.isNotEmpty, // Keep for backward compatibility
            });
          }
        }
      });
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  // Check if notification is read by current user
  bool _isReadByCurrentUser(Map<String, dynamic> data) {
    List<String> readBy = List<String>.from(data['readBy'] ?? []);
    return readBy.contains(widget.userId);
  }

  // Get read statistics
  Map<String, dynamic> _getReadStats(Map<String, dynamic> data) {
    List<String> readBy = List<String>.from(data['readBy'] ?? []);
    List<String> recipients = List<String>.from(data['recipients'] ?? []);

    int totalRecipients = 0;
    if (recipients.contains('all_students')) {
      totalRecipients = 100; // You might want to get actual count from database
    } else if (recipients.contains('all_teachers')) {
      totalRecipients = 20; // You might want to get actual count from database
    } else {
      totalRecipients = recipients.length;
    }

    return {
      'readCount': readBy.length,
      'totalRecipients': totalRecipients,
      'readBy': readBy,
    };
  }

  // Fetch user names for read by list
  Future<List<Map<String, String>>> _fetchReadByUsers(
      List<String> userIds) async {
    List<Map<String, String>> users = [];

    for (String userId in userIds) {
      try {
        // You might need to adjust this query based on your user collection structure
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          users.add({
            'id': userId,
            'name': userData['name'] ?? 'Unknown User',
            'email': userData['email'] ?? '',
            'role': userData['role'] ?? 'student',
          });
        }
      } catch (e) {
        // print('Error fetching user $userId: $e');
        users.add({
          'id': userId,
          'name': 'User $userId',
          'email': '',
          'role': 'unknown',
        });
      }
    }

    return users;
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';

    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d').format(time);
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'assignment':
        return Icons.assignment;
      case 'exam':
        return Icons.school;
      case 'announcement':
        return Icons.campaign;
      case 'alert':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyApp.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: MyApp.borderColor)),
        title: Text(
          'Notifications',
          style: TextStyle(
              color: MyApp.textPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        actions: [
          if (widget.userRole != 'student')
            IconButton(
              icon: Icon(Icons.add, color: MyApp.primaryColor),
              onPressed: _showAddNotificationDialog,
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('classes')
            .doc(widget.classId)
            .collection('notifications')
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
 
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 56, color: MyApp.textSecondaryColor.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('No notifications yet',
                      style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }
 
          final notifications = snapshot.data!.docs;
 
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
 
              // Filter for students
              if (widget.userRole == 'student') {
                final recipients = List<String>.from(data['recipients'] ?? []);
                if (!recipients.contains('all_students') &&
                    !recipients.contains(widget.userId)) {
                  return const SizedBox();
                }
              }
 
              return _buildNotificationCard(doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(String docId, Map<String, dynamic> data) {
    final isRead = _isReadByCurrentUser(data);
    final priority = data['priority'] ?? 'medium';
    final type = data['type'] ?? 'announcement';
    final title = data['title'] ?? 'No Title';
    final message = data['message'] ?? 'No Message';
    final sender = data['sender'] ?? 'Unknown';
    final timestamp = data['time'] as Timestamp?;
    final readStats = _getReadStats(data);
 
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: priority == 'urgent' ? MyApp.errorColor : MyApp.borderColor,
          width: priority == 'urgent' ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!isRead) markAsRead(docId);
          _showNotificationDetails(docId, data);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTypeIcon(type),
                  color: _getPriorityColor(priority),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.bold : FontWeight.w900,
                              fontSize: 15,
                              color: MyApp.textPrimaryColor,
                            ),
                          ),
                        ),
                        Text(
                          _getTimeAgo(timestamp),
                          style:
                              TextStyle(fontSize: 12, color: MyApp.textSecondaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(color: MyApp.textSecondaryColor, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(priority).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(priority),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'From: $sender',
                          style:
                              TextStyle(fontSize: 12, color: MyApp.textSecondaryColor),
                        ),
                        const Spacer(),
                        // Read statistics for admin/teacher
                        if (widget.userRole != 'student') ...[
                          InkWell(
                            onTap: () => _showReadByDialog(readStats['readBy']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: MyApp.primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility,
                                      size: 12, color: MyApp.primaryColor),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${readStats['readCount']}/${readStats['totalRecipients']}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: MyApp.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: MyApp.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReadByDialog(List<String> readByIds) {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<Map<String, String>>>(
        future: _fetchReadByUsers(readByIds),
        builder: (context, snapshot) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.visibility, color: MyApp.primaryColor),
                const SizedBox(width: 8),
                Text('Read By (${readByIds.length})', style: TextStyle(color: MyApp.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : snapshot.hasData && snapshot.data!.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final user = snapshot.data![index];
                            final isTeacher = user['role'] == 'teacher';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isTeacher
                                    ? MyApp.warningColor.withOpacity(0.1)
                                    : MyApp.primaryColor.withOpacity(0.1),
                                child: Icon(
                                  isTeacher ? Icons.school : Icons.person,
                                  color: isTeacher ? MyApp.warningColor : MyApp.primaryColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                user['name']!,
                                style: TextStyle(fontWeight: FontWeight.bold, color: MyApp.textPrimaryColor, fontSize: 14),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (user['email']!.isNotEmpty)
                                    Text(user['email']!, style: TextStyle(color: MyApp.textSecondaryColor, fontSize: 12)),
                                  Text(
                                    user['role']!.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isTeacher ? MyApp.warningColor : MyApp.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.check_circle,
                                color: MyApp.successColor,
                                size: 20,
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.visibility_off,
                                  size: 48, color: MyApp.textSecondaryColor.withOpacity(0.5)),
                              const SizedBox(height: 8),
                              Text(
                                'No one has read this notification yet',
                                style: TextStyle(color: MyApp.textSecondaryColor),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: TextStyle(color: MyApp.textSecondaryColor)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(String docId, String title, String sender) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: MyApp.errorColor),
            const SizedBox(width: 8),
            Text('Delete Notification', style: TextStyle(color: MyApp.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this notification?', style: TextStyle(color: MyApp.textSecondaryColor)),
            const SizedBox(height: 8),
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MyApp.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MyApp.borderColor),
              ),
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: MyApp.textPrimaryColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(color: MyApp.errorColor, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: MyApp.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteNotification(docId, sender);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyApp.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

// Delete notification (only for admin and sender)
  Future<void> deleteNotification(String docId, String sender) async {
    // Check if user has permission to delete
    if (widget.userRole != 'admin' && widget.userName != sender) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('You don\'t have permission to delete this notification')),
      );
      return;
    }

    try {
      await _firestore
          .collection('classes')
          .doc(widget.classId)
          .collection('notifications')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete notification')),
        );
      }
    }
  }

  void _showNotificationDetails(String docId, Map<String, dynamic> data) {
    final timestamp = data['time'] as Timestamp?;
    final recipients = List<String>.from(data['recipients'] ?? []);
    final readStats = _getReadStats(data);
    final sender = data['sender'] ?? 'Unknown';
    final title = data['title'] ?? 'Notification';
 
    // Check if user can delete this notification
    final canDelete = widget.userRole == 'admin' || widget.userName == sender;
 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Expanded(child: Text(title, style: TextStyle(color: MyApp.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16))),
            if (canDelete)
              IconButton(
                icon: Icon(Icons.delete, color: MyApp.errorColor),
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(docId, title, sender);
                },
                tooltip: 'Delete Notification',
              ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['message'] ?? 'No message', style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 14)),
              const SizedBox(height: 16),
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MyApp.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MyApp.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From: $sender', style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Priority: ${data['priority'] ?? 'medium'}', style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Type: ${data['type'] ?? 'announcement'}', style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Recipients: ${recipients.join(", ")}', style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 12)),
                    if (widget.userRole != 'student') ...[
                      const SizedBox(height: 4),
                      Text(
                          'Read by: ${readStats['readCount']}/${readStats['totalRecipients']} users', style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 12)),
                    ],
                    if (timestamp != null) ...[
                      const SizedBox(height: 4),
                      Text(
                          'Time: ${DateFormat('MMM d, yyyy - h:mm a').format(timestamp.toDate())}', style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              if (widget.userRole != 'student' &&
                  readStats['readCount'] > 0) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showReadByDialog(readStats['readBy']);
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Read By List'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyApp.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (canDelete)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmation(docId, title, sender);
              },
              icon: Icon(Icons.delete, color: MyApp.errorColor),
              label: Text('Delete', style: TextStyle(color: MyApp.errorColor)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: MyApp.textSecondaryColor)),
          ),
        ],
      ),
    );
  }
 
  void _showAddNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = 'announcement';
    String selectedPriority = 'medium';
    List<String> selectedRecipients = [];
 
    final availableRecipients = [
      'all_students',
      'all_teachers',
      'grade_10_students',
      'grade_11_students',
      'grade_12_students',
    ];
 
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Send Notification', style: TextStyle(color: MyApp.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: MyApp.borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: MyApp.borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: MyApp.primaryColor)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Message',
                    labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: MyApp.borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: MyApp.borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: MyApp.primaryColor)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Type',
                    labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: MyApp.borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: MyApp.borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: MyApp.primaryColor)),
                  ),
                  items: ['announcement', 'assignment', 'exam', 'alert']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.toUpperCase(), style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedType = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: MyApp.borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: MyApp.borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: MyApp.primaryColor)),
                  ),
                  items: ['low', 'medium', 'high', 'urgent']
                      .map((priority) => DropdownMenuItem(
                            value: priority,
                            child: Text(priority.toUpperCase(), style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedPriority = value!),
                ),
                const SizedBox(height: 12),
                Text('Recipients:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: MyApp.textPrimaryColor, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: availableRecipients.map((recipient) {
                    final isSelected = selectedRecipients.contains(recipient);
                    return FilterChip(
                      label: Text(recipient.replaceAll('_', ' '), style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : MyApp.textPrimaryColor)),
                      selected: isSelected,
                      selectedColor: MyApp.primaryColor,
                      checkmarkColor: Colors.white,
                      backgroundColor: MyApp.backgroundColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? MyApp.primaryColor : MyApp.borderColor)),
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedRecipients.add(recipient);
                          } else {
                            selectedRecipients.remove(recipient);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: MyApp.textSecondaryColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    messageController.text.isNotEmpty &&
                    selectedRecipients.isNotEmpty) {
                  Navigator.pop(context);
 
                  await addNotification(
                    title: titleController.text,
                    message: messageController.text,
                    type: selectedType,
                    priority: selectedPriority,
                    recipients: selectedRecipients,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyApp.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
