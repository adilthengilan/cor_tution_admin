import 'package:flutter/material.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({Key? key}) : super(key: key);

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedClass = 'All Classes';
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
  String _selectedSubject = 'All Subjects';
  final List<String> _subjects = [
    'All Subjects',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'History',
    'Geography'
  ];

  final List<Map<String, dynamic>> _exams = [
    // {
    //   'id': 'EX-1001',
    //   'title': 'Algebra Mid-Term',
    //   'description':
    //       'Mid-term examination covering linear equations, polynomials, and factorization.',
    //   'class': '10th',
    //   'subject': 'Mathematics',
    //   'duration': 60,
    //   'totalQuestions': 30,
    //   'passingMarks': 40,
    //   'totalMarks': 100,
    //   'status': 'Active',
    //   'createdDate': '12 May 2023',
    //   'dueDate': '20 May 2023',
    // },
    // {
    //   'id': 'EX-1002',
    //   'title': 'Newton\'s Laws Quiz',
    //   'description':
    //       'Quick assessment on Newton\'s three laws of motion with numerical problems.',
    //   'class': '12th',
    //   'subject': 'Physics',
    //   'duration': 30,
    //   'totalQuestions': 15,
    //   'passingMarks': 20,
    //   'totalMarks': 50,
    //   'status': 'Active',
    //   'createdDate': '15 May 2023',
    //   'dueDate': '22 May 2023',
    // },
    // {
    //   'id': 'EX-1003',
    //   'title': 'Periodic Table Test',
    //   'description':
    //       'Comprehensive test on the periodic table, elements, and their properties.',
    //   'class': '11th',
    //   'subject': 'Chemistry',
    //   'duration': 45,
    //   'totalQuestions': 25,
    //   'passingMarks': 30,
    //   'totalMarks': 75,
    //   'status': 'Upcoming',
    //   'createdDate': '20 May 2023',
    //   'dueDate': '27 May 2023',
    // },
    // {
    //   'id': 'EX-1004',
    //   'title': 'Cell Biology Final',
    //   'description':
    //       'Final examination covering cell structure, organelles, and cellular processes.',
    //   'class': '10th',
    //   'subject': 'Biology',
    //   'duration': 90,
    //   'totalQuestions': 40,
    //   'passingMarks': 50,
    //   'totalMarks': 120,
    //   'status': 'Completed',
    //   'createdDate': '25 May 2023',
    //   'dueDate': '01 Jun 2023',
    // },
    // {
    //   'id': 'EX-1005',
    //   'title': 'Shakespeare Literature Quiz',
    //   'description':
    //       'Quiz on Shakespeare\'s major works, characters, and literary devices.',
    //   'class': '9th',
    //   'subject': 'English',
    //   'duration': 40,
    //   'totalQuestions': 20,
    //   'passingMarks': 24,
    //   'totalMarks': 60,
    //   'status': 'Active',
    //   'createdDate': '30 May 2023',
    //   'dueDate': '05 Jun 2023',
    // },
    // {
    //   'id': 'EX-1006',
    //   'title': 'World War II Assessment',
    //   'description':
    //       'Comprehensive assessment on World War II events, key figures, and impacts.',
    //   'class': '8th',
    //   'subject': 'History',
    //   'duration': 60,
    //   'totalQuestions': 30,
    //   'passingMarks': 36,
    //   'totalMarks': 90,
    //   'status': 'Upcoming',
    //   'createdDate': '05 Jun 2023',
    //   'dueDate': '12 Jun 2023',
    // },
  ];

  List<Map<String, dynamic>> get _filteredExams {
    return _exams.where((exam) {
      final title = exam['title'].toString().toLowerCase();
      final description = exam['description'].toString().toLowerCase();
      final query = _searchController.text.toLowerCase();

      // Filter by search query
      final matchesSearch =
          title.contains(query) || description.contains(query);

      // Filter by class
      final matchesClass =
          _selectedClass == 'All Classes' || exam['class'] == _selectedClass;

      // Filter by subject
      final matchesSubject = _selectedSubject == 'All Subjects' ||
          exam['subject'] == _selectedSubject;

      return matchesSearch && matchesClass && matchesSubject;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Exams',
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3B82F6),
          tabs: const [
            Tab(text: 'All Exams'),
            Tab(text: 'Active'),
            Tab(text: 'Upcoming'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExamsTab('All'),
          _buildExamsTab('Active'),
          _buildExamsTab('Upcoming'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddExamDialog();
        },
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildExamsTab(String status) {
    final exams = status == 'All'
        ? _filteredExams
        : _filteredExams.where((exam) => exam['status'] == status).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and filter
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
                      hintText: 'Search exams...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                    hint: const Text('Class'),
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
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSubject,
                    hint: const Text('Subject'),
                    items: _subjects.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedSubject = newValue!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Exams list
          Expanded(
            child: exams.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No exams found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: exams.length,
                    itemBuilder: (context, index) {
                      final exam = exams[index];
                      return _buildExamCard(exam);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    Color statusColor;

    switch (exam['status']) {
      case 'Active':
        statusColor = Colors.green;
        break;
      case 'Upcoming':
        statusColor = Colors.orange;
        break;
      case 'Completed':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exam['description'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    exam['status'],
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildExamDetail(Icons.class_, 'Class', exam['class']),
                    _buildExamDetail(Icons.subject, 'Subject', exam['subject']),
                    _buildExamDetail(
                        Icons.timer, 'Duration', '${exam['duration']} mins'),
                    _buildExamDetail(Icons.help_outline, 'Questions',
                        exam['totalQuestions'].toString()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildExamDetail(Icons.check_circle_outline,
                        'Passing Marks', exam['passingMarks'].toString()),
                    _buildExamDetail(Icons.grade, 'Total Marks',
                        exam['totalMarks'].toString()),
                    _buildExamDetail(
                        Icons.calendar_today, 'Due Date', exam['dueDate']),
                    _buildExamDetail(
                        Icons.date_range, 'Created', exam['createdDate']),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _showViewQuestionsDialog(exam);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Questions'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    _showEditExamDialog(exam);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    _showDeleteConfirmationDialog(exam);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamDetail(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddExamDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController durationController =
        TextEditingController(text: '60');
    final TextEditingController totalQuestionsController =
        TextEditingController(text: '30');
    final TextEditingController passingMarksController =
        TextEditingController(text: '40');
    final TextEditingController totalMarksController =
        TextEditingController(text: '100');
    String selectedClass = '10th';
    String selectedSubject = 'Mathematics';
    String selectedStatus = 'Upcoming';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Exam'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        value: selectedSubject,
                        items: _subjects
                            .where((s) => s != 'All Subjects')
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedSubject = value!;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        decoration: InputDecoration(
                          labelText: 'Duration (minutes)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: totalQuestionsController,
                        decoration: InputDecoration(
                          labelText: 'Total Questions',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: passingMarksController,
                        decoration: InputDecoration(
                          labelText: 'Passing Marks',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: totalMarksController,
                        decoration: InputDecoration(
                          labelText: 'Total Marks',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
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
                        value: 'Upcoming', child: Text('Upcoming')),
                  ],
                  onChanged: (value) {
                    selectedStatus = value!;
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
              Navigator.pop(context);
              _showAddQuestionsDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continue to Add Questions'),
          ),
        ],
      ),
    );
  }

  void _showAddQuestionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Questions'),
        content: SizedBox(
          width: 800,
          height: 600,
          child: Column(
            children: [
              // Question form
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildQuestionForm(0),
                      const Divider(height: 32),
                      // _buildQuestionForm(2),
                      // const Divider(height: 32),
                      // _buildQuestionForm(3),
                    ],
                  ),
                ),
              ),

              // Add more button
              // Padding(
              //   padding: const EdgeInsets.symmetric(vertical: 16),
              //   child: ElevatedButton.icon(
              //     onPressed: () {
              //       // Add more question form
              //     },
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.grey[200],
              //       foregroundColor: Colors.black,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //     ),
              //     icon: const Icon(Icons.add),
              //     label: const Text('Add More Questions'),
              //   ),
              // ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save exam with questions
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exam created successfully'),
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
            child: const Text('Save Exam'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionForm(int questionNumber) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Question',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Delete question
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            labelText: 'Question Text',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Question Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: 'Multiple Choice',
                items: const [
                  DropdownMenuItem(
                      value: 'Multiple Choice', child: Text('Multiple Choice')),
                  DropdownMenuItem(
                      value: 'True/False', child: Text('True/False')),
                ],
                onChanged: (value) {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Marks',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: '1'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Options:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildOptionField('A', true),
        const SizedBox(height: 8),
        _buildOptionField('B', false),
        const SizedBox(height: 8),
        _buildOptionField('C', false),
        const SizedBox(height: 8),
        _buildOptionField('D', false),
      ],
    );
  }

  Widget _buildOptionField(String option, bool isCorrect) {
    return Row(
      children: [
        Radio(
          value: isCorrect,
          groupValue: true,
          onChanged: (value) {},
          activeColor: const Color(0xFF3B82F6),
        ),
        const SizedBox(width: 8),
        Text(
          'Option $option:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Enter option $option',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditExamDialog(Map<String, dynamic> exam) {
    final TextEditingController titleController =
        TextEditingController(text: exam['title']);
    final TextEditingController descriptionController =
        TextEditingController(text: exam['description']);
    final TextEditingController durationController =
        TextEditingController(text: exam['duration'].toString());
    final TextEditingController totalQuestionsController =
        TextEditingController(text: exam['totalQuestions'].toString());
    final TextEditingController passingMarksController =
        TextEditingController(text: exam['passingMarks'].toString());
    final TextEditingController totalMarksController =
        TextEditingController(text: exam['totalMarks'].toString());
    String selectedClass = exam['class'];
    String selectedSubject = exam['subject'];
    String selectedStatus = exam['status'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Exam'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        value: selectedSubject,
                        items: _subjects
                            .where((s) => s != 'All Subjects')
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedSubject = value!;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        decoration: InputDecoration(
                          labelText: 'Duration (minutes)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: totalQuestionsController,
                        decoration: InputDecoration(
                          labelText: 'Total Questions',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: passingMarksController,
                        decoration: InputDecoration(
                          labelText: 'Passing Marks',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: totalMarksController,
                        decoration: InputDecoration(
                          labelText: 'Total Marks',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
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
                        value: 'Upcoming', child: Text('Upcoming')),
                    DropdownMenuItem(
                        value: 'Completed', child: Text('Completed')),
                  ],
                  onChanged: (value) {
                    selectedStatus = value!;
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
              // Update exam details
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exam updated successfully'),
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
            child: const Text('Update Exam'),
          ),
        ],
      ),
    );
  }

  void _showViewQuestionsDialog(Map<String, dynamic> exam) {
    // Sample questions for the exam
    final List<Map<String, dynamic>> questions = [
      // {
      //   'id': 'Q-1001',
      //   'text': 'What is the formula for the area of a circle?',
      //   'type': 'Multiple Choice',
      //   'options': [
      //     {'id': 'A', 'text': 'πr²', 'isCorrect': true},
      //     {'id': 'B', 'text': '2πr', 'isCorrect': false},
      //     {'id': 'C', 'text': 'πd', 'isCorrect': false},
      //     {'id': 'D', 'text': '2πr²', 'isCorrect': false},
      //   ],
      //   'marks': 2,
      // },
      // {
      //   'id': 'Q-1002',
      //   'text': 'Which of the following is a quadratic equation?',
      //   'type': 'Multiple Choice',
      //   'options': [
      //     {'id': 'A', 'text': 'y = mx + c', 'isCorrect': false},
      //     {'id': 'B', 'text': 'y = ax² + bx + c', 'isCorrect': true},
      //     {'id': 'C', 'text': 'y = ax³ + bx² + cx + d', 'isCorrect': false},
      //     {'id': 'D', 'text': 'y = a/x', 'isCorrect': false},
      //   ],
      //   'marks': 2,
      // },
      // {
      //   'id': 'Q-1003',
      //   'text': 'The Pythagorean theorem applies to right-angled triangles.',
      //   'type': 'True/False',
      //   'options': [
      //     {'id': 'A', 'text': 'True', 'isCorrect': true},
      //     {'id': 'B', 'text': 'False', 'isCorrect': false},
      //   ],
      //   'marks': 1,
      // },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Questions: ${exam['title']}'),
        content: SizedBox(
          width: 800,
          height: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exam details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildExamDetail(Icons.class_, 'Class', exam['class']),
                    _buildExamDetail(Icons.subject, 'Subject', exam['subject']),
                    _buildExamDetail(Icons.help_outline, 'Questions',
                        exam['totalQuestions'].toString()),
                    _buildExamDetail(Icons.grade, 'Total Marks',
                        exam['totalMarks'].toString()),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Questions list
              Expanded(
                child: ListView.separated(
                  itemCount: questions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 32),
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return _buildQuestionView(index + 1, question);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddQuestionsDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Edit Questions'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView(int questionNumber, Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Question $questionNumber (${question['marks']} marks)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                question['type'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(question['text']),
        const SizedBox(height: 16),
        ...question['options'].map<Widget>((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: option['isCorrect']
                        ? const Color(0xFF3B82F6)
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      option['id'],
                      style: TextStyle(
                        color:
                            option['isCorrect'] ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(option['text']),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Are you sure you want to delete "${exam['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete exam logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exam deleted successfully'),
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
