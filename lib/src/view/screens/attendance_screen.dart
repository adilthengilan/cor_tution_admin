import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FIRESTORE STRUCTURE
// ─────────────────────────────────────────────────────────────────────────────
//
//  users/
//    {studentAuthUID}/                     ← student document (id = auth uid)
//      student_name : String
//      class        : String
//      division     : String
//      rollNo       : String
//      role         : "student"
//      status       : "Active"
//
//      attendance/                         ← SUB-COLLECTION (student reads this)
//        {yyyy-MM-dd}/                     ← one document per calendar date
//          date        : String            "2025-07-10"
//          class       : String
//          division    : String
//          teacherName : String
//          teacherUid  : String
//          savedAt     : Timestamp
//          1hr         : "present" | "absent" | "late"
//          2hr         : "present" | "absent" | "late"
//          3hr         : "present" | "absent" | "late"
//          4hr         : "present" | "absent" | "late"
//          5hr         : "present" | "absent" | "late"
//          6hr         : "present" | "absent" | "late"
//
//  attendance_completion/                  ← top-level completion tracker
//    {yyyy-MM-dd}/                         ← date document
//      "10th_M1_1hr" : true               ← slot completed flag
//      "10th_M1_2hr" : true
//
// ─────────────────────────────────────────────────────────────────────────────
//  READ PATHS
//  • Student app  → users/{theirUID}/attendance/{date}
//  • Teacher app  → queries users/ by class+division, then reads each
//                   student's attendance subcollection for history
//  • Completion   → attendance_completion/{date} for tracker circles
// ─────────────────────────────────────────────────────────────────────────────

