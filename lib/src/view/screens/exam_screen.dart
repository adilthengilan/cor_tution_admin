import 'package:corona_lms_webapp/src/controller/student_controllers/student_service_controller.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:corona_lms_webapp/main.dart';

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
      // print(examData);
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
      backgroundColor: MyApp.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: MyApp.borderColor)),
        title: Text(
          'Academic Examinations',
          style: TextStyle(
            color: MyApp.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: MyApp.textSecondaryColor),
            onPressed: _loadExams,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: MyApp.primaryColor,
          unselectedLabelColor: MyApp.textSecondaryColor,
          indicatorColor: MyApp.primaryColor,
          indicatorWeight: 2,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateExamDialog,
        backgroundColor: MyApp.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Exam'),
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
        border: Border.all(color: MyApp.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Exams',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MyApp.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13),
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search exams...',
                    hintStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: MyApp.textSecondaryColor, size: 18),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: MyApp.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: MyApp.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: MyApp.primaryColor),
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
        color: Colors.white,
        border: Border.all(color: MyApp.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: MyApp.textSecondaryColor, fontSize: 13)),
          isExpanded: true,
          dropdownColor: Colors.white,
          style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13),
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
            color: MyApp.textSecondaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            status == 'All' ? 'No exams created yet' : 'No $status exams',
            style: TextStyle(
              fontSize: 18,
              color: MyApp.textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first MCQ exam to get started',
            style: TextStyle(
              fontSize: 14,
              color: MyApp.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final statusColors = {
      'Upcoming': MyApp.warningColor,
      'Active': MyApp.successColor,
      'Completed': MyApp.primaryColor,
    };
    final statusColor = statusColors[exam['status']] ?? MyApp.textSecondaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: MyApp.borderColor)),
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: MyApp.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        exam['description'] ?? 'No description',
                        style: TextStyle(
                          color: MyApp.textSecondaryColor,
                          fontSize: 13,
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
                    exam['status'] ?? 'Unknown',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
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
                      color: MyApp.textSecondaryColor,
                      onPressed: () => _showViewExamDialog(exam),
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      icon: Icons.edit,
                      label: 'Edit',
                      color: MyApp.primaryColor,
                      onPressed: () => _showEditExamDialog(exam),
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      icon: Icons.delete,
                      label: 'Delete',
                      color: MyApp.errorColor,
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
          Icon(icon, size: 16, color: MyApp.textSecondaryColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: MyApp.textSecondaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: MyApp.textPrimaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
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
        backgroundColor: color.withOpacity(0.08),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _showCreateExamDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final durationController = TextEditingController(text: '60');
    final questionCountController = TextEditingController(text: '10');
    List<String> selectedDivisions = ['M1'];
    String selectedClass = '10th';
    String selectedSubject = 'Mathematics';
    String selectedStatus = 'Upcoming';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New MCQ Exam',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: MyApp.textPrimaryColor,
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
                          items: _classes
                              .where((c) => c != 'All Classes')
                              .toList(),
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
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: MyApp.borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Divisions',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: MyApp.textSecondaryColor,
                            ),
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: SingleChildScrollView(
                            child: Column(
                              children: _divisions
                                  .where((c) => c != 'All Divisions')
                                  .map((String divisionName) {
                                return CheckboxListTile(
                                  title: Text(divisionName, style: TextStyle(color: MyApp.textPrimaryColor)),
                                  value:
                                      selectedDivisions.contains(divisionName),
                                  activeColor: MyApp.primaryColor,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedDivisions.add(divisionName);
                                      } else {
                                        selectedDivisions.remove(divisionName);
                                      }
                                    });
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  dense: true,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(durationController,
                            'Duration (minutes)', Icons.timer,
                            keyboardType: TextInputType.number),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(questionCountController,
                            'Question Count', Icons.quiz,
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
                        child: Text('Cancel', style: TextStyle(color: MyApp.textSecondaryColor)),
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
                              division: selectedDivisions);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyApp.primaryColor,
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
    required division,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
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
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: MyApp.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$className • $subject • $questionCount Questions',
                            style: TextStyle(
                              fontSize: 14,
                              color: MyApp.textSecondaryColor,
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
                      child: Text('Cancel', style: TextStyle(color: MyApp.textSecondaryColor)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isSavingExam
                          ? null
                          : () async {
                              setState(() {
                                _isSavingExam = true;
                              });

                              try {
                                if (questions == null) {
                                  _showErrorSnackBar(
                                      'Questions data is not available');
                                  return;
                                }

                                bool allValid = true;

                                for (int i = 0; i < questions.length; i++) {
                                  final question = questions[i];
                                  if (question == null) {
                                    allValid = false;
                                    break;
                                  }

                                  if (question['question'] == null ||
                                      question['question']
                                          .toString()
                                          .trim()
                                          .isEmpty) {
                                    allValid = false;
                                    break;
                                  }

                                  if (question['options'] == null) {
                                    allValid = false;
                                    break;
                                  }

                                  final options = question['options'] as List?;
                                  if (options == null || options.isEmpty) {
                                    allValid = false;
                                    break;
                                  }

                                  for (int j = 0; j < options.length; j++) {
                                    if (options[j] == null ||
                                        options[j].toString().trim().isEmpty) {
                                      allValid = false;
                                      break;
                                    }
                                  }

                                  if (!allValid) break;
                                }

                                if (!allValid) {
                                  _showErrorSnackBar(
                                      'Please complete all questions and options');
                                  return;
                                }

                                Random random = Random();
                                int randomNumber = random.nextInt(9999999);
                                String examId = "cor@$randomNumber";

                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }

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
                              } catch (e) {
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
                            : MyApp.successColor,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyApp.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
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
                  color: MyApp.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Question $questionNumber',
                  style: TextStyle(
                    color: MyApp.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 100,
                child: TextField(
                  style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Marks',
                    labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(8),
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
            style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Question Text',
              labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 12),
              hintText: 'Enter your question here...',
              hintStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: MyApp.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: MyApp.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: MyApp.primaryColor),
              ),
            ),
            maxLines: 2,
            onChanged: (value) {
              question['question'] = value;
              onChanged();
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Answer Options:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: MyApp.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(4, (index) {
            final labels = ['A', 'B', 'C', 'D'];
            final isCorrect = question['correctAnswer'] == index;
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
                    activeColor: MyApp.successColor,
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? MyApp.successColor.withOpacity(0.1)
                          : MyApp.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isCorrect ? MyApp.successColor : MyApp.borderColor),
                    ),
                    child: Center(
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCorrect
                              ? MyApp.successColor
                              : MyApp.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Option ${labels[index]}',
                        hintStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: MyApp.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: MyApp.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: MyApp.primaryColor),
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
      style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 12),
        prefixIcon: Icon(icon, color: MyApp.textSecondaryColor, size: 18),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyApp.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyApp.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyApp.primaryColor),
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
      dropdownColor: Colors.white,
      style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 12),
        prefixIcon: Icon(icon, color: MyApp.textSecondaryColor, size: 18),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyApp.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyApp.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyApp.primaryColor),
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
        backgroundColor: Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'View Exam: ${exam['title']}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: MyApp.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MyApp.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MyApp.primaryColor.withOpacity(0.1)),
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
                    ? Center(
                        child: Text(
                          'No questions found',
                          style: TextStyle(fontSize: 16, color: MyApp.textSecondaryColor),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: MyApp.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Question ${index + 1} (${question['marks']} marks)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: MyApp.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  question['question'] ?? 'No question text',
                                  style: TextStyle(fontSize: 14, color: MyApp.textPrimaryColor),
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
                                                ? MyApp.successColor
                                                : MyApp.borderColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              labels[optIndex],
                                              style: TextStyle(
                                                color: isCorrect
                                                    ? Colors.white
                                                    : MyApp.textSecondaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
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
                                              color: MyApp.textPrimaryColor,
                                              fontWeight: isCorrect
                                                  ? FontWeight.bold
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
                    child: Text('Close', style: TextStyle(color: MyApp.textSecondaryColor)),
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
            style: TextStyle(
              fontSize: 12,
              color: MyApp.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: MyApp.textPrimaryColor,
              fontWeight: FontWeight.bold,
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
        backgroundColor: Colors.white,
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Exam',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: MyApp.textPrimaryColor,
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
                      child: Text('Cancel', style: TextStyle(color: MyApp.textSecondaryColor)),
                    ),
                    const SizedBox(width: 16),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Exam',
          style: TextStyle(fontWeight: FontWeight.bold, color: MyApp.textPrimaryColor),
        ),
        content: Text(
            'Are you sure you want to delete "${exam['title']}"? This action cannot be undone.',
            style: TextStyle(color: MyApp.textSecondaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: MyApp.textSecondaryColor)),
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
              backgroundColor: MyApp.errorColor,
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
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: MyApp.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: MyApp.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
