// ============================================================
//  fees_screen.dart  —  Full Firebase Integration
//  Firestore path : users/{uid}/fees/feeDetails
//
//  pubspec.yaml — ensure sdk is 3.0+ to use records & super-params:
//    environment:
//      sdk: ">=3.0.0 <4.0.0"
//
//  dependencies:
//    cloud_firestore: ^4.x
//    firebase_core: ^2.x
//    file_picker: ^6.x
//    excel: ^4.x        (provides TextCellValue in v4+)
//    intl: ^0.18.x
// ============================================================

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
// FIX: Import excel with a prefix so its 'Border' doesn't clash with
//      Flutter's painting 'Border'.
import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────
class FeeRecord {
  final String admissionNumber;
  final String studentName;
  final String studentClass;
  final String division;
  final double feesPaid;
  final double totalFees;
  final String uid;
  final String feeDocId;
  final DateTime? uploadedAt;

  const FeeRecord({
    required this.admissionNumber,
    required this.studentName,
    required this.studentClass,
    required this.division,
    required this.feesPaid,
    required this.totalFees,
    required this.uid,
    required this.feeDocId,
    this.uploadedAt,
  });

  double get pendingAmount => (totalFees - feesPaid).clamp(0, double.infinity);
  bool get isFullyPaid => pendingAmount == 0 && totalFees > 0;
  bool get isPartial => feesPaid > 0 && !isFullyPaid;
  bool get isDue => feesPaid == 0;

  String get statusLabel {
    if (isFullyPaid) return 'Paid';
    if (isPartial) return 'Partial';
    return 'Due';
  }

