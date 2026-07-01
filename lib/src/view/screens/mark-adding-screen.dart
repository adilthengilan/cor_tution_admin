import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ─── Max Mark Manager ────────────────────────────────────────────────────────

class MaxMarkManager {
  static double maxMark = 100;
  static void updateMaxMark(double v) => maxMark = v;
}

// ─── Student Model ────────────────────────────────────────────────────────────

class StudentModel {
  final String uid;
  final String name;
  final String className;
  final String division;
  final String rollNo;
  final String contact;

  StudentModel({
    required this.uid,
    required this.name,
    required this.className,
    required this.division,
    required this.rollNo,
    required this.contact,
  });

  factory StudentModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StudentModel(
      uid: doc.id,
      name: d['student_name'] ?? '',
      className: d['class'] ?? '',
      division: d['division'] ?? '',
      rollNo: d['rollNo'] ?? '',
      contact: d['contact'] ?? '',
    );
  }
}

// ─── Mark Adding Page ─────────────────────────────────────────────────────────

class MarkAddingPage extends StatefulWidget {
  const MarkAddingPage({Key? key}) : super(key: key);

  @override
  State<MarkAddingPage> createState() => _MarkAddingPageState();
}

class _MarkAddingPageState extends State<MarkAddingPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  // Controllers
  final _markController = TextEditingController();
  final _examNameController = TextEditingController();
  final _outOfController = TextEditingController(text: '100');
  final _gradeController = TextEditingController();
  final _searchController = TextEditingController();

  // State
  List<StudentModel> _allStudents = [];
  List<StudentModel> _filteredStudents = [];
  StudentModel? _selectedStudent;

  String? _selectedClass;
  String? _selectedDivision;
  String? _selectedSubject;
  DateTime _selectedDate = DateTime.now();

  bool _isFetchingStudents = false;
  bool _isSaving = false;

  String _searchQuery = '';
  String _teacherName = '';
  String _teacherSubject = '';

  // Options
  final _classes = ['6th', '7th', '8th', '9th', '10th', '11th', '12th'];
  final _divisions = [
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
  final _subjects = [
    'Maths',
    'Physics',
    'Chemistry',
    'Biology',
    'Hindi',
    'History',
    'Geography',
    'English',
    'Arabic'
  ];

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) => _resolveTeacher());
  }

  // void _resolveTeacher() {
  //   final ctrl = Provider.of<fetchclass>(context, listen: false);
  //   final local = Provider.of<LocalStorageService>(context, listen: false);

  //   final idx = ctrl.teachers.indexWhere(
  //     (t) => t['contact'] == local.index2,
  //   );

  //   if (idx != -1) {
  //     setState(() {
  //       _teacherName = ctrl.teachers[idx]['student_name'] ?? '';
  //       _teacherSubject = ctrl.teachers[idx]['class'] ?? '';
  //       // Pre-select the subject that matches the teacher's subject
  //       if (_subjects.contains(_teacherSubject)) {
  //         _selectedSubject = _teacherSubject;
  //       }
  //     });
  //   }
  // }

  // ── Firestore: fetch students ───────────────────────────────────────────────

  Future<void> _fetchStudents() async {
    if (_selectedClass == null || _selectedDivision == null) return;

    setState(() {
      _isFetchingStudents = true;
      _allStudents = [];
      _filteredStudents = [];
      _selectedStudent = null;
      _searchQuery = '';
      _searchController.clear();
    });

    try {
      final snap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('class', isEqualTo: _selectedClass)
          .where('division', isEqualTo: _selectedDivision)
          .where('status', isEqualTo: 'Active')
          .get();

      final students = snap.docs.map((d) => StudentModel.fromDoc(d)).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _allStudents = students;
        _filteredStudents = students;
      });
    } catch (e) {
      _showSnackbar('Failed to load students: $e', isError: true);
    } finally {
      setState(() => _isFetchingStudents = false);
    }
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
      final q = query.toLowerCase();
      _filteredStudents = _allStudents.where((s) {
        return s.name.toLowerCase().contains(q) ||
            s.rollNo.toLowerCase().contains(q) ||
            s.contact.contains(q);
      }).toList();
    });
  }

  // ── Firestore: save mark ────────────────────────────────────────────────────

  Future<void> _saveMark() async {
    if (!_validateForm()) return;

    setState(() => _isSaving = true);

    try {
      final markData = {
        'studentName': _selectedStudent!.name,
        'studentId': _selectedStudent!.uid,
        'rollNo': _selectedStudent!.rollNo,
        'class': _selectedClass,
        'division': _selectedDivision,
        'subject': _selectedSubject,
        'examName': _examNameController.text.trim(),
        'mark': int.parse(_markController.text.trim()),
        'outOf': int.parse(_outOfController.text.trim()),
        'grade': _gradeController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate),
        'teacherName': _teacherName,
        'teacherSubject': _teacherSubject,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save as sub-collection under the student's document
      await _firestore
          .collection('users')
          .doc(_selectedStudent!.uid)
          .collection('marks')
          .add(markData);

      _showSnackbar('Mark saved successfully!', isError: false);

      await Future.delayed(const Duration(milliseconds: 400));
      // if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackbar('Error saving mark: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _validateForm() {
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    if (_selectedClass == null) {
      _showSnackbar('Select a class', isError: true);
      return false;
    }
    if (_selectedDivision == null) {
      _showSnackbar('Select a division', isError: true);
      return false;
    }
    if (_selectedSubject == null) {
      _showSnackbar('Select a subject', isError: true);
      return false;
    }
    if (_selectedStudent == null) {
      _showSnackbar('Select a student', isError: true);
      return false;
    }
    return true;
  }

  void _showSnackbar(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _markController.dispose();
    _examNameController.dispose();
    _outOfController.dispose();
    _gradeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Add Mark',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _teacherCard(),
                const SizedBox(height: 14),
                _classDivisionSubjectCard(),
                const SizedBox(height: 14),
                _studentSelectionCard(),
                const SizedBox(height: 14),
                _markEntryCard(),
                const SizedBox(height: 14),
                _datePicker(),
                const SizedBox(height: 14),
                _markPreview(),
                const SizedBox(height: 24),
                _actionButtons(),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isSaving) _loadingOverlay(),
        ],
      ),
    );
  }

  // ── Teacher Card ────────────────────────────────────────────────────────────

  Widget _teacherCard() {
    return _card(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue[100],
            child: Icon(Icons.person, color: Colors.blue[700], size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Teacher',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(_teacherName.isEmpty ? '—' : _teacherName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                if (_teacherSubject.isNotEmpty)
                  Text('Subject: $_teacherSubject',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Class / Division / Subject ──────────────────────────────────────────────

  Widget _classDivisionSubjectCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Class & Division'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _dropdown(
                label: 'Class',
                icon: Icons.school,
                value: _selectedClass,
                items: _classes,
                onChanged: (v) {
                  setState(() {
                    _selectedClass = v;
                    _selectedDivision = null;
                    _allStudents = [];
                    _filteredStudents = [];
                    _selectedStudent = null;
                  });
                },
                validator: (v) => v == null ? 'Required' : null,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _dropdown(
                label: 'Division',
                icon: Icons.groups,
                value: _selectedDivision,
                items: _divisions,
                onChanged: (v) {
                  setState(() {
                    _selectedDivision = v;
                    _selectedStudent = null;
                  });
                  _fetchStudents();
                },
                validator: (v) => v == null ? 'Required' : null,
              )),
            ],
          ),
          const SizedBox(height: 12),
          _dropdown(
            label: 'Subject',
            icon: Icons.menu_book,
            value: _selectedSubject,
            items: _subjects,
            onChanged: (v) => setState(() => _selectedSubject = v),
            validator: (v) => v == null ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  // ── Student Selection ───────────────────────────────────────────────────────

  Widget _studentSelectionCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Select Student'),
          const SizedBox(height: 12),

          // Search bar (shown only when students are loaded)
          if (_allStudents.isNotEmpty) ...[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or roll no...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _applySearch('');
                        })
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                isDense: true,
              ),
              onChanged: _applySearch,
            ),
            const SizedBox(height: 10),
          ],

          if (_isFetchingStudents)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator()))
          else if (_selectedClass == null || _selectedDivision == null)
            _emptyState(
                Icons.touch_app_outlined, 'Select class & division first')
          else if (_allStudents.isEmpty)
            _emptyState(Icons.person_off_outlined,
                'No students found in\n$_selectedClass - $_selectedDivision')
          else if (_filteredStudents.isEmpty)
            _emptyState(Icons.search_off, 'No match for "$_searchQuery"')
          else ...[
            // Student count chip
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                      '${_filteredStudents.length} student${_filteredStudents.length != 1 ? 's' : ''}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w600)),
                ),
                if (_selectedStudent != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      Icon(Icons.check_circle,
                          size: 14, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(_selectedStudent!.name,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Student list
            SizedBox(
              height: 220,
              child: ListView.separated(
                itemCount: _filteredStudents.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final s = _filteredStudents[i];
                  final selected = _selectedStudent?.uid == s.uid;
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          selected ? Colors.blue[600] : Colors.grey[200],
                      child: Text(
                        s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: selected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                    title: Text(s.name,
                        style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14)),
                    subtitle: Text(
                        'Roll: ${s.rollNo}  •  ${s.className} ${s.division}',
                        style: const TextStyle(fontSize: 11)),
                    trailing: selected
                        ? Icon(Icons.check_circle,
                            color: Colors.green[600], size: 20)
                        : null,
                    selected: selected,
                    selectedTileColor: Colors.blue[50],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    onTap: () => setState(() => _selectedStudent = s),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Mark Entry ──────────────────────────────────────────────────────────────

  Widget _markEntryCard() {
    double maxMark = MaxMarkManager.maxMark;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Mark Details'),
          const SizedBox(height: 12),
          Row(
            children: [
              // Mark field
              Expanded(
                child: TextFormField(
                  controller: _markController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((old, nv) {
                      if (nv.text.isEmpty) return nv;
                      final v = int.tryParse(nv.text);
                      if (v == null || v > maxMark) return old;
                      return nv;
                    }),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Mark',
                    prefixIcon: const Icon(Icons.grade),
                    suffixText: '/${maxMark.toInt()}',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final m = int.tryParse(v);
                    if (m == null || m < 0 || m > maxMark)
                      return '0–${maxMark.toInt()}';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              // Out of field
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: _outOfController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Out of',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 14),
                  ),
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null && n > 0) {
                      MaxMarkManager.updateMaxMark(n.toDouble());
                      final cur = int.tryParse(_markController.text);
                      if (cur != null && cur > n) _markController.clear();
                      setState(() {});
                    }
                  },
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _examNameController,
                  decoration: InputDecoration(
                    labelText: 'Exam Name',
                    prefixIcon: const Icon(Icons.quiz),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _gradeController,
                  decoration: InputDecoration(
                    labelText: 'Grade (A+, B…)',
                    prefixIcon: const Icon(Icons.grading),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Date Picker ─────────────────────────────────────────────────────────────

  Widget _datePicker() {
    return _card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) setState(() => _selectedDate = picked);
        },
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Exam Date',
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
          ),
          child: Text(DateFormat('MMMM dd, yyyy').format(_selectedDate),
              style: const TextStyle(fontSize: 15)),
        ),
      ),
    );
  }

  // ── Mark Preview ────────────────────────────────────────────────────────────

  Widget _markPreview() {
    if (_markController.text.isEmpty ||
        _selectedStudent == null ||
        _gradeController.text.isEmpty) {
      return const SizedBox.shrink();
    }
    final mark = int.tryParse(_markController.text);
    final outOf = int.tryParse(_outOfController.text) ?? 100;
    if (mark == null) return const SizedBox.shrink();

    final pct = (mark / outOf * 100).clamp(0, 100);
    final color = pct >= 80
        ? Colors.green
        : pct >= 60
            ? Colors.orange
            : Colors.red;

    return _card(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(
              child: Text(_gradeController.text,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preview',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(_selectedStudent!.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                    '${_examNameController.text.isEmpty ? 'Exam' : _examNameController.text} — ${_selectedSubject ?? ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$mark / $outOf',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text('${pct.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  // ── Action Buttons ──────────────────────────────────────────────────────────

  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveMark,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            child: _isSaving
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 8),
                      Text('Saving...'),
                    ],
                  )
                : const Text('Save Mark',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // ── Loading Overlay ─────────────────────────────────────────────────────────

  Widget _loadingOverlay() {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 14),
                Text('Saving mark…',
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared Helpers ──────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.blue[800],
            letterSpacing: 0.3));
  }

  Widget _dropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _emptyState(IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey[500], fontSize: 14, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
