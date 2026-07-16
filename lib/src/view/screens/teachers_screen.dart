import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:corona_lms_webapp/main.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({Key? key}) : super(key: key);

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _selectedSubject = 'All Subjects';
  String _sortField = 'student_name';
  bool _sortAscending = true;

  final List<String> _filters = ['All', 'Active', 'Inactive'];
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

  // ── Password generator ───────────────────────────────────────
  String _generatePassword({int length = 10}) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

  // ── Firestore stream — only role == 'teacher' ────────────────
  Stream<List<Map<String, dynamic>>> _teachersStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['docId'] = doc.id; // doc.id == uid
              return data;
            }).toList());
  }

  // ── Client-side filter + sort ────────────────────────────────
  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> teachers) {
    final query = _searchController.text.toLowerCase();

    var filtered = teachers.where((t) {
      final name = (t['student_name'] ?? '').toString().toLowerCase();
      final email = (t['email'] ?? '').toString().toLowerCase();
      final contact = (t['contact'] ?? '').toString().toLowerCase();

      final matchesSearch = name.contains(query) ||
          email.contains(query) ||
          contact.contains(query);
      final matchesStatus =
          _selectedFilter == 'All' || t['status'] == _selectedFilter;
      final matchesSubject =
          _selectedSubject == 'All Subjects' || t['class'] == _selectedSubject;

      return matchesSearch && matchesStatus && matchesSubject;
    }).toList();

    filtered.sort((a, b) {
      final av = (a[_sortField] ?? '').toString().toLowerCase();
      final bv = (b[_sortField] ?? '').toString().toLowerCase();
      return _sortAscending ? av.compareTo(bv) : bv.compareTo(av);
    });

    return filtered;
  }

  // ── Add Teacher (Firebase Auth + users collection only) ──────
  Future<void> _addTeacher({
    required String name,
    required String email,
    required String phone,
    required String subject,
    required String status,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // Write everything to users/{uid}
      await _firestore.collection('users').doc(uid).set({
        'role': 'teacher',
        'teacher_name': name,
        'student_name': name, // Store in student_name as well to match filters/sorting
        'email': email,
        'contact': phone,
        'class': subject,
        'status': status,
        'password': '$name@teacher.com',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Firebase Auth error');
    }
  }

  // ── Update Teacher (users collection only) ───────────────────
  Future<void> _updateTeacher(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // ── Delete Teacher (users collection only) ───────────────────
  Future<void> _deleteTeacher(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  // ── Sort toggle ──────────────────────────────────────────────
  void _onSort(String field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          'Teachers',
          style: TextStyle(color: MyApp.textPrimaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: MyApp.textSecondaryColor),
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
            // ── Search + Add ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: MyApp.borderColor),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by name, email or phone...',
                        prefixIcon: Icon(Icons.search, color: MyApp.textSecondaryColor),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showAddTeacherDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyApp.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Teacher', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Filters + Sort ───────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status filter chips
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Filter by Status:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13, color: MyApp.textSecondaryColor)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 44,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          itemBuilder: (context, index) {
                            final filter = _filters[index];
                            final isSelected = _selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                selected: isSelected,
                                label: Text(filter),
                                onSelected: (_) =>
                                    setState(() => _selectedFilter = filter),
                                backgroundColor: Colors.white,
                                selectedColor:
                                    MyApp.primaryColor.withOpacity(0.1),
                                checkmarkColor: MyApp.primaryColor,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? MyApp.primaryColor
                                      : MyApp.textPrimaryColor,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected
                                        ? MyApp.primaryColor
                                        : MyApp.borderColor,
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
                const SizedBox(width: 16),

                // Subject filter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Filter by Subject:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13, color: MyApp.textSecondaryColor)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: MyApp.borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSubject,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            icon: Icon(Icons.keyboard_arrow_down, color: MyApp.textSecondaryColor),
                            style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 14),
                            items: _subjects
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedSubject = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Sort dropdown + direction toggle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sort by:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13, color: MyApp.textSecondaryColor)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: MyApp.borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _sortField,
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  icon: Icon(Icons.keyboard_arrow_down, color: MyApp.textSecondaryColor),
                                  style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 14),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'student_name',
                                        child: Text('Name')),
                                    DropdownMenuItem(
                                        value: 'class', child: Text('Subject')),
                                    DropdownMenuItem(
                                        value: 'status', child: Text('Status')),
                                  ],
                                  onChanged: (v) => _onSort(v!),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip:
                                _sortAscending ? 'Ascending' : 'Descending',
                            icon: Icon(
                              _sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: MyApp.primaryColor,
                            ),
                            onPressed: () => setState(
                                () => _sortAscending = !_sortAscending),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Table ─────────────────────────────────────────────
            Expanded(
              child: Container(
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
                  children: [
                    // Header row
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                              flex: 2,
                              child: Text('Name',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: MyApp.textSecondaryColor))),
                          Expanded(
                              child: Text('Contact',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: MyApp.textSecondaryColor))),
                          Expanded(
                              child: Text('Subject',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: MyApp.textSecondaryColor))),
                          Expanded(
                              child: Text('Status',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: MyApp.textSecondaryColor))),
                          const SizedBox(width: 100),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: MyApp.borderColor),

                    // Body via StreamBuilder
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _teachersStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }

                          final teachers = _applyFilters(snapshot.data ?? []);

                          if (teachers.isEmpty) {
                            return Center(
                              child: Text('No Teachers found',
                                  style: TextStyle(
                                      color: MyApp.textSecondaryColor, fontSize: 16)),
                            );
                          }

                          return ListView.separated(
                            itemCount: teachers.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: MyApp.borderColor),
                            itemBuilder: (context, index) {
                              final teacher = teachers[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 16),
                                    // Name + Email
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: MyApp.primaryColor.withOpacity(0.1),
                                            child: Text(
                                              (teacher['student_name'] ??
                                                      'T')
                                                  .toString()
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                  color: MyApp.primaryColor,
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
                                                teacher['student_name'] ??
                                                    '',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: MyApp.textPrimaryColor),
                                              ),
                                              Text(
                                                teacher['email'] ?? '',
                                                style: TextStyle(
                                                    color: MyApp.textSecondaryColor,
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                        child: Text(teacher['contact'] ?? '',
                                            style: TextStyle(color: MyApp.textPrimaryColor))),
                                    Expanded(
                                        child: Text(teacher['class'] ?? '',
                                            style: TextStyle(color: MyApp.textPrimaryColor))),
                                    // Status badge
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: teacher['status'] ==
                                                    'Active'
                                                ? MyApp.successColor
                                                    .withOpacity(0.1)
                                                : MyApp.errorColor.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            teacher['status'] ?? '',
                                            style: TextStyle(
                                              color: teacher['status'] ==
                                                      'Active'
                                                  ? MyApp.successColor
                                                  : MyApp.errorColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Edit / Delete
                                    SizedBox(
                                      width: 100,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit_outlined,
                                                color: MyApp.primaryColor),
                                            onPressed: () =>
                                                _showEditTeacherDialog(
                                                    teacher),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline,
                                                color: MyApp.errorColor),
                                            onPressed: () =>
                                                _showDeleteDialog(teacher),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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

  // ── Add Teacher Dialog ───────────────────────────────────────
  void _showAddTeacherDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: _generatePassword());
    String selectedSubject = 'Mathematics';
    String selectedStatus = 'Active';
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: MyApp.borderColor),
          ),
          title: const Text('Add New Teacher', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: MyApp.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(errorMessage!,
                          style: TextStyle(color: MyApp.errorColor)),
                    ),
                  _buildField(nameCtrl, 'Full Name', Icons.person),
                  const SizedBox(height: 16),
                  _buildField(emailCtrl, 'Email', Icons.email,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildField(phoneCtrl, 'Phone Number', Icons.phone,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passCtrl,
                    style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Password (auto-generated)',
                      labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 14),
                      prefixIcon: Icon(Icons.lock, color: MyApp.textSecondaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.primaryColor, width: 2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.borderColor),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.refresh, color: MyApp.textSecondaryColor),
                        tooltip: 'Regenerate password',
                        onPressed: () => setDialogState(
                            () => passCtrl.text = _generatePassword()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 14),
                      prefixIcon: Icon(Icons.book, color: MyApp.textSecondaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.primaryColor, width: 2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.borderColor),
                      ),
                    ),
                    value: selectedSubject,
                    dropdownColor: Colors.white,
                    style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 14),
                    items: _subjects
                        .where((s) => s != 'All Subjects')
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => selectedSubject = v!,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Status',
                      labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 14),
                      prefixIcon: Icon(Icons.toggle_on, color: MyApp.textSecondaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.primaryColor, width: 2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.borderColor),
                      ),
                    ),
                    value: selectedStatus,
                    dropdownColor: Colors.white,
                    style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 14),
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(
                          value: 'Inactive', child: Text('Inactive')),
                    ],
                    onChanged: (v) => selectedStatus = v!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: MyApp.textSecondaryColor)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty ||
                          emailCtrl.text.trim().isEmpty ||
                          phoneCtrl.text.trim().isEmpty) {
                        setDialogState(
                            () => errorMessage = 'Please fill all fields.');
                        return;
                      }
                      setDialogState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      try {
                        await _addTeacher(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          subject: selectedSubject,
                          status: selectedStatus,
                          password: 'lms@teacher.com',
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          _showSnackbar(
                              'Teacher registered! Password: lms@teacher.com',
                              MyApp.successColor);
                        }
                      } catch (e) {
                        setDialogState(() {
                          isLoading = false;
                          errorMessage =
                              e.toString().replaceAll('Exception: ', '');
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyApp.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Register Teacher'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit Teacher Dialog ──────────────────────────────────────
  void _showEditTeacherDialog(Map<String, dynamic> teacher) {
    final nameCtrl = TextEditingController(text: teacher['student_name'] ?? '');
    final phoneCtrl = TextEditingController(text: teacher['contact'] ?? '');
    final passCtrl = TextEditingController(text: teacher['password'] ?? '');
    String selectedSubject =
        _subjects.contains(teacher['class']) ? teacher['class'] : 'Mathematics';
    String selectedStatus =
        teacher['status'] == 'Inactive' ? 'Inactive' : 'Active';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: MyApp.borderColor),
          ),
          title: const Text('Edit Teacher', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  _buildField(nameCtrl, 'Full Name', Icons.person),
                  const SizedBox(height: 16),
                  // Email read-only — changing email needs Admin SDK
                  TextField(
                    readOnly: true,
                    controller:
                        TextEditingController(text: teacher['email'] ?? ''),
                    style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Email (read-only)',
                      labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 14),
                      prefixIcon: Icon(Icons.email, color: MyApp.textSecondaryColor),
                      filled: true,
                      fillColor: MyApp.backgroundColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.primaryColor, width: 2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField(phoneCtrl, 'Phone Number', Icons.phone,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildField(passCtrl, 'Password', Icons.lock),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 14),
                      prefixIcon: Icon(Icons.book, color: MyApp.textSecondaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.primaryColor, width: 2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.borderColor),
                      ),
                    ),
                    value: selectedSubject,
                    dropdownColor: Colors.white,
                    style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 14),
                    items: _subjects
                        .where((s) => s != 'All Subjects')
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => selectedSubject = v!,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Status',
                      labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 14),
                      prefixIcon: Icon(Icons.toggle_on, color: MyApp.textSecondaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.primaryColor, width: 2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: MyApp.borderColor),
                      ),
                    ),
                    value: selectedStatus,
                    dropdownColor: Colors.white,
                    style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 14),
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(
                          value: 'Inactive', child: Text('Inactive')),
                    ],
                    onChanged: (v) => selectedStatus = v!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: MyApp.textSecondaryColor)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      try {
                        await _updateTeacher(teacher['docId'], {
                          'student_name': nameCtrl.text.trim(),
                          'contact': phoneCtrl.text.trim(),
                          'class': selectedSubject,
                          'status': selectedStatus,
                          'password': passCtrl.text.trim(),
                        });
                        if (mounted) {
                          Navigator.pop(context);
                          _showSnackbar(
                              'Teacher updated successfully', MyApp.successColor);
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        _showSnackbar('Update failed: $e', MyApp.errorColor);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyApp.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Update Teacher'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete Dialog ────────────────────────────────────────────
  void _showDeleteDialog(Map<String, dynamic> teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: MyApp.borderColor),
        ),
        title: const Text('Delete Teacher', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete ${teacher['student_name']}?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: MyApp.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteTeacher(teacher['docId']);
              if (mounted) {
                Navigator.pop(context);
                _showSnackbar('Teacher deleted successfully', MyApp.errorColor);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyApp.errorColor,
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

  // ── Helpers ──────────────────────────────────────────────────
  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 14),
        prefixIcon: Icon(icon, color: MyApp.textSecondaryColor),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyApp.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyApp.primaryColor, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyApp.borderColor),
        ),
      ),
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}
