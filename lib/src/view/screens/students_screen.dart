import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({Key? key}) : super(key: key);

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Inactive', 'Due Fees'];

  String _selectedClass = 'All Classes';
  String _selectedDivision = 'All Division';
  String _selectedCourse = 'All Course';

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

  final List<String> _divisions = [
    'All Division',
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

  // ─── Password generator ───────────────────────────────────────────────────
  String _generatePassword({int length = 10}) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

  // ─── Filtering ────────────────────────────────────────────────────────────
  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> docs) {
    final query = _searchController.text.toLowerCase();

    var list = docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final name = (d['student_name'] ?? '').toString().toLowerCase();
      final id = (d['id'] ?? '').toString().toLowerCase();
      final email = (d['email'] ?? '').toString().toLowerCase();

      final matchesSearch =
          name.contains(query) || id.contains(query) || email.contains(query);

      final matchesStatus = _selectedFilter == 'All' ||
          (_selectedFilter == 'Due Fees'
              ? d['fee_status'] == 'Due'
              : d['status'] == _selectedFilter);

      final matchesClass =
          _selectedClass == 'All Classes' || d['class'] == _selectedClass;

      final matchesDivision = _selectedDivision == 'All Division' ||
          d['division'] == _selectedDivision;

      final matchesCourse =
          _selectedCourse == 'All Course' || d['course'] == _selectedCourse;

      return matchesSearch &&
          matchesStatus &&
          matchesClass &&
          matchesDivision &&
          matchesCourse;
    }).toList();

    // Sort by roll number when a specific class + division is chosen
    if (_selectedClass != 'All Classes' &&
        _selectedDivision != 'All Division') {
      list.sort((a, b) {
        final da = a.data() as Map<String, dynamic>;
        final db = b.data() as Map<String, dynamic>;
        final ra = int.tryParse(da['rollNo']?.toString() ?? '') ?? 0;
        final rb = int.tryParse(db['rollNo']?.toString() ?? '') ?? 0;
        return ra.compareTo(rb);
      });
    }

    return list;
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────

  /// Add / Register student via Firebase Auth + Firestore
  void _showAddStudentDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final rollNoCtrl = TextEditingController();
    final dobCtrl = TextEditingController();
    final dojCtrl = TextEditingController();
    final admissionCtrl = TextEditingController();

    String selClass = '10th';
    String selDivision = 'M1';
    String selCourse = '';
    String selStatus = 'Active';
    String selFeeStatus = 'Paid';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Register New Student'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(nameCtrl, 'Full Name'),
                  _field(emailCtrl, 'Email', type: TextInputType.emailAddress),
                  _field(phoneCtrl, 'Phone Number', type: TextInputType.phone),
                  _field(rollNoCtrl, 'Roll No', type: TextInputType.number),
                  _field(dobCtrl, 'Date of Birth'),
                  _field(dojCtrl, 'Date of Joining'),
                  const SizedBox(height: 16),
                  _dropdownField(
                    label: 'Class',
                    value: selClass,
                    items: _classes.where((c) => c != 'All Classes').toList(),
                    onChanged: (v) => setDialogState(() => selClass = v!),
                  ),
                  const SizedBox(height: 16),
                  _dropdownField(
                    label: 'Division',
                    value: selDivision,
                    items:
                        _divisions.where((c) => c != 'All Division').toList(),
                    onChanged: (v) => setDialogState(() => selDivision = v!),
                  ),
                  const SizedBox(height: 16),
                  _field(TextEditingController()..addListener(() {}), 'Course',
                      onChanged: (v) => selCourse = v),
                  _dropdownField(
                    label: 'Status',
                    value: selStatus,
                    items: const ['Active', 'Inactive'],
                    onChanged: (v) => setDialogState(() => selStatus = v!),
                  ),
                  const SizedBox(height: 16),
                  _dropdownField(
                    label: 'Fee Status',
                    value: selFeeStatus,
                    items: const ['Paid', 'Due', 'Partial'],
                    onChanged: (v) => setDialogState(() => selFeeStatus = v!),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty ||
                          emailCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Name and Email are required'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setDialogState(() => isLoading = true);

                      try {
                        // final password = _generatePassword();

                        // 1. Create Firebase Auth account
                        final credential =
                            await _auth.createUserWithEmailAndPassword(
                          email: emailCtrl.text.trim(),
                          password: 'lmsSupport@123',
                        );

                        final uid = credential.user!.uid;

                        // 2. Save to Firestore users/{uid}
                        await _firestore.collection('users').doc(uid).set({
                          'uid': uid,
                          'student_name': nameCtrl.text.trim(),
                          'role': 'student',
                          'admissionNumber': admissionCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'contact': phoneCtrl.text.trim(),
                          'rollNo': rollNoCtrl.text.trim(),
                          'dob': dobCtrl.text.trim(),
                          'doj': dojCtrl.text.trim(),
                          'class': selClass,
                          'division': selDivision,
                          'course': selCourse,
                          'status': selStatus,
                          'fee_status': selFeeStatus,
                          'password': 'lms@student.com',
                          'image': '',
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Student registered! Temp password: lmsSupport@123'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 6),
                          ),
                        );
                      } on FirebaseAuthException catch (e) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.message ?? 'Auth error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Register Student'),
            ),
          ],
        ),
      ),
    );
  }

  /// Edit student — updates Firestore only (Auth email/password untouched here)
  void _showEditStudentDialog(Map<String, dynamic> student, String docId) {
    final nameCtrl = TextEditingController(text: student['student_name']);
    final admctrl = TextEditingController(text: student['admissionNumber']);
    final emailCtrl = TextEditingController(text: student['email']);
    final phoneCtrl = TextEditingController(text: student['contact']);
    final passwordCtrl = TextEditingController(text: student['password']);
    final dobCtrl = TextEditingController(text: student['dob']);
    final dojCtrl = TextEditingController(text: student['doj']);
    final rollNoCtrl = TextEditingController(text: student['rollNo']);
    final courseCtrl = TextEditingController(text: student['course']);

    String selClass = student['class'] ?? '10th';
    String selDivision = student['division'] ?? 'M1';
    String selStatus = student['status'] ?? 'Active';
    String selFeeStatus = student['fee_status'] ?? 'Paid';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Student'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(nameCtrl, 'Full Name'),
                  _field(emailCtrl, 'Email', type: TextInputType.emailAddress),
                  _field(phoneCtrl, 'Phone Number', type: TextInputType.phone),
                  _field(passwordCtrl, 'Password'),
                  _field(admctrl, 'Admission Number'),
                  _field(dobCtrl, 'Date of Birth'),
                  _field(dojCtrl, 'Date of Joining'),
                  _field(rollNoCtrl, 'Roll No', type: TextInputType.number),
                  _field(courseCtrl, 'Course'),
                  const SizedBox(height: 16),
                  _dropdownField(
                    label: 'Class',
                    value: selClass,
                    items: _classes.where((c) => c != 'All Classes').toList(),
                    onChanged: (v) => setDialogState(() => selClass = v!),
                  ),
                  const SizedBox(height: 16),
                  _dropdownField(
                    label: 'Division',
                    value: selDivision,
                    items:
                        _divisions.where((c) => c != 'All Division').toList(),
                    onChanged: (v) => setDialogState(() => selDivision = v!),
                  ),
                  const SizedBox(height: 16),
                  _dropdownField(
                    label: 'Status',
                    value: selStatus,
                    items: const ['Active', 'Inactive'],
                    onChanged: (v) => setDialogState(() => selStatus = v!),
                  ),
                  const SizedBox(height: 16),
                  _dropdownField(
                    label: 'Fee Status',
                    value: selFeeStatus,
                    items: const ['Paid', 'Due', 'Partial'],
                    onChanged: (v) => setDialogState(() => selFeeStatus = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _firestore.collection('users').doc(docId).update({
                  'student_name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'role': 'student',
                  'admissionNumber': admctrl.text.trim(),
                  'contact': phoneCtrl.text.trim(),
                  'password': passwordCtrl.text.trim(),
                  'dob': dobCtrl.text.trim(),
                  'doj': dojCtrl.text.trim(),
                  'rollNo': rollNoCtrl.text.trim(),
                  'course': courseCtrl.text.trim(),
                  'class': selClass,
                  'division': selDivision,
                  'status': selStatus,
                  'fee_status': selFeeStatus,
                });
                Navigator.pop(ctx);
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
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Update Student'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> student, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student'),
        content:
            Text('Are you sure you want to delete ${student['student_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('users').doc(docId).delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStudentDetailsDialog(Map<String, dynamic> student, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Student Details',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800])),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Name banner ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Student Name',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[700])),
                      const SizedBox(height: 4),
                      Text(
                        student['student_name'] ?? 'N/A',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _detailRow('Class', student['class']),
                _detailRow('Division', student['division']),
                _detailRow('Course', student['course']),
                _detailRow('Roll No', student['rollNo']),
                _detailRow('Status', student['status']),
                _detailRow('Fee Status', student['fee_status']),
                _detailRow('Contact', student['contact']),
                _detailRow('Email', student['email']),
                _detailRow('Student UID', docId),
                _detailRow('Date of Birth', student['dob']),
                _detailRow('Date of Joining', student['doj']),
                const SizedBox(height: 24),

                // ── Action row ──
                Row(
                  children: [
                    // Toggle Active/Inactive
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final newStatus = student['status'] == 'Active'
                              ? 'Inactive'
                              : 'Active';
                          await _firestore
                              .collection('users')
                              .doc(docId)
                              .update({'status': newStatus});
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Status changed to $newStatus'),
                              backgroundColor: newStatus == 'Active'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          );
                        },
                        icon: Icon(
                          student['status'] == 'Active'
                              ? Icons.person_off
                              : Icons.person,
                        ),
                        label: Text(
                          student['status'] == 'Active'
                              ? 'Set Inactive'
                              : 'Set Active',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: student['status'] == 'Active'
                              ? Colors.orange
                              : Colors.green,
                          side: BorderSide(
                            color: student['status'] == 'Active'
                                ? Colors.orange
                                : Colors.green,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Edit
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showEditStudentDialog(student, docId);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Delete
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showDeleteDialog(student, docId);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Close
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Close',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Students',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
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
            // ── Search + Add ──
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
                      onChanged: (_) => setState(() {}),
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
                  onPressed: _showAddStudentDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Register Student'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Filters ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status chips
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: _filters.map((f) {
                          final sel = _selectedFilter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: sel,
                              label: Text(f),
                              onSelected: (_) =>
                                  setState(() => _selectedFilter = f),
                              backgroundColor: Colors.white,
                              selectedColor:
                                  const Color(0xFF3B82F6).withOpacity(0.1),
                              checkmarkColor: const Color(0xFF3B82F6),
                              labelStyle: TextStyle(
                                  color: sel
                                      ? const Color(0xFF3B82F6)
                                      : Colors.black,
                                  fontWeight: sel
                                      ? FontWeight.bold
                                      : FontWeight.normal),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                    color: sel
                                        ? const Color(0xFF3B82F6)
                                        : Colors.grey.shade300),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),

                  // Division dropdown
                  _filterDropdown(
                    label: 'Division',
                    value: _selectedDivision,
                    items: _divisions,
                    onChanged: (v) => setState(() => _selectedDivision = v!),
                  ),
                  const SizedBox(width: 24),

                  // Class dropdown
                  _filterDropdown(
                    label: 'Class',
                    value: _selectedClass,
                    items: _classes,
                    onChanged: (v) => setState(() => _selectedClass = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Table ──
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
                    // Header row
                    const Padding(
                      padding: EdgeInsets.fromLTRB(32, 16, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text('Name',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey))),
                          Expanded(
                              child: Text('Roll No',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey))),
                          Expanded(
                              child: Text('Class',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey))),
                          Expanded(
                              child: Text('Division',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey))),
                          Expanded(
                              child: Text('Status',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey))),
                          Expanded(
                              child: Text('Fee Status',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey))),
                          SizedBox(width: 80),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Live Firestore stream
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('users')
                            .where('role', isEqualTo: 'student')
                            .snapshots(),
                        builder: (ctx, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }

                          final docs = snapshot.data?.docs ?? [];
                          final filtered = _applyFilters(docs);

                          if (filtered.isEmpty) {
                            return const Center(
                              child: Text('No students found',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16)),
                            );
                          }

                          return ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final doc = filtered[i];
                              final s = doc.data() as Map<String, dynamic>;
                              final docId = doc.id;

                              return InkWell(
                                onTap: () =>
                                    _showStudentDetailsDialog(s, docId),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 16),
                                      // Name + email
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: Colors.blue[100],
                                              child: Text(
                                                (s['student_name'] ?? 'S')
                                                    .toString()
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                    color: Colors.blue[700],
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  s['student_name'] ?? '',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                  s['email'] ?? '',
                                                  style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                          child: Text(
                                              s['rollNo']?.toString() ?? '-')),
                                      Expanded(
                                          child: Text(
                                              s['class']?.toString() ?? '-')),
                                      Expanded(
                                          child: Text(
                                              s['division']?.toString() ??
                                                  '-')),
                                      // Status badge
                                      Expanded(
                                        child: _statusBadge(
                                          s['status'],
                                          activeColor: Colors.green,
                                          inactiveColor: Colors.red,
                                        ),
                                      ),
                                      // Fee badge
                                      Expanded(
                                        child: _feeBadge(s['fee_status']),
                                      ),
                                      // Actions
                                      SizedBox(
                                        width: 80,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  color: Color(0xFF3B82F6),
                                                  size: 20),
                                              onPressed: () =>
                                                  _showEditStudentDialog(
                                                      s, docId),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red, size: 20),
                                              onPressed: () =>
                                                  _showDeleteDialog(s, docId),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType type = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: items.contains(value) ? value : null,
      items: items
          .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map(
                      (v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(
    String? status, {
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isActive = status == 'Active';
    final color = isActive ? activeColor : inactiveColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status ?? '-',
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _feeBadge(String? fee) {
    Color color;
    if (fee == 'Paid') {
      color = Colors.green;
    } else if (fee == 'Due') {
      color = Colors.red;
    } else {
      color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        fee ?? '-',
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600])),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                value?.toString() ?? 'N/A',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
