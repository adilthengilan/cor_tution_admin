import 'package:corona_lms_webapp/src/controller/student_controllers/fetch_Student_Details.dart';
import 'package:corona_lms_webapp/src/controller/student_controllers/student_service_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({Key? key}) : super(key: key);

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final studentService = StudentService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Inactive', 'Due Fees'];
  String _selectedClass = 'All Classes';
  String _selectedDivision = 'Division';

  // making random passwords
  String generatePassword({
    int length = 8,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
  }) {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_-+=<>?/|';

    String chars = '';
    if (includeUppercase) chars += uppercase;
    if (includeLowercase) chars += lowercase;
    if (includeNumbers) chars += numbers;
    if (includeSymbols) chars += symbols;

    if (chars.isEmpty) return '';

    final rand = Random.secure();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

//----------------
  final List<String> _classes = [
    'All Classes',
    '12th',
    '11th',
    '10th',
    '9th',
    '8th',
    '7th',
    '6th'
  ];
  final List<String> _Division = [
    'All Division',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G'
  ];

  List<dynamic> _students = [
    // {
    //   'id': 'ST-1001',
    //   'name': 'John Smith',
    //   'email': 'john.smith@example.com',
    //   'phone': '+1 234 567 890',
    //   'course': 'Mathematics',
    //   'class': '10th',
    //   'joinDate': '12 Jan 2023',
    //   'status': 'Active',
    //   'feeStatus': 'Paid',
    //   'avatar': 'https://i.pravatar.cc/150?img=1',
    // },
    // {
    //   'id': 'ST-1002',
    //   'name': 'Emily Johnson',
    //   'email': 'emily.johnson@example.com',
    //   'phone': '+1 234 567 891',
    //   'course': 'Physics',
    //   'class': '12th',
    //   'joinDate': '15 Feb 2023',
    //   'status': 'Active',
    //   'feeStatus': 'Due',
    //   'avatar': 'https://i.pravatar.cc/150?img=5',
    // },
    // {
    //   'id': 'ST-1003',
    //   'name': 'Michael Brown',
    //   'email': 'michael.brown@example.com',
    //   'phone': '+1 234 567 892',
    //   'course': 'Chemistry',
    //   'class': '11th',
    //   'joinDate': '20 Mar 2023',
    //   'status': 'Inactive',
    //   'feeStatus': 'Paid',
    //   'avatar': 'https://i.pravatar.cc/150?img=3',
    // },
    // {
    //   'id': 'ST-1004',
    //   'name': 'Sarah Davis',
    //   'email': 'sarah.davis@example.com',
    //   'phone': '+1 234 567 893',
    //   'course': 'Biology',
    //   'class': '10th',
    //   'joinDate': '05 Apr 2023',
    //   'status': 'Active',
    //   'feeStatus': 'Partial',
    //   'avatar': 'https://i.pravatar.cc/150?img=4',
    // },
    // {
    //   'id': 'ST-1005',
    //   'name': 'David Wilson',
    //   'email': 'david.wilson@example.com',
    //   'phone': '+1 234 567 894',
    //   'course': 'English',
    //   'class': '9th',
    //   'joinDate': '10 May 2023',
    //   'status': 'Active',
    //   'feeStatus': 'Paid',
    //   'avatar': 'https://i.pravatar.cc/150?img=6',
    // },
    // {
    //   'id': 'ST-1006',
    //   'name': 'Jessica Taylor',
    //   'email': 'jessica.taylor@example.com',
    //   'phone': '+1 234 567 895',
    //   'course': 'History',
    //   'class': '8th',
    //   'joinDate': '15 Jun 2023',
    //   'status': 'Inactive',
    //   'feeStatus': 'Due',
    //   'avatar': 'https://i.pravatar.cc/150?img=7',
    // },
  ];

  void getingData(BuildContext context) {
    final Students = Provider.of<StudentDetailsProvider>(context);
    _students = Students.studentDetails;
  }

  List<dynamic> get _filteredStudents {
    return _students.where((student) {
      final name = student['name'].toString().toLowerCase();
      final id = student['id'].toString().toLowerCase();
      final email = student['email'].toString().toLowerCase();
      final query = _searchController.text.toLowerCase();

      // Filter by search query
      final matchesSearch =
          name.contains(query) || id.contains(query) || email.contains(query);

      // Filter by status
      final matchesStatus = _selectedFilter == 'All' ||
          (_selectedFilter == 'Due Fees'
              ? student['feeStatus'] == 'Due'
              : student['status'] == _selectedFilter);

      // Filter by class
      final matchesClass =
          _selectedClass == 'All Classes' || student['class'] == _selectedClass;

      return matchesSearch && matchesStatus && matchesClass;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    getingData(context);

    final studentDetailss =
        Provider.of<StudentDetailsProvider>(context, listen: false);
    studentDetailss.fetchStudents('Student_list_@12', context);
    getingData(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Students',
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with search and add button
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search students...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddStudentDialog();
                    final index = Provider.of<StudentDetailsProvider>(context,
                        listen: false);
                    index.fetchNumber();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Student'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filter section
            Row(
              children: [
                // Status filter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter by Status:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          itemBuilder: (context, index) {
                            final filter = _filters[index];
                            final isSelected = _selectedFilter == filter;

                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: FilterChip(
                                selected: isSelected,
                                label: Text(filter),
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                },
                                backgroundColor: Colors.white,
                                selectedColor:
                                    const Color(0xFF3B82F6).withOpacity(0.1),
                                checkmarkColor: const Color(0xFF3B82F6),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF3B82F6)
                                      : Colors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFF3B82F6)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Class filter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter by Class:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedClass,
                            isExpanded: true,
                            items: _classes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedClass = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Students table
            Expanded(
              child: Container(
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
                child: Column(
                  children: [
                    // Table header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: const [
                          SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Name',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'ID',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Class',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          // Expanded(
                          //   child: Text(
                          //     'Course',
                          //     style: TextStyle(
                          //       fontWeight: FontWeight.bold,
                          //       color: Colors.grey,
                          //     ),
                          //   ),
                          // ),
                          Expanded(
                            child: Text(
                              'Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Fee Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(width: 80),
                        ],
                      ),
                    ),
                    const Divider(),

                    // Table body
                    Expanded(
                      child: _filteredStudents.isEmpty
                          ? const Center(
                              child: Text(
                                'No students found',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredStudents.length,
                              itemBuilder: (context, index) {
                                final student = _filteredStudents[index];
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundImage: NetworkImage(
                                                      " student['avatar']"),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      student['student_name'],
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      student['email'],
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(student['id']),
                                          ),
                                          Expanded(
                                            child: Text(student['class']),
                                          ),
                                          // Expanded(
                                          //   child: Text(student['Division']),
                                          // ),
                                          // Expanded(
                                          //   child: Text(student['course']),
                                          // ),
                                          Expanded(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: student['status'] ==
                                                        'Active'
                                                    ? Colors.green
                                                        .withOpacity(0.1)
                                                    : Colors.red
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                student['status'],
                                                style: TextStyle(
                                                  color: student['status'] ==
                                                          'Active'
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: student['fee_status'] ==
                                                        'Paid'
                                                    ? Colors.green
                                                        .withOpacity(0.1)
                                                    : student['fee_status'] ==
                                                            'Due'
                                                        ? Colors.red
                                                            .withOpacity(0.1)
                                                        : Colors.orange
                                                            .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                student['fee_status'],
                                                style: TextStyle(
                                                  color: student[
                                                              'fee_status'] ==
                                                          'Paid'
                                                      ? Colors.green
                                                      : student['fee_status'] ==
                                                              'Due'
                                                          ? Colors.red
                                                          : Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 80,
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      color: Color(0xFF3B82F6)),
                                                  onPressed: () {
                                                    _showEditStudentDialog(
                                                        student);
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red),
                                                  onPressed: () {
                                                    _showDeleteConfirmationDialog(
                                                        student);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (index < _filteredStudents.length - 1)
                                      const Divider(),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStudentDialog() {
    final studentService = StudentService();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    String selectedClass = '10th';
    String selectedDivision = 'A';

    String selectedCourse = 'Mathematics';
    String selectedStatus = 'Active';
    String selectedFeeStatus = 'Paid';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Student'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: selectedClass,
                  items: _classes
                      .where((c) => c != 'All Classes')
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedClass = value!;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Division',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: selectedDivision,
                  items: _Division.where((c) => c != 'Division')
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedDivision = value!;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Course',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  controller: TextEditingController(text: selectedCourse),
                  onChanged: (value) {
                    selectedCourse = value;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(
                        value: 'Inactive', child: Text('Inactive')),
                  ],
                  onChanged: (value) {
                    selectedStatus = value!;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Fee Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: selectedFeeStatus,
                  items: const [
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'Due', child: Text('Due')),
                    DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                  ],
                  onChanged: (value) {
                    selectedFeeStatus = value!;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final password = generatePassword();
              final index =
                  Provider.of<StudentDetailsProvider>(context, listen: false);
              index.fetchNumber();
              studentService.addStudent('Student_list_@12', {
                'division': selectedDivision,
                'id': 'cor@132${index.index}',
                'student_name': nameController.text,
                'class': selectedClass,
                'contact': phoneController.text,
                'email': emailController.text,
                'status': selectedStatus,
                'fee_status': selectedFeeStatus,
                'password': password
              });
              index.docids = 'cor@132${index.index}';
              index.createStudentDocList('cor@132${index.index}');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              index.updateindex();
              // Provider.of<StudentDetailsProvider>(context, listen: false)
              //     .fetchStudents('Student_list_@12', context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(student) {
    final TextEditingController nameController =
        TextEditingController(text: student['student_name']);
    final TextEditingController emailController =
        TextEditingController(text: student['email']);
    final TextEditingController phoneController =
        TextEditingController(text: student['contact']);
    String selectedClass = student['class'];
    // String selectedCourse = student['course'];
    String selectedStatus = student['status'];
    String selectedFeeStatus = student['fee_status'];
    String selectedDivision = student['division'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: selectedClass,
                  items: _classes
                      .where((c) => c != 'All Classes')
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedClass = value!;
                  },
                ),
                const SizedBox(height: 16),
                // TextField(
                //   decoration: InputDecoration(
                //     labelText: 'Course',
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //   ),
                //   controller: TextEditingController(text: selectedCourse),
                //   onChanged: (value) {
                //     selectedCourse = value;
                //   },
                // ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Division',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: selectedDivision,
                  items: _Division.where((c) => c != 'Division')
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedDivision = value!;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(
                        value: 'Inactive', child: Text('Inactive')),
                  ],
                  onChanged: (value) {
                    selectedStatus = value!;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Fee Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: selectedFeeStatus,
                  items: const [
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'Due', child: Text('Due')),
                    DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                  ],
                  onChanged: (value) {
                    selectedFeeStatus = value!;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newdata = {
                'class': selectedClass,
                'student_name': nameController.text,
                'status': selectedStatus,
                'fee_status': selectedFeeStatus,
                'contact': phoneController.text,
                'email': emailController.text,
                'division': selectedDivision,
                'id': student['id'],
                'password': student['password']
              };
              final obj = StudentService();
              obj.updateStudent('Student_list_@12', student['id'], newdata);

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Update Student'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final deleteValue = StudentService();
              deleteValue.deleteStudent('Student_list_@12', student['id']);
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
