import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[400]!, Colors.blue[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (widget.userRole != 'student')
            IconButton(
              icon: Icon(Icons.add),
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
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No notifications yet',
                      style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;

              // Filter for students
              if (widget.userRole == 'student') {
                final recipients = List<String>.from(data['recipients'] ?? []);
                if (!recipients.contains('all_students') &&
                    !recipients.contains(widget.userId)) {
                  return SizedBox();
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
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: priority == 'urgent'
            ? Border.all(color: Colors.red, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
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
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTypeIcon(type),
                  color: _getPriorityColor(priority),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
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
                                  isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          _getTimeAgo(timestamp),
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(priority).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(priority),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'From: $sender',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        Spacer(),
                        // Read statistics for admin/teacher
                        if (widget.userRole != 'student') ...[
                          InkWell(
                            onTap: () => _showReadByDialog(readStats['readBy']),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility,
                                      size: 12, color: Colors.blue),
                                  SizedBox(width: 2),
                                  Text(
                                    '${readStats['readCount']}/${readStats['totalRecipients']}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue,
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
            title: Row(
              children: [
                Icon(Icons.visibility, color: Colors.blue),
                SizedBox(width: 8),
                Text('Read By (${readByIds.length})'),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              height: 300,
              child: snapshot.connectionState == ConnectionState.waiting
                  ? Center(child: CircularProgressIndicator())
                  : snapshot.hasData && snapshot.data!.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final user = snapshot.data![index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: user['role'] == 'teacher'
                                    ? Colors.orange
                                    : Colors.blue,
                                child: Icon(
                                  user['role'] == 'teacher'
                                      ? Icons.school
                                      : Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                user['name']!,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (user['email']!.isNotEmpty)
                                    Text(user['email']!),
                                  Text(
                                    user['role']!.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: user['role'] == 'teacher'
                                          ? Colors.orange
                                          : Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.check_circle,
                                color: Colors.green,
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
                                  size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'No one has read this notification yet',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
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
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Notification'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this notification?'),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteNotification(docId, sender);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
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
        title: Row(
          children: [
            Expanded(child: Text(title)),
            if (canDelete)
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
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
              Text(data['message'] ?? 'No message'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From: ${sender}'),
                    Text('Priority: ${data['priority'] ?? 'medium'}'),
                    Text('Type: ${data['type'] ?? 'announcement'}'),
                    Text('Recipients: ${recipients.join(", ")}'),
                    if (widget.userRole != 'student')
                      Text(
                          'Read by: ${readStats['readCount']}/${readStats['totalRecipients']} users'),
                    if (timestamp != null)
                      Text(
                          'Time: ${DateFormat('MMM d, yyyy - h:mm a').format(timestamp.toDate())}'),
                  ],
                ),
              ),
              if (widget.userRole != 'student' &&
                  readStats['readCount'] > 0) ...[
                SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showReadByDialog(readStats['readBy']);
                  },
                  icon: Icon(Icons.visibility),
                  label: Text('View Read By List'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
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
              icon: Icon(Icons.delete, color: Colors.red),
              label: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
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
          title: Text('Send Notification'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['announcement', 'assignment', 'exam', 'alert']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedType = value!),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: ['low', 'medium', 'high', 'urgent']
                      .map((priority) => DropdownMenuItem(
                            value: priority,
                            child: Text(priority.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedPriority = value!),
                ),
                SizedBox(height: 12),
                Text('Recipients:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  children: availableRecipients.map((recipient) {
                    return FilterChip(
                      label: Text(recipient.replaceAll('_', ' ')),
                      selected: selectedRecipients.contains(recipient),
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
              child: Text('Cancel'),
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
              child: Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