// ═════════════════════════════════════════════════════════════════════════════
//  AttendanceScreen  (Teacher side)
// ═════════════════════════════════════════════════════════════════════════════
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with TickerProviderStateMixin {
  // ── Palette ──────────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF4F46E5);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color lightGray = Color(0xFFF8FAFC);
  static const Color mediumGray = Color(0xFF64748B);
  static const Color darkGray = Color(0xFF1E293B);

  // ── HR config ────────────────────────────────────────────────────
  static const List<String> _hrKeys = [
    '1hr',
    '2hr',
    '3hr',
    '4hr',
    '5hr',
    '6hr'
  ];
  static const List<String> _hrLabels = [
    '1st Hr',
    '2nd Hr',
    '3rd Hr',
    '4th Hr',
    '5th Hr',
    '6th Hr'
  ];

  // ── Filter state ─────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  String _selClass = 'All Classes';
  String _selDiv = 'All Divisions';
  String _selHr = '1hr';
  DateTime _selDate = DateTime.now();

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
    'S3',
  ];

  // ── Data ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;

  /// studentUID → status already saved in Firestore for _selHr on _selDate
  Map<String, String> _savedStatus = {};

  /// studentUID → status marked locally, not yet saved
  Map<String, String> _pending = {};

  /// "class_div_hr" → completed flag
  Map<String, bool> _completion = {};

  String _teacherName = '';
  String _teacherUid = '';

  late AnimationController _animCtrl;

  // ── Init ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _initTeacher().then((_) {
      _loadStudents();
      _loadCompletionMap();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  //  DATA METHODS
  // ─────────────────────────────────────────────────────────────────

  Future<void> _initTeacher() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _teacherUid = user.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) _teacherName = doc.data()?['name'] ?? '';
  }

  /// Load all active students from users/ where role == "student"
  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('status', isEqualTo: 'Active')
          .get();

      _students = snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['uid'] = d.id; // auth uid == doc id
        return data;
      }).toList();

      setState(() => _loading = false);
      await _loadSavedStatuses();
    } catch (e) {
      debugPrint('loadStudents: $e');
      setState(() => _loading = false);
    }
  }

  /// For the selected class+division+hr+date, read the hr field from
  /// each matching student's attendance doc.
  ///
  /// Path: users/{uid}/attendance/{dateKey}  field: _selHr
  Future<void> _loadSavedStatuses() async {
    if (_selClass == 'All Classes' || _selDiv == 'All Divisions') {
      setState(() {
        _savedStatus = {};
        _pending = {};
      });
      return;
    }

    final dateKey = _dateKey;
    final hrKey = _selHr;
    final relevant = _students
        .where((s) => s['class'] == _selClass && s['division'] == _selDiv)
        .toList();

    // Parallel fetch — one Firestore read per student in this class+div
    final results = await Future.wait(relevant.map((s) async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(s['uid'] as String)
            .collection('attendance')
            .doc(dateKey)
            .get();
        if (doc.exists) {
          final st = doc.data()?[hrKey];
          if (st != null && (st as String).isNotEmpty) {
            return MapEntry(s['uid'] as String, st);
          }
        }
      } catch (_) {}
      return null;
    }));

    final map = <String, String>{};
    for (final e in results) {
      if (e != null) map[e.key] = e.value;
    }

    setState(() {
      _savedStatus = map;
      _pending = {}; // clear stale pending when switching slot
    });
  }

  /// Load which class+div+hr slots are already completed today
  Future<void> _loadCompletionMap() async {
    final doc = await FirebaseFirestore.instance
        .collection('attendance_completion')
        .doc(_dateKey)
        .get();

    if (doc.exists) {
      final map = <String, bool>{};
      (doc.data() ?? {}).forEach((k, v) => map[k] = v == true);
      setState(() => _completion = map);
    } else {
      setState(() => _completion = {});
    }
  }

  Future<void> _markSlotCompleted() async {
    final key = _slotKey(_selClass, _selDiv, _selHr);
    await FirebaseFirestore.instance
        .collection('attendance_completion')
        .doc(_dateKey)
        .set({key: true}, SetOptions(merge: true));
    setState(() => _completion[key] = true);
  }

  // ─────────────────────────────────────────────────────────────────
  //  SAVE
  //  Writes into each student's own attendance subcollection using
  //  merge so that different teachers can fill different hr fields on
  //  the same date document without overwriting each other.
  //
  //  users/{studentUID}/attendance/{dateKey}
  //    → { _selHr: status, date, class, division, teacherName,
  //        teacherUid, savedAt }   (merged)
  // ─────────────────────────────────────────────────────────────────
  Future<void> _saveAttendance() async {
    if (_pending.isEmpty) return;

    if (_selClass == 'All Classes' || _selDiv == 'All Divisions') {
      _showSnack('Select a specific class & division first.', dangerRed);
      return;
    }

    _showLoading();

    final batch = FirebaseFirestore.instance.batch();
    final dateKey = _dateKey;

    for (final entry in _pending.entries) {
      final uid = entry.key;
      final status = entry.value;

      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('attendance')
          .doc(dateKey);

      // SetOptions(merge: true) keeps other hr fields already on this doc
      batch.set(
          ref,
          {
            _selHr: status,
            'date': dateKey,
            'class': _selClass,
            'division': _selDiv,
            'teacherName': _teacherName,
            'teacherUid': _teacherUid,
            'savedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    }

    try {
      await batch.commit();
      await _markSlotCompleted();

      final saved = _pending.length;
      setState(() {
        _savedStatus.addAll(_pending);
        _pending = {};
      });

      if (mounted) Navigator.pop(context);
      _showSnack(
          'Saved $saved records for ${_selHr.toUpperCase()} ✓', successGreen);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnack('Error: $e', dangerRed);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────────

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selDate);

  String _slotKey(String cls, String div, String hr) => '${cls}_${div}_$hr';

  bool _isCompleted(String cls, String div, String hr) =>
      _completion[_slotKey(cls, div, hr)] ?? false;

  /// Returns pending status first, falls back to already-saved status
  String? _statusOf(String uid) => _pending[uid] ?? _savedStatus[uid];

  void _markStudent(String uid, String status) {
    setState(() => _pending[uid] = status);
    _animCtrl.forward().then((_) => _animCtrl.reverse());
  }

  void _markAll(String status) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(_statusIcon(status), color: _statusColor(status)),
          const SizedBox(width: 10),
          Text('Mark All ${_cap(status)}',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'Mark all ${_filtered.length} students as ${_cap(status)} for ${_selHr.toUpperCase()}?',
          style: GoogleFonts.nunito(fontSize: 15),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _statusColor(status),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                for (final s in _filtered) {
                  _pending[s['uid'] as String] = status;
                }
              });
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _students.where((s) {
      final q = _searchCtrl.text.toLowerCase();
      final matchSearch =
          (s['student_name'] ?? '').toString().toLowerCase().contains(q) ||
              (s['rollNo'] ?? '').toString().toLowerCase().contains(q);
      final matchClass = _selClass == 'All Classes' || s['class'] == _selClass;
      final matchDiv = _selDiv == 'All Divisions' || s['division'] == _selDiv;
      return matchSearch && matchClass && matchDiv;
    }).toList();

    if (_selClass != 'All Classes' && _selDiv != 'All Divisions') {
      list.sort((a, b) {
        final iA = int.tryParse(a['rollNo']?.toString() ?? '');
        final iB = int.tryParse(b['rollNo']?.toString() ?? '');
        if (iA != null && iB != null) return iA.compareTo(iB);
        return (a['rollNo']?.toString() ?? '')
            .compareTo(b['rollNo']?.toString() ?? '');
      });
    }
    return list;
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'present':
        return successGreen;
      case 'absent':
        return dangerRed;
      case 'late':
        return warningAmber;
      default:
        return mediumGray;
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'present':
        return Icons.check_circle_rounded;
      case 'absent':
        return Icons.cancel_rounded;
      case 'late':
        return Icons.schedule_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _showLoading() => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.nunito(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHrSelector(),
                        const SizedBox(height: 20),
                        _buildCompletionTracker(),
                        const SizedBox(height: 20),
                        _buildSearchAndFilters(),
                        const SizedBox(height: 16),
                        _buildQuickActions(),
                        const SizedBox(height: 20),
                        _buildListHeader(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                _buildStudentList(),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
      floatingActionButton: _pending.isNotEmpty ? _buildSaveButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── App bar ───────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 120,
      pinned: true,
      backgroundColor: primaryBlue,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Attendance',
            style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryBlue, Color(0xFF6366F1)],
            ),
          ),
        ),
      ),
      actions: [
        _appBarBtn(Icons.refresh_rounded, _loadStudents, 'Refresh'),
        _appBarBtn(
            Icons.history_rounded,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AttendanceHistoryScreen())),
            'History'),
        // Date picker button
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(DateFormat('dd MMM').format(_selDate),
                    style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _appBarBtn(IconData icon, VoidCallback fn, String tip) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
          icon: Icon(icon, color: Colors.white), onPressed: fn, tooltip: tip),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryBlue)),
        child: child!,
      ),
    );
    if (picked != null && picked != _selDate) {
      setState(() => _selDate = picked);
      await Future.wait([_loadCompletionMap(), _loadSavedStatuses()]);
    }
  }

  // ── HR selector tabs ──────────────────────────────────────────────
  Widget _buildHrSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Hour',
            style: GoogleFonts.nunito(
                fontSize: 13, fontWeight: FontWeight.w700, color: mediumGray)),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _hrKeys.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final key = _hrKeys[i];
              final label = _hrLabels[i];
              final selected = _selHr == key;
              final done = _selClass != 'All Classes' &&
                  _selDiv != 'All Divisions' &&
                  _isCompleted(_selClass, _selDiv, key);

              return GestureDetector(
                onTap: () async {
                  setState(() => _selHr = key);
                  await _loadSavedStatuses();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? primaryBlue
                        : done
                            ? successGreen.withOpacity(0.1)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected
                          ? primaryBlue
                          : done
                              ? successGreen
                              : Colors.grey.shade200,
                      width: 1.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                                color: primaryBlue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ]
                        : [],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (done && !selected)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(Icons.check_circle_rounded,
                            size: 13, color: successGreen),
                      ),
                    Text(label,
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : done
                                    ? successGreen
                                    : darkGray)),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Completion tracker (class-division circles) ───────────────────
  Widget _buildCompletionTracker() {
    final Set<String> combos = {};
    for (final s in _students) {
      final c = s['class']?.toString() ?? '';
      final d = s['division']?.toString() ?? '';
      if (c.isNotEmpty && d.isNotEmpty) combos.add('$c||$d');
    }
    if (combos.isEmpty) return const SizedBox();

    final sorted = combos.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Class Status — ',
              style: GoogleFonts.nunito(
                  fontSize: 14, fontWeight: FontWeight.w800, color: darkGray)),
          Text(_hrLabels[_hrKeys.indexOf(_selHr)],
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue)),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final parts = sorted[i].split('||');
              final cls = parts[0];
              final div = parts[1];
              final done = _isCompleted(cls, div, _selHr);
              final selected = _selClass == cls && _selDiv == div;

              return GestureDetector(
                onTap: () async {
                  setState(() {
                    _selClass = cls;
                    _selDiv = div;
                  });
                  await _loadSavedStatuses();
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? successGreen
                            : selected
                                ? primaryBlue.withOpacity(0.1)
                                : Colors.white,
                        border: Border.all(
                          color: done
                              ? successGreen
                              : selected
                                  ? primaryBlue
                                  : Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: done
                                ? successGreen.withOpacity(0.35)
                                : Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: done
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 24)
                          : Center(
                              child: Text(div,
                                  style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          selected ? primaryBlue : mediumGray)),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(cls,
                        style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: done
                                ? successGreen
                                : selected
                                    ? primaryBlue
                                    : mediumGray)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Search + filters ──────────────────────────────────────────────
  Widget _buildSearchAndFilters() {
    return Column(children: [
      Container(
        decoration: _cardDeco(),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.nunito(),
          decoration: InputDecoration(
            hintText: 'Search by name or roll no...',
            hintStyle: GoogleFonts.nunito(color: mediumGray),
            prefixIcon: const Icon(Icons.search_rounded, color: mediumGray),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: _dropdown(_selDiv, _divisions, (v) async {
          setState(() => _selDiv = v!);
          await _loadSavedStatuses();
        })),
        const SizedBox(width: 10),
        Expanded(
            child: _dropdown(_selClass, _classes, (v) async {
          setState(() => _selClass = v!);
          await _loadSavedStatuses();
        })),
      ]),
    ]);
  }

  Widget _dropdown(
      String value, List<String> items, Function(String?) onChange) {
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: GoogleFonts.nunito(fontSize: 13, color: darkGray),
          icon: const Icon(Icons.arrow_drop_down_rounded),
          items: items
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: GoogleFonts.nunito(fontSize: 13))))
              .toList(),
          onChanged: onChange,
        ),
      ),
    );
  }

  // ── Quick actions ─────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Row(children: [
      Expanded(
          child: _quickBtn('All Present', Icons.check_circle_rounded,
              successGreen, () => _markAll('present'))),
      const SizedBox(width: 10),
      Expanded(
          child: _quickBtn('All Absent', Icons.cancel_rounded, dangerRed,
              () => _markAll('absent'))),
      const SizedBox(width: 10),
      Expanded(
          child: _quickBtn('All Late', Icons.schedule_rounded, warningAmber,
              () => _markAll('late'))),
    ]);
  }

  Widget _quickBtn(String label, IconData icon, Color color, VoidCallback fn) {
    return ElevatedButton.icon(
      onPressed: fn,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      icon: Icon(icon, size: 15),
      label: Text(label,
          style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  // ── List header ───────────────────────────────────────────────────
  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Students (${_filtered.length})',
            style: GoogleFonts.nunito(
                fontSize: 17, fontWeight: FontWeight.w800, color: darkGray)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(DateFormat('MMM d, yyyy').format(_selDate),
              style: GoogleFonts.nunito(
                  color: primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ),
      ],
    );
  }

  // ── Student list ──────────────────────────────────────────────────
  Widget _buildStudentList() {
    final students = _filtered;

    if (students.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined,
                  size: 64, color: mediumGray.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text(
                _selClass == 'All Classes' || _selDiv == 'All Divisions'
                    ? 'Select a class and division\nto mark attendance'
                    : 'No students found',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 15, color: mediumGray),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _studentCard(students[i]),
          childCount: students.length,
        ),
      ),
    );
  }

  Widget _studentCard(Map<String, dynamic> student) {
    final uid = student['uid'] as String;
    final status = _statusOf(uid);
    final name = (student['student_name'] as String? ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
        border: status != null
            ? Border.all(
                color: _statusColor(status).withOpacity(0.35), width: 1.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          // Info row
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: primaryBlue.withOpacity(0.12),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: primaryBlue,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: darkGray)),
                    const SizedBox(height: 3),
                    Row(children: [
                      _chip(student['class'] ?? '',
                          primaryBlue.withOpacity(0.12), primaryBlue),
                      const SizedBox(width: 6),
                      _chip(student['division'] ?? '',
                          Colors.purple.withOpacity(0.12), Colors.purple),
                      const SizedBox(width: 6),
                      Text('Roll: ${student['rollNo'] ?? 'N/A'}',
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: mediumGray)),
                    ]),
                  ]),
            ),
            if (status != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_cap(status),
                    style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
          ]),
          const SizedBox(height: 12),
          // Attendance buttons
          Row(children: [
            Expanded(
                child: _attendBtn(uid, 'present', 'Present', successGreen,
                    Icons.check_circle_rounded, status)),
            const SizedBox(width: 8),
            Expanded(
                child: _attendBtn(uid, 'absent', 'Absent', dangerRed,
                    Icons.cancel_rounded, status)),
            const SizedBox(width: 8),
            Expanded(
                child: _attendBtn(uid, 'late', 'Late', warningAmber,
                    Icons.schedule_rounded, status)),
          ]),
        ]),
      ),
    );
  }

  Widget _attendBtn(String uid, String value, String label, Color color,
      IconData icon, String? current) {
    final sel = current?.toLowerCase() == value;
    return ElevatedButton.icon(
      onPressed: () => _markStudent(uid, value),
      style: ElevatedButton.styleFrom(
        backgroundColor: sel ? color : Colors.grey.shade100,
        foregroundColor: sel ? Colors.white : mediumGray,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      icon: Icon(icon, size: 14),
      label: Text(label,
          style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: sel ? FontWeight.w800 : FontWeight.w600)),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: MediaQuery.of(context).size.width - 40,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: FloatingActionButton.extended(
        onPressed: _saveAttendance,
        backgroundColor: primaryBlue,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        label: Text(
          'Save ${_selHr.toUpperCase()} Attendance (${_pending.length})',
          style: GoogleFonts.nunito(
              fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        icon: const Icon(Icons.save_rounded, color: Colors.white),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: GoogleFonts.nunito(
              fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      );
}

// ═════════════════════════════════════════════════════════════════════════════
//  AttendanceHistoryScreen  (Teacher side)
//  Reads from each student's attendance subcollection
// ═════════════════════════════════════════════════════════════════════════════
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  static const Color primaryBlue = Color(0xFF4F46E5);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color lightGray = Color(0xFFF8FAFC);
  static const Color mediumGray = Color(0xFF64748B);
  static const Color darkGray = Color(0xFF1E293B);

  static const List<String> _hrKeys = [
    '1hr',
    '2hr',
    '3hr',
    '4hr',
    '5hr',
    '6hr'
  ];

  DateTime _selMonth = DateTime.now();
  String _selClass = 'All Classes';
  String _selDiv = 'All Divisions';
  String _selHr = 'All Hours';

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
    'S3',
  ];
  final List<String> _hrOptions = [
    'All Hours',
    '1hr',
    '2hr',
    '3hr',
    '4hr',
    '5hr',
    '6hr'
  ];

  /// Flattened: one entry per student per date per hr
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  /// Query students by class+div, then fetch each student's attendance
  /// subcollection for the selected month. Flatten hr fields into rows.
  Future<void> _fetchHistory() async {
    setState(() => _loading = true);
    try {
      Query q = FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('status', isEqualTo: 'Active');
      if (_selClass != 'All Classes')
        q = q.where('class', isEqualTo: _selClass);
      if (_selDiv != 'All Divisions')
        q = q.where('division', isEqualTo: _selDiv);

      final studentSnap = await q.get();
      if (studentSnap.docs.isEmpty) {
        setState(() {
          _records = [];
          _loading = false;
        });
        return;
      }

      final start = DateTime(_selMonth.year, _selMonth.month, 1);
      final end = DateTime(_selMonth.year, _selMonth.month + 1, 0);
      final startKey = DateFormat('yyyy-MM-dd').format(start);
      final endKey = DateFormat('yyyy-MM-dd').format(end);

      final allRecords = <Map<String, dynamic>>[];

      // Parallel: fetch each student's attendance docs for the month
      await Future.wait(studentSnap.docs.map((sDoc) async {
        final sData = sDoc.data() as Map<String, dynamic>;
        final sName = sData['student_name'] ?? '';
        final sCls = sData['class'] ?? '';
        final sDiv = sData['division'] ?? '';
        final sRoll = sData['rollNo'] ?? '';

        final attSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(sDoc.id)
            .collection('attendance')
            .where('date', isGreaterThanOrEqualTo: startKey)
            .where('date', isLessThanOrEqualTo: endKey)
            .orderBy('date', descending: true)
            .get();

        for (final attDoc in attSnap.docs) {
          final attData = attDoc.data();
          final date = attData['date'] as String? ?? '';
          final tName = attData['teacherName'] as String? ?? '';

          // One row per hr field that has a value
          for (final hr in _hrKeys) {
            final status = attData[hr] as String?;
            if (status != null && status.isNotEmpty) {
              allRecords.add({
                'studentName': sName,
                'studentUid': sDoc.id,
                'class': sCls,
                'division': sDiv,
                'rollNo': sRoll,
                'date': date,
                'hr': hr,
                'status': status,
                'teacherName': tName,
              });
            }
          }
        }
      }));

      // Sort: date desc → rollNo asc
      allRecords.sort((a, b) {
        final dCmp = (b['date'] as String).compareTo(a['date'] as String);
        if (dCmp != 0) return dCmp;
        final iA = int.tryParse(a['rollNo'] ?? '');
        final iB = int.tryParse(b['rollNo'] ?? '');
        if (iA != null && iB != null) return iA.compareTo(iB);
        return 0;
      });

      setState(() {
        _records = allRecords;
        _loading = false;
      });
    } catch (e) {
      debugPrint('fetchHistory: $e');
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered => _records
      .where((r) => _selHr == 'All Hours' || r['hr'] == _selHr)
      .toList();

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final r in _filtered) {
      map.putIfAbsent(r['date'] as String, () => []).add(r);
    }
    return map;
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'present':
        return successGreen;
      case 'absent':
        return dangerRed;
      case 'late':
        return warningAmber;
      default:
        return mediumGray;
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'present':
        return Icons.check_circle_rounded;
      case 'absent':
        return Icons.cancel_rounded;
      case 'late':
        return Icons.schedule_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: lightGray,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            backgroundColor: primaryBlue,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Attendance History',
                  style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryBlue, Color(0xFF6366F1)],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthSelector(),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                        child: _dropdown(_selClass, _classes, (v) {
                      setState(() => _selClass = v!);
                      _fetchHistory();
                    })),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _dropdown(_selDiv, _divisions, (v) {
                      setState(() => _selDiv = v!);
                      _fetchHistory();
                    })),
                  ]),
                  const SizedBox(height: 10),
                  _dropdown(
                      _selHr, _hrOptions, (v) => setState(() => _selHr = v!)),
                  const SizedBox(height: 16),
                  _buildSummary(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Records',
                          style: GoogleFonts.nunito(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: darkGray)),
                      Text('${sortedDates.length} days',
                          style: GoogleFonts.nunito(
                              color: mediumGray, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (sortedDates.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded,
                        size: 64, color: mediumGray.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text('No records found',
                        style: GoogleFonts.nunito(
                            fontSize: 17, color: mediumGray)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _dayCard(
                      DateTime.parse(sortedDates[i]), grouped[sortedDates[i]]!),
                  childCount: sortedDates.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        IconButton(
          onPressed: () {
            setState(() =>
                _selMonth = DateTime(_selMonth.year, _selMonth.month - 1));
            _fetchHistory();
          },
          icon: const Icon(Icons.chevron_left_rounded),
          style: IconButton.styleFrom(
              backgroundColor: primaryBlue.withOpacity(0.1),
              foregroundColor: primaryBlue),
        ),
        Expanded(
          child: Center(
            child: Text(DateFormat('MMMM yyyy').format(_selMonth),
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: darkGray)),
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() =>
                _selMonth = DateTime(_selMonth.year, _selMonth.month + 1));
            _fetchHistory();
          },
          icon: const Icon(Icons.chevron_right_rounded),
          style: IconButton.styleFrom(
              backgroundColor: primaryBlue.withOpacity(0.1),
              foregroundColor: primaryBlue),
        ),
      ]),
    );
  }

  Widget _dropdown(
      String value, List<String> items, Function(String?) onChange) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: GoogleFonts.nunito(fontSize: 13, color: darkGray),
          items: items
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: GoogleFonts.nunito(fontSize: 13))))
              .toList(),
          onChanged: (v) {
            onChange(v);
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildSummary() {
    int present = 0, absent = 0, late = 0;
    for (final r in _filtered) {
      switch ((r['status'] as String).toLowerCase()) {
        case 'present':
          present++;
          break;
        case 'absent':
          absent++;
          break;
        case 'late':
          late++;
          break;
      }
    }
    final total = _filtered.length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        Expanded(
            child: _stat('Present', present, total, successGreen,
                Icons.check_circle_rounded)),
        Expanded(
            child: _stat(
                'Absent', absent, total, dangerRed, Icons.cancel_rounded)),
        Expanded(
            child: _stat(
                'Late', late, total, warningAmber, Icons.schedule_rounded)),
      ]),
    );
  }

  Widget _stat(String label, int count, int total, Color color, IconData icon) {
    final pct =
        total > 0 ? '${(count / total * 100).toStringAsFixed(0)}%' : '0%';
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(height: 6),
      Text('$count',
          style: GoogleFonts.nunito(
              fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      Text(label,
          style: GoogleFonts.nunito(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      Text(pct,
          style: GoogleFonts.nunito(
              fontSize: 10,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _dayCard(DateTime date, List<Map<String, dynamic>> recs) {
    int p = 0, a = 0, l = 0;
    for (final r in recs) {
      switch ((r['status'] as String).toLowerCase()) {
        case 'present':
          p++;
          break;
        case 'absent':
          a++;
          break;
        case 'late':
          l++;
          break;
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetail(date, recs),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(DateFormat('d').format(date),
                        style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: primaryBlue)),
                    Text(DateFormat('MMM').format(date),
                        style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: primaryBlue)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE').format(date),
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: darkGray)),
                    const SizedBox(height: 6),
                    Row(children: [
                      _chip(
                          '$p P', successGreen.withOpacity(0.15), successGreen),
                      const SizedBox(width: 6),
                      _chip('$a A', dangerRed.withOpacity(0.15), dangerRed),
                      const SizedBox(width: 6),
                      _chip(
                          '$l L', warningAmber.withOpacity(0.15), warningAmber),
                    ]),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: mediumGray),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: GoogleFonts.nunito(
              fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  void _showDetail(DateTime date, List<Map<String, dynamic>> recs) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(DateFormat('EEEE, MMM d yyyy').format(date),
                      style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: darkGray)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                ),
              ]),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: recs.length,
                  itemBuilder: (_, i) {
                    final r = recs[i];
                    final status = r['status'] as String;
                    return ListTile(
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_statusIcon(status),
                            color: _statusColor(status), size: 16),
                      ),
                      title: Text(r['studentName'] ?? '',
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: Text(
                        '${r['hr']} • ${r['class']}-${r['division']} • Roll ${r['rollNo']}',
                        style:
                            GoogleFonts.nunito(fontSize: 11, color: mediumGray),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_cap(status),
                            style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Close',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
