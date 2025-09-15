import 'package:corona_lms_webapp/src/controller/student_controllers/student_service_controller.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({Key? key}) : super(key: key);

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedClass = 'All Classes';
  String _selectedSubject = 'All Subjects';
  String _selectedDivision = 'All Divisions';

  List<Map<String, dynamic>> _allExams = [];
  bool _isLoading = true;

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

  final List<String> _subjects = [
    'All Subjects',
    'Mathematics',
    'English',
    'Arabic',
    'Malayalam',
    'Urdu',
    'Hindi',
    'Chemistry',
    'Physics',
    'Biology',
    'Social Science',
    'History',
    'Geography'
  ];
  final List<String> _divisions = [
    'All Divisions',
    'M1',
    'M2',
    'M3',
    'M4',
    'M5',
    'M6',
    'M7',
    'E1',
    'E2',
    'E3',
    'E4',
    'E5',
    'S1',
    'S2',
    'S3'
  ];
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadExams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Load exams from Firestore
  Future<void> _loadExams() async {
    try {
      final docSnapshot =
          await _firestore.collection('exams').doc('exam-list').get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();

        setState(() {
          _allExams = (data?['exams'] as List<dynamic>? ?? []).map((exam) {
            return {
              ...exam as Map<String, dynamic>,
              'createdAt': (exam['createdAt'] as Timestamp?)?.toDate(),
            };
          }).toList();

          _isLoading = false;
        });
      } else {
        setState(() {
          _allExams = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading exams: $e');
    }
  }

  // Add exam to Firestore
  Future<void> _addExamToFirestore({
    required String id,
    required String title,
    required String description,
    required String className,
    required String subject,
    required int duration,
    required int questionCount,
    required String status,
    required List<Map<String, dynamic>> questions,
    required String division,
  }) async {
    try {
      final examData = {
        'division': division,
        'id': id,
        'title': title,
        'description': description,
        'class': className,
        'subject': subject,
        'duration': duration,
        'questionCount': questionCount,
        'status': status,
        'questions': questions
            .map((q) => {
                  'question': q['question'],
                  'options': q['options'],
                  'correctAnswer': q['correctAnswer'],
                  'marks': q['marks'],
                })
            .toList(),
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      final service = StudentService();
      service.addexams('exam-list', examData);
      print(examData);
      // await _firestore.collection('exams').doc('exams_mcq').set([]);
      _showSuccessSnackBar('Exam created successfully');
      _loadExams(); // Reload exams
    } catch (e) {
      _showErrorSnackBar('Error creating exam: $e');
    }
  }

  // Filter exams based on status and search criteria
  List<Map<String, dynamic>> _getFilteredExams(String status) {
    return _allExams.where((exam) {
      final matchesStatus = status == 'All' || exam['status'] == status;
      final matchesSearch = _searchController.text.isEmpty ||
          exam['title']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          exam['description']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      final matchesClass =
          _selectedClass == 'All Classes' || exam['class'] == _selectedClass;
      final matchesSubject = _selectedSubject == 'All Subjects' ||
          exam['subject'] == _selectedSubject;

      return matchesStatus && matchesSearch && matchesClass && matchesSubject;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        title: const Text(
          'MCQ Exam Manager',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
              onPressed: _loadExams,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color.fromARGB(255, 255, 255, 255),
          unselectedLabelColor: const Color.fromARGB(255, 0, 0, 0),
          indicatorColor: const Color.fromARGB(255, 255, 255, 255),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'All Exams'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildExamsTab('All'),
                _buildExamsTab('Upcoming'),
                _buildExamsTab('Active'),
                _buildExamsTab('Completed'),
              ],
            ),
      floatingActionButton: Container(
        child: FloatingActionButton.extended(
          onPressed: _showCreateExamDialog,
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Create Exam'),
        ),
      ),
    );
  }

  Widget _buildExamsTab(String status) {
    final exams = _getFilteredExams(status);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildFilterSection(),
          const SizedBox(height: 24),
          Expanded(
            child: exams.isEmpty
                ? _buildEmptyState(status)
                : ListView.builder(
                    itemCount: exams.length,
                    itemBuilder: (context, index) =>
                        _buildExamCard(exams[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Exams',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search exams...',
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF64748B)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  value: _selectedClass,
                  items: _classes,
                  onChanged: (value) => setState(() => _selectedClass = value!),
                  hint: 'Class',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  value: _selectedSubject,
                  items: _subjects,
                  onChanged: (value) =>
                      setState(() => _selectedSubject = value!),
                  hint: 'Subject',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            status == 'All' ? 'No exams created yet' : 'No $status exams',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first MCQ exam to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final statusColors = {
      'Upcoming': Colors.orange,
      'Active': Colors.green,
      'Completed': Colors.blue,
    };
    final statusColor = statusColors[exam['status']] ?? Colors.grey;

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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.1),
                  const Color(0xFF1E40AF).withOpacity(0.05),
                ],
              ),
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
                        exam['title'] ?? 'Untitled Exam',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        exam['description'] ?? 'No description',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
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
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    exam['status'] ?? 'Unknown',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildExamStat(
                        Icons.school, 'Class', exam['class'] ?? 'N/A'),
                    _buildExamStat(
                        Icons.book, 'Subject', exam['subject'] ?? 'N/A'),
                    _buildExamStat(Icons.timer, 'Duration',
                        '${exam['duration'] ?? 0} min'),
                    _buildExamStat(Icons.quiz, 'Questions',
                        '${exam['questionCount'] ?? 0}'),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: Icons.visibility,
                      label: 'View',
                      color: Colors.grey,
                      onPressed: () => _showViewExamDialog(exam),
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      icon: Icons.edit,
                      label: 'Edit',
                      color: const Color(0xFF3B82F6),
                      onPressed: () => _showEditExamDialog(exam),
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      icon: Icons.delete,
                      label: 'Delete',
                      color: Colors.red,
                      onPressed: () => _showDeleteDialog(exam),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamStat(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  void _showCreateExamDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final durationController = TextEditingController(text: '60');
    final questionCountController = TextEditingController(text: '10');
    String selectDivision = 'M1';
    String selectedClass = '10th';
    String selectedSubject = 'Mathematics';
    String selectedStatus = 'Upcoming';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New MCQ Exam',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextField(titleController, 'Exam Title', Icons.title),
                const SizedBox(height: 16),
                _buildTextField(
                    descriptionController, 'Description', Icons.description,
                    maxLines: 3),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormDropdown(
                        value: selectedClass,
                        items:
                            _classes.where((c) => c != 'All Classes').toList(),
                        onChanged: (value) => selectedClass = value!,
                        label: 'Class',
                        icon: Icons.school,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFormDropdown(
                        value: selectedSubject,
                        items: _subjects
                            .where((s) => s != 'All Subjects')
                            .toList(),
                        onChanged: (value) => selectedSubject = value!,
                        label: 'Subject',
                        icon: Icons.book,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFormDropdown(
                  value: selectDivision,
                  items: _divisions.where((s) => s != 'All Divisions').toList(),
                  onChanged: (value) => selectDivision = value!,
                  label: 'Division',
                  icon: Icons.book,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                          durationController, 'Duration (minutes)', Icons.timer,
                          keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                          questionCountController, 'Question Count', Icons.quiz,
                          keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFormDropdown(
                  value: selectedStatus,
                  items: const ['Upcoming', 'Active'],
                  onChanged: (value) => selectedStatus = value!,
                  label: 'Status',
                  icon: Icons.flag,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (titleController.text.isEmpty ||
                            questionCountController.text.isEmpty) {
                          _showErrorSnackBar(
                              'Please fill in all required fields');
                          return;
                        }
                        Navigator.pop(context);
                        _showAddQuestionsDialog(
                            title: titleController.text,
                            description: descriptionController.text,
                            className: selectedClass,
                            subject: selectedSubject,
                            duration: int.parse(durationController.text),
                            questionCount:
                                int.parse(questionCountController.text),
                            status: selectedStatus,
                            division: selectDivision);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Add Questions'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isSavingExam = false;

  void _showAddQuestionsDialog({
    required String title,
    required String description,
    required String className,
    required String subject,
    required int duration,
    required int questionCount,
    required String status,
    required String division,
  }) {
    List<Map<String, dynamic>> questions = List.generate(
      questionCount,
      (index) => {
        'question': '',
        'options': ['', '', '', ''],
        'correctAnswer': 0,
        'marks': 1,
      },
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Questions - $title',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '$className • $subject • $questionCount Questions',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: questionCount,
                    itemBuilder: (context, index) => Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: _buildQuestionCard(
                        questionNumber: index + 1,
                        question: questions[index],
                        onChanged: () => setDialogState(() {}),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    // Add this as a class variable

// Debugged Save Exam Button
                    ElevatedButton.icon(
                      onPressed: _isSavingExam
                          ? null
                          : () async {
                              setState(() {
                                _isSavingExam = true;
                              });

                              try {
                                print('hi');

                                // Debug: Check if questions is null
                                if (questions == null) {
                                  print('ERROR: questions is null');
                                  _showErrorSnackBar(
                                      'Questions data is not available');
                                  return;
                                }

                                print('Questions length: ${questions.length}');

                                // Safe validation with null checks
                                bool allValid = true;

                                for (int i = 0; i < questions.length; i++) {
                                  final question = questions[i];
                                  print('Checking question $i: $question');

                                  // Check if question exists and has required fields
                                  if (question == null) {
                                    print('ERROR: Question $i is null');
                                    allValid = false;
                                    break;
                                  }

                                  if (question['question'] == null ||
                                      question['question']
                                          .toString()
                                          .trim()
                                          .isEmpty) {
                                    print(
                                        'ERROR: Question $i has empty question text');
                                    allValid = false;
                                    break;
                                  }

                                  if (question['options'] == null) {
                                    print(
                                        'ERROR: Question $i has null options');
                                    allValid = false;
                                    break;
                                  }

                                  final options = question['options'] as List?;
                                  if (options == null || options.isEmpty) {
                                    print(
                                        'ERROR: Question $i has empty options list');
                                    allValid = false;
                                    break;
                                  }

                                  // Check each option
                                  for (int j = 0; j < options.length; j++) {
                                    if (options[j] == null ||
                                        options[j].toString().trim().isEmpty) {
                                      print(
                                          'ERROR: Question $i, option $j is empty');
                                      allValid = false;
                                      break;
                                    }
                                  }

                                  if (!allValid) break;
                                }

                                print('Validation result: $allValid');

                                if (!allValid) {
                                  _showErrorSnackBar(
                                      'Please complete all questions and options');
                                  return;
                                }

                                print('demo - validation passed');

                                // Generate random ID
                                Random random = Random();
                                int randomNumber = random.nextInt(9999999);
                                String examId = "cor@$randomNumber";

                                print('Generated exam ID: $examId');

                                // Close dialog first
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }

                                // Save to Firestore
                                await _addExamToFirestore(
                                    id: examId,
                                    title: title,
                                    description: description,
                                    className: className,
                                    subject: subject,
                                    duration: duration,
                                    questionCount: questionCount,
                                    status: status,
                                    questions: questions,
                                    division: division);

                                print('Exam saved successfully');
                              } catch (e, stackTrace) {
                                print('ERROR in save exam: $e');
                                print('Stack trace: $stackTrace');
                                _showErrorSnackBar(
                                    'Failed to save exam: ${e.toString()}');
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isSavingExam = false;
                                  });
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSavingExam
                            ? Colors.grey
                            : const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      icon: _isSavingExam
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSavingExam ? 'Saving...' : 'Save Exam'),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard({
    required int questionNumber,
    required Map<String, dynamic> question,
    required VoidCallback onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Question $questionNumber',
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 80,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Marks',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    question['marks'] = int.tryParse(value) ?? 1;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Question Text',
              hintText: 'Enter your question here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 2,
            onChanged: (value) {
              question['question'] = value;
              onChanged();
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Answer Options:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(4, (index) {
            final labels = ['A', 'B', 'C', 'D'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Radio<int>(
                    value: index,
                    groupValue: question['correctAnswer'],
                    onChanged: (value) {
                      question['correctAnswer'] = value!;
                      onChanged();
                    },
                    activeColor: const Color(0xFF10B981),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: question['correctAnswer'] == index
                          ? const Color(0xFF10B981).withOpacity(0.2)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: question['correctAnswer'] == index
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Option ${labels[index]}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      onChanged: (value) {
                        question['options'][index] = value;
                        onChanged();
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildFormDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String label,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  void _showViewExamDialog(Map<String, dynamic> exam) {
    final questions = List<Map<String, dynamic>>.from(exam['questions'] ?? []);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'View Exam: ${exam['title']}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildExamInfo('Class', exam['class'] ?? 'N/A'),
                    _buildExamInfo('Subject', exam['subject'] ?? 'N/A'),
                    _buildExamInfo(
                        'Questions', '${exam['questionCount'] ?? 0}'),
                    _buildExamInfo('Duration', '${exam['duration'] ?? 0} min'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: questions.isEmpty
                    ? const Center(
                        child: Text(
                          'No questions found',
                          style:
                              TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final question = questions[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Question ${index + 1} (${question['marks']} marks)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  question['question'] ?? 'No question text',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                ...List.generate(4, (optIndex) {
                                  final options = List<String>.from(
                                      question['options'] ?? []);
                                  if (optIndex >= options.length)
                                    return Container();

                                  final isCorrect =
                                      question['correctAnswer'] == optIndex;
                                  final labels = ['A', 'B', 'C', 'D'];

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isCorrect
                                                ? const Color(0xFF10B981)
                                                : Colors.grey.shade300,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              labels[optIndex],
                                              style: TextStyle(
                                                color: isCorrect
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            options[optIndex],
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isCorrect
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamInfo(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditExamDialog(Map<String, dynamic> exam) {
    final titleController = TextEditingController(text: exam['title']);
    final descriptionController =
        TextEditingController(text: exam['description']);
    final durationController =
        TextEditingController(text: exam['duration'].toString());
    String selectedClass = exam['class'];
    String selectedSubject = exam['subject'];
    String selectedStatus = exam['status'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Exam',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextField(titleController, 'Exam Title', Icons.title),
                const SizedBox(height: 16),
                _buildTextField(
                    descriptionController, 'Description', Icons.description,
                    maxLines: 3),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormDropdown(
                        value: selectedClass,
                        items:
                            _classes.where((c) => c != 'All Classes').toList(),
                        onChanged: (value) => selectedClass = value!,
                        label: 'Class',
                        icon: Icons.school,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFormDropdown(
                        value: selectedSubject,
                        items: _subjects
                            .where((s) => s != 'All Subjects')
                            .toList(),
                        onChanged: (value) => selectedSubject = value!,
                        label: 'Subject',
                        icon: Icons.book,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                          durationController, 'Duration (minutes)', Icons.timer,
                          keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFormDropdown(
                        value: selectedStatus,
                        items: const ['Upcoming', 'Active', 'Completed'],
                        onChanged: (value) => selectedStatus = value!,
                        label: 'Status',
                        icon: Icons.flag,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    // ElevatedButton.icon(
                    //   onPressed: () async {
                    //     final service = StudentService();

                    //     try {

                    //       Navigator.pop(context);
                    //       _showSuccessSnackBar('Exam updated successfully');
                    //       _loadExams();
                    //     } catch (e) {
                    //       _showErrorSnackBar('Error updating exam: $e');
                    //     }
                    //   },
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: const Color(0xFF3B82F6),
                    //     foregroundColor: Colors.white,
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(8),
                    //     ),
                    //   ),
                    //   icon: const Icon(Icons.save),
                    //   label: const Text('Update Exam'),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Exam',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
            'Are you sure you want to delete "${exam['title']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final services = StudentService();
              try {
                await services.deleteExam('exam-list', exam['id']);
                Navigator.pop(context);
                _showSuccessSnackBar('Exam deleted successfully');
                _loadExams();
              } catch (e) {
                _showErrorSnackBar('Error deleting exam: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