  Color get statusColor {
    if (isFullyPaid) return const Color(0xFF16A34A);
    if (isPartial) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  factory FeeRecord.fromFirestore(
      Map<String, dynamic> d, String uid, String docId) {
    return FeeRecord(
      admissionNumber: d['admissionNumber']?.toString() ?? '',
      studentName: d['studentName']?.toString() ?? '',
      studentClass: d['class']?.toString() ?? '',
      division: d['division']?.toString() ?? '',
      feesPaid: (d['feesPaid'] ?? 0).toDouble(),
      totalFees: (d['totalFees'] ?? 0).toDouble(),
      uid: uid,
      feeDocId: docId,
      uploadedAt: (d['uploadedAt'] as Timestamp?)?.toDate(),
    );
  }

  FeeRecord copyWith({
    double? feesPaid,
    double? totalFees,
    String? studentClass,
    String? division,
  }) {
    return FeeRecord(
      admissionNumber: admissionNumber,
      studentName: studentName,
      studentClass: studentClass ?? this.studentClass,
      division: division ?? this.division,
      feesPaid: feesPaid ?? this.feesPaid,
      totalFees: totalFees ?? this.totalFees,
      uid: uid,
      feeDocId: feeDocId,
      uploadedAt: uploadedAt,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RESULT WRAPPER  (replaces Dart-3 named record)
// FIX: Projects on Dart <3.0 cannot use ({int success, int failed}).
//      A simple class is fully compatible with all SDK versions.
// ─────────────────────────────────────────────────────────────
class _UploadResult {
  final int success;
  final int failed;
  const _UploadResult(this.success, this.failed);
}

// ─────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────
class FeesFirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<FeeRecord>> fetchAllFeeRecords() async {
    final usersSnap = await _db.collection('users').get();
    final List<FeeRecord> records = [];

    final futures = usersSnap.docs.map((userDoc) async {
      try {
        final feeSnap = await _db
            .collection('users')
            .doc(userDoc.id)
            .collection('fees')
            .doc('feeDetails')
            .get();
        if (feeSnap.exists && feeSnap.data() != null) {
          records.add(
              FeeRecord.fromFirestore(feeSnap.data()!, userDoc.id, feeSnap.id));
        }
      } catch (_) {}
    });
    await Future.wait(futures);
    return records;
  }

  Future<void> updateFeeRecord(String uid, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('fees')
        .doc('feeDetails')
        .set({
      ...data,
      'uploadedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteFeeRecord(String uid) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('fees')
        .doc('feeDetails')
        .delete();
  }

  Future<String?> findUidByAdmissionNumber(String admNo) async {
    var q = await _db
        .collection('users')
        .where('admissionNumber', isEqualTo: admNo)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) return q.docs.first.id;

    q = await _db
        .collection('users')
        .where('id', isEqualTo: admNo)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) return q.docs.first.id;
    return null;
  }

  // FIX: Return type changed from named record to _UploadResult class
  Future<_UploadResult> commitBulkUpload(
      List<Map<String, dynamic>> rows) async {
    int success = 0, failed = 0;

    for (final row in rows) {
      try {
        final admNo = row['admissionNumber'].toString().trim();
        final uid = await findUidByAdmissionNumber(admNo);
        if (uid == null) {
          failed++;
          continue;
        }

        final double feesPaid = (row['feesPaid'] as num).toDouble();
        final double totalFees = (row['totalFees'] as num).toDouble();
        final double pending = (totalFees - feesPaid).clamp(0, double.infinity);
        final String status =
            feesPaid == 0 ? 'Due' : (pending == 0 ? 'Paid' : 'Partial');

        await _db
            .collection('users')
            .doc(uid)
            .collection('fees')
            .doc('feeDetails')
            .set({
          'admissionNumber': admNo,
          'studentName': row['studentName']?.toString() ?? '',
          'class': row['class']?.toString() ?? '',
          'division': row['division']?.toString() ?? '',
          'feesPaid': feesPaid,
          'totalFees': totalFees,
          'pendingAmount': pending,
          'status': status,
          'uploadedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        success++;
      } catch (_) {
        failed++;
      }
    }
    return _UploadResult(success, failed);
  }
}

// ─────────────────────────────────────────────────────────────
// EXCEL PARSER
// FIX: All excel types now use the `xl.` prefix to avoid the
//      Border / other name conflicts with flutter/material.dart
// ─────────────────────────────────────────────────────────────
class ExcelParser {
  static List<Map<String, dynamic>> parse(Uint8List bytes) {
    final excel = xl.Excel.decodeBytes(bytes);

    final sheet = excel.tables[excel.tables.keys.first];

    if (sheet == null || sheet.rows.length < 2) {
      return [];
    }

    int headerIdx = -1;

    final Map<String, int> colMap = {};

    // FIND HEADER ROW
    for (int i = 0; i < sheet.rows.length; i++) {
      final cells = sheet.rows[i]
          .map(
            (c) => c?.value?.toString().trim().toLowerCase() ?? '',
          )
          .toList();

      if (cells.any(
        (c) => c.contains('admissionnumber') || c == 'adm no',
      )) {
        headerIdx = i;

        for (int j = 0; j < cells.length; j++) {
          if (cells[j].isNotEmpty) {
            colMap[cells[j]] = j;
          }
        }

        break;
      }
    }

    if (headerIdx == -1) {
      return [];
    }

    // READ CELL VALUE
    String cellVal(
      List<xl.Data?> row,
      String keyFragment,
    ) {
      final entry = colMap.entries.firstWhere(
        (e) => e.key.contains(keyFragment),
        orElse: () => MapEntry('', -1),
      );

      if (entry.value == -1 || entry.value >= row.length) {
        return '';
      }

      return row[entry.value]?.value?.toString().trim() ?? '';
    }

    final List<Map<String, dynamic>> result = [];

    // PARSE ROWS
    for (int i = headerIdx + 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];

      final admNo = cellVal(row, 'admissionnumber');

      final name = cellVal(row, 'studentname');

      final paidStr = cellVal(row, 'feespaid');

      final totalStr = cellVal(row, 'totalfees');

      if (admNo.isEmpty || name.isEmpty) {
        continue;
      }

      final paid = double.tryParse(paidStr);

      final total = double.tryParse(totalStr);

      if (paid == null || total == null) {
        continue;
      }

      result.add({
        'admissionNumber': admNo,
        'studentName': name,
        'class': cellVal(row, 'class'),
        'division': cellVal(row, 'division'),
        'feesPaid': paid,
        'totalFees': total,
      });
    }

    return result;
  }

  static Uint8List generateTemplate() {
    final excel = xl.Excel.createExcel();

    final sheet = excel['Sheet1'];

    final headers = [
      'admissionNumber',
      'studentName',
      'class',
      'division',
      'feesPaid',
      'totalFees',
    ];

    // HEADER ROW
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(
          columnIndex: i,
          rowIndex: 0,
        ),
      );

      // FIXED
      cell.value = headers[i];

      // FIXED
      cell.cellStyle = xl.CellStyle(
        bold: true,
      );
    }

    // SAMPLE DATA
    final sample = [
      ['ADM001', 'Sample Student 1', '10th', 'M1', '5000', '10000'],
      ['ADM002', 'Sample Student 2', '11th', 'E1', '10000', '10000'],
    ];

    for (int r = 0; r < sample.length; r++) {
      for (int c = 0; c < sample[r].length; c++) {
        final cell = sheet.cell(
          xl.CellIndex.indexByColumnRow(
            columnIndex: c,
            rowIndex: r + 1,
          ),
        );

        // FIXED
        cell.value = sample[r][c];
      }
    }

    final encoded = excel.encode();

    if (encoded == null) {
      return Uint8List(0);
    }

    return Uint8List.fromList(encoded);
  }
}

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────
class FeesScreen extends StatefulWidget {
  // FIX: Use old-style key param for Dart <2.17 compatibility.
  //      If your pubspec sdk is >=2.17 this is also fine; change to
  //      `const FeesScreen({super.key});` if desired.
  const FeesScreen({Key? key}) : super(key: key);

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen>
    with SingleTickerProviderStateMixin {
  final FeesFirebaseService _svc = FeesFirebaseService();
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  List<FeeRecord> _records = [];
  bool _loading = false;
  String _filterStatus = 'All';
  String _filterClass = '';
  String _filterDivision = '';
  final List<String> _statusFilters = ['All', 'Paid', 'Partial', 'Due'];
  final Set<String> _expandedRows = {};

  bool _uploading = false;
  int _uploadSuccess = 0;
  int _uploadFailed = 0;
  bool _showUploadResult = false;

  String _sortBy = 'name';
  bool _sortAsc = true;

  final NumberFormat _fmt = NumberFormat('#,##0', 'en_IN');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() => setState(() {}));
    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // DATA OPS
  // ─────────────────────────────────────────────────────────
  Future<void> _loadRecords() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final records = await _svc.fetchAllFeeRecords();
      if (!mounted) return;
      setState(() => _records = records);
    } catch (e) {
      _toast('Error loading records: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateRecord(FeeRecord r, double newPaid, double newTotal,
      String cls, String div) async {
    try {
      final double pending = (newTotal - newPaid).clamp(0, double.infinity);
      final String status =
          newPaid == 0 ? 'Due' : (pending == 0 ? 'Paid' : 'Partial');
      await _svc.updateFeeRecord(r.uid, {
        'admissionNumber': r.admissionNumber,
        'studentName': r.studentName,
        'class': cls,
        'division': div,
        'feesPaid': newPaid,
        'totalFees': newTotal,
        'pendingAmount': pending,
        'status': status,
      });
      await _loadRecords();
      _toast('Record updated ✓');
    } catch (e) {
      _toast('Update failed: $e', error: true);
    }
  }

  Future<void> _deleteRecord(FeeRecord r) async {
    try {
      await _svc.deleteFeeRecord(r.uid);
      if (!mounted) return;
      setState(() => _records.removeWhere((x) => x.uid == r.uid));
      _toast('Record deleted');
    } catch (e) {
      _toast('Delete failed: $e', error: true);
    }
  }

  // ─────────────────────────────────────────────────────────
  // FILTER + SORT
  // ─────────────────────────────────────────────────────────
  List<FeeRecord> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    // FIX: Explicit type annotation on fold to avoid Object? '+' error
    final list = _records.where((r) {
      final matchQ = q.isEmpty ||
          r.studentName.toLowerCase().contains(q) ||
          r.admissionNumber.toLowerCase().contains(q);
      final matchStatus =
          _filterStatus == 'All' || r.statusLabel == _filterStatus;
      final matchClass = _filterClass.isEmpty || r.studentClass == _filterClass;
      final matchDiv = _filterDivision.isEmpty || r.division == _filterDivision;
      return matchQ && matchStatus && matchClass && matchDiv;
    }).toList();

    list.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'paid':
          cmp = a.feesPaid.compareTo(b.feesPaid);
          break;
        case 'pending':
          cmp = a.pendingAmount.compareTo(b.pendingAmount);
          break;
        case 'status':
          cmp = a.statusLabel.compareTo(b.statusLabel);
          break;
        default:
          cmp = a.studentName.compareTo(b.studentName);
      }
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  List<String> get _uniqueClasses {
    final list = _records
        .map((r) => r.studentClass)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    list.sort();
    return list;
  }

  List<String> get _uniqueDivisions {
    final list = _records
        .map((r) => r.division)
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();
    list.sort();
    return list;
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────
  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          error ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _setSort(String col) {
    setState(() {
      if (_sortBy == col) {
        _sortAsc = !_sortAsc;
      } else {
        _sortBy = col;
        _sortAsc = true;
      }
    });
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        title: const Text(
          'Fees Management',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadRecords,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Fee Records'),
            Tab(text: 'Upload via Excel'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecordsTab(),
          _buildUploadTab(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TAB 1 — FEE RECORDS
  // ═══════════════════════════════════════════════════════════
  Widget _buildRecordsTab() {
    final list = _filtered;

    // FIX: Explicit <double> type param on fold stops Object? '+' errors
    final double totalFees =
        _records.fold<double>(0.0, (s, r) => s + r.totalFees);
    final double totalPaid =
        _records.fold<double>(0.0, (s, r) => s + r.feesPaid);
    final double totalPending =
        _records.fold<double>(0.0, (s, r) => s + r.pendingAmount);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow(totalPaid, totalPending, totalFees),
          const SizedBox(height: 16),
          _buildSearchFilterRow(),
          const SizedBox(height: 12),
          _buildStatusChips(),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${list.length} record${list.length == 1 ? '' : 's'}',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (_filterStatus != 'All' ||
                  _filterClass.isNotEmpty ||
                  _filterDivision.isNotEmpty ||
                  _searchCtrl.text.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _filterStatus = 'All';
                    _filterClass = '';
                    _filterDivision = '';
                    _searchCtrl.clear();
                  }),
                  icon: const Icon(Icons.clear, size: 15),
                  label: const Text('Clear filters',
                      style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? _buildEmpty()
                    : _buildTable(list),
          ),
        ],
      ),
    );
  }

  // ── Summary cards ──────────────────────────────────────────
  Widget _buildSummaryRow(double paid, double pending, double total) {
    return Row(children: [
      _sumCard('Total Students', _records.length.toString(),
          Icons.people_alt_rounded, const Color(0xFF6366F1)),
      const SizedBox(width: 12),
      _sumCard('Collected', '₹${_fmt.format(paid)}',
          Icons.account_balance_wallet_rounded, const Color(0xFF16A34A)),
      const SizedBox(width: 12),
      _sumCard('Pending', '₹${_fmt.format(pending)}',
          Icons.pending_actions_rounded, const Color(0xFFDC2626)),
      const SizedBox(width: 12),
      _sumCard('Total Fees', '₹${_fmt.format(total)}', Icons.summarize_rounded,
          const Color(0xFF3B82F6)),
    ]);
  }

  Widget _sumCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          // FIX: flutter Border (not excel Border) — safe because xl. prefix
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17),
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Search + filter dropdowns ──────────────────────────────
  Widget _buildSearchFilterRow() {
    return Row(children: [
      Expanded(
        flex: 3,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Search by name or admission no…',
              hintStyle: TextStyle(fontSize: 13),
              prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      _dropdownFilter('Class', ['', ..._uniqueClasses], _filterClass,
          (v) => setState(() => _filterClass = v ?? '')),
      const SizedBox(width: 10),
      _dropdownFilter('Division', ['', ..._uniqueDivisions], _filterDivision,
          (v) => setState(() => _filterDivision = v ?? '')),
    ]);
  }

  Widget _dropdownFilter(String label, List<String> items, String value,
      void Function(String?) onChange) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: items.map((s) {
            return DropdownMenuItem<String>(
              value: s,
              child: Text(s.isEmpty ? 'All ${label}s' : s),
            );
          }).toList(),
          onChanged: onChange,
        ),
      ),
    );
  }

  // ── Status chips ───────────────────────────────────────────
  Widget _buildStatusChips() {
    const chipColors = <String, Color>{
      'All': Color(0xFF6366F1),
      'Paid': Color(0xFF16A34A),
      'Partial': Color(0xFFD97706),
      'Due': Color(0xFFDC2626),
    };
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _statusFilters.map((f) {
          final sel = _filterStatus == f;
          final color = chipColors[f] ?? Colors.blue;
          final count = f == 'All'
              ? _records.length
              : _records.where((r) => r.statusLabel == f).length;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filterStatus = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? color : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? color : Colors.grey.shade300),
                ),
                child: Text(
                  '$f ($count)',
                  style: TextStyle(
                    color: sel ? Colors.white : Colors.black87,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 14),
        Text('No fee records found',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        const SizedBox(height: 6),
        Text(
            _records.isEmpty
                ? 'Upload an Excel file in the "Upload via Excel" tab.'
                : 'Try clearing your filters.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        if (_records.isEmpty) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _tabController.animateTo(1),
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Go to Upload'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]
      ]),
    );
  }

  // ── Main table ─────────────────────────────────────────────
  Widget _buildTable(List<FeeRecord> list) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        _buildTableHeader(),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Expanded(
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16),
            itemBuilder: (_, i) => _buildRow(list[i]),
          ),
        ),
      ]),
    );
  }

  Widget _buildTableHeader() {
    Widget hdr(String label, String? sortKey, {int flex = 2}) {
      final active = sortKey != null && _sortBy == sortKey;
      return Expanded(
        flex: flex,
        child: GestureDetector(
          onTap: sortKey != null ? () => _setSort(sortKey) : null,
          child: Row(children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: active
                        ? const Color(0xFF6366F1)
                        : Colors.grey.shade500)),
            if (sortKey != null && active)
              Icon(
                _sortAsc
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 13,
                color: const Color(0xFF6366F1),
              ),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        hdr('Student', 'name', flex: 3),
        hdr('Adm No', null),
        hdr('Class', null, flex: 1),
        hdr('Paid', 'paid'),
        hdr('Total', null),
        hdr('Pending', 'pending'),
        hdr('Status', 'status'),
        const SizedBox(width: 72),
      ]),
    );
  }

  Widget _buildRow(FeeRecord r) {
    final expanded = _expandedRows.contains(r.admissionNumber);

    return Column(children: [
      InkWell(
        onTap: () => setState(() => expanded
            ? _expandedRows.remove(r.admissionNumber)
            : _expandedRows.add(r.admissionNumber)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Expanded(
              flex: 3,
              child: Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: r.statusColor.withValues(alpha: 0.12),
                  child: Text(
                    r.studentName.isNotEmpty
                        ? r.studentName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: r.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.studentName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                        if (r.division.isNotEmpty)
                          Text(r.division,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
                      ]),
                ),
              ]),
            ),
            Expanded(
              flex: 2,
              child: Text(r.admissionNumber,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ),
            Expanded(
              flex: 1,
              child: Text(r.studentClass, style: const TextStyle(fontSize: 12)),
            ),
            Expanded(
              flex: 2,
              child: Text('₹${_fmt.format(r.feesPaid)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13)),
            ),
            Expanded(
              flex: 2,
              child: Text('₹${_fmt.format(r.totalFees)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '₹${_fmt.format(r.pendingAmount)}',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: r.pendingAmount > 0
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A)),
              ),
            ),
            Expanded(
              flex: 2,
              child: _StatusBadge(r.statusLabel, r.statusColor),
            ),
            SizedBox(
              width: 72,
              child: Row(children: [
                _miniBtn(Icons.edit_outlined, const Color(0xFF6366F1),
                    () => _openEditDialog(r)),
                const SizedBox(width: 4),
                _miniBtn(Icons.delete_outline, const Color(0xFFDC2626),
                    () => _openDeleteDialog(r)),
                const SizedBox(width: 4),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ]),
            ),
          ]),
        ),
      ),
      if (expanded) _buildExpandedPanel(r),
    ]);
  }

  Widget _miniBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  Widget _buildExpandedPanel(FeeRecord r) {
    final paidPct = r.totalFees > 0 ? (r.feesPaid / r.totalFees) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 36, runSpacing: 12, children: [
          _infoChip('Class', r.studentClass.isEmpty ? '—' : r.studentClass),
          _infoChip('Division', r.division.isEmpty ? '—' : r.division),
          _infoChip('Fees Paid', '₹${_fmt.format(r.feesPaid)}'),
          _infoChip('Total Fees', '₹${_fmt.format(r.totalFees)}'),
          _infoChip('Pending', '₹${_fmt.format(r.pendingAmount)}',
              valueColor: r.pendingAmount > 0
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF16A34A)),
          if (r.uploadedAt != null)
            _infoChip('Last Updated',
                DateFormat('dd MMM yyyy, hh:mm a').format(r.uploadedAt!)),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Payment Progress',
              style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          Text('${(paidPct * 100).toStringAsFixed(1)}%',
              style:
                  TextStyle(color: r.statusColor, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: paidPct.clamp(0.0, 1.0),
            minHeight: 10.0,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(r.statusColor),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: r.statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: r.statusColor.withValues(alpha: 0.35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              r.isFullyPaid
                  ? Icons.check_circle_rounded
                  : r.isDue
                      ? Icons.cancel_rounded
                      : Icons.timelapse_rounded,
              color: r.statusColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              r.isFullyPaid
                  ? 'Fully Paid'
                  : r.isDue
                      ? 'Payment Due — ₹${_fmt.format(r.pendingAmount)} pending'
                      : 'Partial — ₹${_fmt.format(r.pendingAmount)} still pending',
              style: TextStyle(
                  color: r.statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _infoChip(String label, String value, {Color? valueColor}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
      const SizedBox(height: 2),
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? Colors.black87)),
    ]);
  }

  // ─────────────────────────────────────────────────────────
  // EDIT DIALOG — uses dialog's own BuildContext (ctx) for pop
  // ─────────────────────────────────────────────────────────
  void _openEditDialog(FeeRecord r) {
    final paidCtrl = TextEditingController(text: r.feesPaid.toStringAsFixed(0));
    final totalCtrl =
        TextEditingController(text: r.totalFees.toStringAsFixed(0));
    final classCtrl = TextEditingController(text: r.studentClass);
    final divCtrl = TextEditingController(text: r.division);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 440,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: Colors.grey.shade200))),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: Color(0xFF6366F1), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Edit Fee Record',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        Text(r.studentName,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                      ]),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close, size: 20),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          const Color(0xFF6366F1).withValues(alpha: 0.12),
                      child: Text(
                        r.studentName.isNotEmpty
                            ? r.studentName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.studentName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Adm: ${r.admissionNumber}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500)),
                        ]),
                  ]),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: _editField('Class', classCtrl, hint: 'e.g. 10th')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _editField('Division', divCtrl, hint: 'e.g. M1')),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _editField('Fees Paid (₹)', paidCtrl,
                          keyboard: TextInputType.number, hint: '0')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _editField('Total Fees (₹)', totalCtrl,
                          keyboard: TextInputType.number, hint: '0')),
                ]),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200))),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final paid = double.tryParse(paidCtrl.text.trim());
                    final total = double.tryParse(totalCtrl.text.trim());
                    if (paid == null || total == null) {
                      _toast('Enter valid numbers', error: true);
                      return;
                    }
                    if (paid > total) {
                      _toast('Paid cannot exceed total fees', error: true);
                      return;
                    }
                    Navigator.pop(ctx);
                    _updateRecord(r, paid, total, classCtrl.text.trim(),
                        divCtrl.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Changes'),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl,
      {TextInputType keyboard = TextInputType.text, String? hint}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF6366F1)),
          ),
        ),
      ),
    ]);
  }

  // ─────────────────────────────────────────────────────────
  // DELETE DIALOG
  // ─────────────────────────────────────────────────────────
  void _openDeleteDialog(FeeRecord r) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626), size: 26),
            ),
            const SizedBox(height: 14),
            const Text('Delete Fee Record',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                children: [
                  const TextSpan(
                      text: 'This will permanently delete the fee record for '),
                  TextSpan(
                      text: r.studentName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.black87)),
                  const TextSpan(text: '. Cannot be undone.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _deleteRecord(r);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Delete'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TAB 2 — UPLOAD VIA EXCEL
  // ═══════════════════════════════════════════════════════════
  Widget _buildUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF3B82F6)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Upload Fees via Excel',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Download the template → fill student fee data → upload.\n'
              'The system matches each row by Admission Number and saves fees to Firestore.',
              style:
                  TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            Row(children: [
              ElevatedButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download Template'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _uploading ? null : _pickAndUploadExcel,
                icon: _uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF6366F1)))
                    : const Icon(Icons.upload_file_rounded, size: 18),
                label: Text(_uploading ? 'Uploading…' : 'Upload Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _stepCard(
              '1',
              'Download Template',
              'Get the Excel file with the correct column headers.',
              Icons.download_rounded,
              const Color(0xFF3B82F6)),
          const SizedBox(width: 14),
          _stepCard(
              '2',
              'Fill in Data',
              'Add admissionNumber, studentName, feesPaid, totalFees for each student.',
              // FIX: Icons.edit_document doesn't exist → Icons.edit_note
              Icons.edit_note,
              const Color(0xFF6366F1)),
          const SizedBox(width: 14),
          _stepCard(
              '3',
              'Upload & Confirm',
              'Upload the file. Review the preview, then confirm to save.',
              Icons.cloud_upload_rounded,
              const Color(0xFF16A34A)),
        ]),
        const SizedBox(height: 24),
        _buildColumnRef(),
        const SizedBox(height: 24),
        if (_showUploadResult) _buildUploadResult(),
      ]),
    );
  }

  Widget _stepCard(
      String num, String title, String desc, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color,
              child: Text(num,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: color, size: 22),
          ]),
          const SizedBox(height: 12),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Text(desc,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 12, height: 1.5)),
        ]),
      ),
    );
  }

  Widget _buildColumnRef() {
    final cols = <List<Object>>[
      [
        'admissionNumber',
        'Unique student ID — used to find the Firestore doc',
        true
      ],
      ['studentName', 'Full name of the student', true],
      ['class', 'e.g. 10th, 11th  (optional)', false],
      ['division', 'e.g. M1, E2  (optional)', false],
      ['feesPaid', 'Amount already paid — numbers only', true],
      ['totalFees', 'Total fees for the term — numbers only', true],
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Required Excel Columns',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 14),
        // FIX: Explicit <Widget> type param on map to match
        //      Column.children type List<Widget>
        ...cols.map<Widget>((c) {
          final isReq = c[2] as bool;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isReq ? const Color(0xFFEFF6FF) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: isReq
                          ? const Color(0xFF93C5FD)
                          : Colors.grey.shade300),
                ),
                child: Text(
                  c[0] as String,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isReq
                          ? const Color(0xFF1E40AF)
                          : Colors.grey.shade700),
                ),
              ),
              const SizedBox(width: 10),
              if (isReq)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('required',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(c[1] as String,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ),
            ]),
          );
        }).toList(),
      ]),
    );
  }

  Widget _buildUploadResult() {
    final allOk = _uploadFailed == 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: allOk ? Colors.green.shade200 : Colors.orange.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                (allOk ? Colors.green : Colors.orange).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            allOk ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: allOk ? Colors.green : Colors.orange,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              allOk ? 'Upload Complete' : 'Upload Finished with Errors',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              '$_uploadSuccess record${_uploadSuccess == 1 ? '' : 's'} saved'
              '${_uploadFailed > 0 ? '  ·  $_uploadFailed failed (admission number not found)' : ''}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // EXCEL PICK + UPLOAD
  // ─────────────────────────────────────────────────────────
  Future<void> _pickAndUploadExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    final parsed = ExcelParser.parse(bytes);
    if (parsed.isEmpty) {
      _toast('No valid rows found. Check column names in the Excel file.',
          error: true);
      return;
    }
    _showPreviewDialog(parsed);
  }

  void _showPreviewDialog(List<Map<String, dynamic>> rows) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.preview_rounded, color: Color(0xFF6366F1)),
          const SizedBox(width: 10),
          Text('Preview — ${rows.length} rows found',
              style: const TextStyle(fontSize: 15)),
        ]),
        content: SizedBox(
          width: 580,
          height: 380,
          child: Column(children: [
            if (rows.length > 20)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Showing first 20 of ${rows.length} rows. All rows will be uploaded.',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  // FIX: borderRadius is NOT a param of TableBorder.all()
                  //      — removed. Wrap with ClipRRect if rounding needed.
                  border: TableBorder.all(color: Colors.grey.shade200),
                  columnWidths: const {
                    0: FlexColumnWidth(1.5),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                    4: FlexColumnWidth(1),
                    5: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFEFF6FF)),
                      children: [
                        'Adm No',
                        'Name',
                        'Class',
                        'Division',
                        'Paid',
                        'Total'
                      ]
                          .map((h) => Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(h,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ))
                          .toList(),
                    ),
                    ...rows.take(20).map(
                          (r) => TableRow(
                            children: [
                              _tCell(r['admissionNumber']),
                              _tCell(r['studentName']),
                              _tCell(r['class'] ?? ''),
                              _tCell(r['division'] ?? ''),
                              _tCell('₹${r['feesPaid']}'),
                              _tCell('₹${r['totalFees']}'),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _commitUpload(rows);
            },
            icon: const Icon(Icons.cloud_upload_rounded, size: 17),
            label: const Text('Confirm & Upload'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tCell(dynamic v) => Padding(
        padding: const EdgeInsets.all(7),
        child: Text(v?.toString() ?? '', style: const TextStyle(fontSize: 12)),
      );

  Future<void> _commitUpload(List<Map<String, dynamic>> rows) async {
    if (!mounted) return;
    setState(() {
      _uploading = true;
      _showUploadResult = false;
    });

    // FIX: result is now _UploadResult (not a named record)
    final _UploadResult res = await _svc.commitBulkUpload(rows);

    if (!mounted) return;
    setState(() {
      _uploading = false;
      _uploadSuccess = res.success;
      _uploadFailed = res.failed;
      _showUploadResult = true;
    });

    await _loadRecords();
    _toast(
      '✅ ${res.success} saved'
      '${res.failed > 0 ? "  ❌ ${res.failed} failed (student not found)" : ""}',
      error: res.failed > 0 && res.success == 0,
    );
  }

  // ─────────────────────────────────────────────────────────
  // TEMPLATE DOWNLOAD
  // FIX: Removed broken _webDownload getter. Clean kIsWeb branch.
  // ─────────────────────────────────────────────────────────
  Future<void> _downloadTemplate() async {
    try {
      final bytes = ExcelParser.generateTemplate();
      if (kIsWeb) {
        // Uncomment after adding `universal_html` or using `dart:html`:
        //
        // import 'dart:html' as html;
        // final blob = html.Blob([bytes]);
        // final url  = html.Url.createObjectUrlFromBlob(blob);
        // html.AnchorElement(href: url)
        //   ..setAttribute('download', 'fee_upload_template.xlsx')
        //   ..click();
        // html.Url.revokeObjectUrl(url);
        _toast(
            'Web: uncomment the dart:html block in _downloadTemplate() to enable download.');
      } else {
        // Uncomment after adding `path_provider`:
        //
        // final dir  = await getApplicationDocumentsDirectory();
        // final file = File('\${dir.path}/fee_upload_template.xlsx');
        // await file.writeAsBytes(bytes);
        // _toast('Saved to \${file.path}');
        _toast(
            'Mobile/Desktop: uncomment path_provider block in _downloadTemplate() (${bytes.length} bytes ready).');
      }
    } catch (e) {
      _toast('Template generation failed: $e', error: true);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      );
}
