import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'New Assignment',
      'description': 'Mathematics assignment has been posted.',
      'time': DateTime.now().subtract(const Duration(minutes: 30)),
      'type': 'assignment',
      'isRead': false,
    },
    {
      'title': 'Fee Due',
      'description': 'Your monthly fee payment is due in 3 days.',
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'type': 'fee',
      'isRead': false,
    },
    {
      'title': 'Exam Schedule',
      'description': 'Mid-term exams will start from next Monday.',
      'time': DateTime.now().subtract(const Duration(hours: 5)),
      'type': 'exam',
      'isRead': true,
    },
    {
      'title': 'Holiday Notice',
      'description': 'The center will be closed on 25th for National Holiday.',
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'type': 'announcement',
      'isRead': true,
    },
    {
      'title': 'New Message',
      'description': 'You have a new message from John Smith.',
      'time': DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      'type': 'message',
      'isRead': true,
    },
    {
      'title': 'Result Published',
      'description': 'Physics test results have been published.',
      'time': DateTime.now().subtract(const Duration(days: 2)),
      'type': 'result',
      'isRead': true,
    },
    {
      'title': 'Parent-Teacher Meeting',
      'description': 'Parent-teacher meeting scheduled for next Friday.',
      'time': DateTime.now().subtract(const Duration(days: 3)),
      'type': 'meeting',
      'isRead': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(time);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'assignment':
        return Icons.assignment;
      case 'fee':
        return Icons.payment;
      case 'exam':
        return Icons.school;
      case 'announcement':
        return Icons.announcement;
      case 'message':
        return Icons.message;
      case 'result':
        return Icons.assessment;
      case 'meeting':
        return Icons.people;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'assignment':
        return Colors.blue;
      case 'fee':
        return Colors.red;
      case 'exam':
        return Colors.purple;
      case 'announcement':
        return Colors.orange;
      case 'message':
        return Colors.green;
      case 'result':
        return Colors.teal;
      case 'meeting':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> get _allNotifications => _notifications;

  List<Map<String, dynamic>> get _unreadNotifications => _notifications
      .where((notification) => notification['isRead'] == false)
      .toList();

  List<Map<String, dynamic>> get _readNotifications => _notifications
      .where((notification) => notification['isRead'] == true)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.black),
            onPressed: () {
              setState(() {
                for (var notification in _notifications) {
                  notification['isRead'] = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=13'),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3B82F6),
          tabs: [
            Tab(text: 'All (${_allNotifications.length})'),
            Tab(text: 'Unread (${_unreadNotifications.length})'),
            Tab(text: 'Read (${_readNotifications.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList(_allNotifications),
          _buildNotificationsList(_unreadNotifications),
          _buildNotificationsList(_readNotifications),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<Map<String, dynamic>> notifications) {
    return notifications.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification['type'])
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(notification['type']),
                      color: _getNotificationColor(notification['type']),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'],
                          style: TextStyle(
                            fontWeight: notification['isRead']
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        _getTimeAgo(notification['time']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(notification['description']),
                  ),
                  trailing: notification['isRead']
                      ? null
                      : Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                  onTap: () {
                    setState(() {
                      notification['isRead'] = true;
                    });
                    // Show notification details
                    _showNotificationDetails(notification);
                  },
                ),
              );
            },
          );
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['description']),
            const SizedBox(height: 16),
            Text(
              'Received: ${DateFormat('MMM d, yyyy - h:mm a').format(notification['time'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
