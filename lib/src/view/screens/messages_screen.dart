import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  int _selectedContactIndex = 0;

  final List<Map<String, dynamic>> _contacts = [
    {
      'name': 'John Smith',
      'role': 'Student',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'status': 'online',
      'lastSeen': 'now',
      'unread': 2,
    },
    {
      'name': 'Emily Johnson',
      'role': 'Student',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'status': 'offline',
      'lastSeen': '2 hours ago',
      'unread': 0,
    },
    {
      'name': 'Michael Brown',
      'role': 'Student',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'status': 'online',
      'lastSeen': 'now',
      'unread': 0,
    },
    {
      'name': 'Sarah Davis',
      'role': 'Student',
      'avatar': 'https://i.pravatar.cc/150?img=4',
      'status': 'offline',
      'lastSeen': '1 day ago',
      'unread': 5,
    },
    {
      'name': 'David Wilson',
      'role': 'Teacher',
      'avatar': 'https://i.pravatar.cc/150?img=6',
      'status': 'online',
      'lastSeen': 'now',
      'unread': 0,
    },
    {
      'name': 'Jessica Taylor',
      'role': 'Parent',
      'avatar': 'https://i.pravatar.cc/150?img=7',
      'status': 'offline',
      'lastSeen': '3 hours ago',
      'unread': 1,
    },
  ];

  final List<List<Map<String, dynamic>>> _conversations = [
    [
      {
        'sender': 'John Smith',
        'message': 'Hello, I have a question about the math homework.',
        'time': '10:30 AM',
        'isMe': false,
      },
      {
        'sender': 'Me',
        'message': 'Sure, what do you need help with?',
        'time': '10:32 AM',
        'isMe': true,
      },
      {
        'sender': 'John Smith',
        'message':
            'I\'m stuck on problem 5, the one about quadratic equations.',
        'time': '10:35 AM',
        'isMe': false,
      },
      {
        'sender': 'Me',
        'message': 'Let me check that problem. Give me a moment.',
        'time': '10:36 AM',
        'isMe': true,
      },
      {
        'sender': 'John Smith',
        'message': 'Thank you! I appreciate your help.',
        'time': '10:37 AM',
        'isMe': false,
      },
    ],
    [
      {
        'sender': 'Emily Johnson',
        'message': 'Hi, I won\'t be able to attend class tomorrow.',
        'time': '2:15 PM',
        'isMe': false,
      },
      {
        'sender': 'Me',
        'message': 'Is everything okay?',
        'time': '2:20 PM',
        'isMe': true,
      },
      {
        'sender': 'Emily Johnson',
        'message':
            'Yes, I just have a doctor\'s appointment. I\'ll catch up on the material.',
        'time': '2:25 PM',
        'isMe': false,
      },
    ],
    [
      {
        'sender': 'Michael Brown',
        'message': 'When is the next test scheduled?',
        'time': '9:00 AM',
        'isMe': false,
      },
      {
        'sender': 'Me',
        'message': 'The test is scheduled for next Friday.',
        'time': '9:05 AM',
        'isMe': true,
      },
      {
        'sender': 'Michael Brown',
        'message': 'What topics will be covered?',
        'time': '9:10 AM',
        'isMe': false,
      },
      {
        'sender': 'Me',
        'message':
            'Chapters 5-7 from the textbook. I\'ll send a detailed email later today.',
        'time': '9:15 AM',
        'isMe': true,
      },
    ],
    [
      {
        'sender': 'Sarah Davis',
        'message': 'Hello, I need help with my project.',
        'time': '11:30 AM',
        'isMe': false,
      },
      {
        'sender': 'Me',
        'message': 'What kind of help do you need?',
        'time': '11:45 AM',
        'isMe': true,
      },
      {
        'sender': 'Sarah Davis',
        'message': 'I\'m having trouble with the research part.',
        'time': '12:00 PM',
        'isMe': false,
      },
      {
        'sender': 'Sarah Davis',
        'message': 'Can we schedule a meeting to discuss it?',
        'time': '12:01 PM',
        'isMe': false,
      },
      {
        'sender': 'Sarah Davis',
        'message': 'I\'m available tomorrow afternoon.',
        'time': '12:02 PM',
        'isMe': false,
      },
      {
        'sender': 'Sarah Davis',
        'message': 'Please let me know what time works for you.',
        'time': '12:03 PM',
        'isMe': false,
      },
      {
        'sender': 'Sarah Davis',
        'message': 'Thank you!',
        'time': '12:04 PM',
        'isMe': false,
      },
    ],
    [
      {
        'sender': 'David Wilson',
        'message': 'Hi, do you have the schedule for next semester?',
        'time': '3:00 PM',
        'isMe': false,
      },
      {
        'sender': 'Me',
        'message': 'Yes, I\'ll share it with you.',
        'time': '3:10 PM',
        'isMe': true,
      },
    ],
    [
      {
        'sender': 'Jessica Taylor',
        'message': 'Hello, I\'d like to discuss my son\'s progress.',
        'time': '4:30 PM',
        'isMe': false,
      },
      {
        'sender': 'Me',
        'message':
            'Of course, would you like to schedule a parent-teacher meeting?',
        'time': '4:45 PM',
        'isMe': true,
      },
      {
        'sender': 'Jessica Taylor',
        'message': 'Yes, that would be great. How about next Monday?',
        'time': '5:00 PM',
        'isMe': false,
      },
    ],
  ];

  List<Map<String, dynamic>> get _filteredContacts {
    final query = _searchController.text.toLowerCase();

    return _contacts.where((contact) {
      final name = contact['name'].toString().toLowerCase();
      final role = contact['role'].toString().toLowerCase();

      return name.contains(query) || role.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _conversations[_selectedContactIndex].add({
        'sender': 'Me',
        'message': _messageController.text,
        'time': DateFormat('h:mm a').format(DateTime.now()),
        'isMe': true,
      });
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=13'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Contacts list
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search contacts...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                // Contacts list
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      final isSelected = index == _selectedContactIndex;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedContactIndex = _contacts.indexOf(contact);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF3B82F6).withOpacity(0.1)
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF3B82F6)
                                    : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage:
                                        NetworkImage(contact['avatar']),
                                  ),
                                  if (contact['status'] == 'online')
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      contact['role'],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    contact['status'] == 'online'
                                        ? 'Online'
                                        : contact['lastSeen'],
                                    style: TextStyle(
                                      color: contact['status'] == 'online'
                                          ? Colors.green
                                          : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (contact['unread'] > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        contact['unread'].toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Chat area
          Expanded(
            child: Column(
              children: [
                // Chat header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                            _contacts[_selectedContactIndex]['avatar']),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _contacts[_selectedContactIndex]['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _contacts[_selectedContactIndex]['status'] ==
                                    'online'
                                ? 'Online'
                                : 'Last seen ${_contacts[_selectedContactIndex]['lastSeen']}',
                            style: TextStyle(
                              color: _contacts[_selectedContactIndex]
                                          ['status'] ==
                                      'online'
                                  ? Colors.green
                                  : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.phone),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.videocam),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                // Chat messages
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                    ),
                    child: ListView.builder(
                      reverse: true,
                      itemCount: _conversations[_selectedContactIndex].length,
                      itemBuilder: (context, index) {
                        final reversedIndex =
                            _conversations[_selectedContactIndex].length -
                                1 -
                                index;
                        final message = _conversations[_selectedContactIndex]
                            [reversedIndex];
                        final isMe = message['isMe'];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe) ...[
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: NetworkImage(
                                      _contacts[_selectedContactIndex]
                                          ['avatar']),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.5,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(0xFF3B82F6)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message['message'],
                                      style: TextStyle(
                                        color:
                                            isMe ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message['time'],
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 8),
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundImage: NetworkImage(
                                      'https://i.pravatar.cc/150?img=13'),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Message input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.emoji_emotions),
                        onPressed: () {},
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF3B82F6),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
