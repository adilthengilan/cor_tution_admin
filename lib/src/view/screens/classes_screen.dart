// ============================================================
//  classes_screen.dart  —  Full Firebase Integration
//  Firestore collection : 'classes_@corona'
//  Storage bucket       : gs://corona-lms-cc0db.firebasestorage.app
// ============================================================
//
//  pubspec.yaml dependencies needed:
//    firebase_core: ^2.x
//    cloud_firestore: ^4.x
//    firebase_storage: ^11.x
//    file_picker: ^6.x
//    url_launcher: ^6.x
//    intl: ^0.18.x
//
// ============================================================

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────
const String kFirestoreCollection = 'classes_@corona';
const String kStorageBucket = 'gs://corona-lms-cc0db.firebasestorage.app';

const List<String> kClasses = [
  '12th',
  '11th',
  '10th',
  '9th',
  '8th',
  '7th',
  '6th',
];
const List<String> kSubjects = [
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
  'Geography',
];
const List<String> kDivisions = [
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

// ─────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────
class ClassMaterial {
  final String docId; // Firestore document ID
  final String title;
  final String description;
  final String type; // 'Video' | 'Document'
  final String cls;
  final List<String> division;
  final String subject;
  final String uploadDate;
  final String url;

  const ClassMaterial({
    required this.docId,
    required this.title,
    required this.description,
    required this.type,
    required this.cls,
    required this.division,
    required this.subject,
    required this.uploadDate,
    required this.url,
  });

  // Firestore → Model
  factory ClassMaterial.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ClassMaterial(
      docId: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      type: d['type'] ?? 'Document',
      cls: d['class'] ?? '',
      division: List<String>.from(d['division'] ?? []),
      subject: d['subject'] ?? '',
      uploadDate: d['uploadDate'] ?? '',
      url: d['url'] ?? '',
    );
  }

  // Model → Firestore map
  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'type': type,
        'class': cls,
        'division': division,
        'subject': subject,
        'uploadDate': uploadDate,
        'url': url,
      };

  ClassMaterial copyWith({
    String? title,
    String? description,
    String? type,
    String? cls,
    List<String>? division,
    String? subject,
    String? uploadDate,
    String? url,
  }) =>
      ClassMaterial(
        docId: docId,
        title: title ?? this.title,
        description: description ?? this.description,
        type: type ?? this.type,
        cls: cls ?? this.cls,
        division: division ?? this.division,
        subject: subject ?? this.subject,
        uploadDate: uploadDate ?? this.uploadDate,
        url: url ?? this.url,
      );
}

// ─────────────────────────────────────────────────────────────
// FIREBASE SERVICE  (Firestore + Storage)
// ─────────────────────────────────────────────────────────────
class ClassesFirebaseService {
  // Firestore reference
  final CollectionReference _col =
      FirebaseFirestore.instance.collection(kFirestoreCollection);

  // Storage reference
  final FirebaseStorage _storage =
      FirebaseStorage.instanceFor(bucket: kStorageBucket);

  // ── Real-time stream ──────────────────────────────────────
  Stream<List<ClassMaterial>> streamMaterials() {
    return _col.orderBy('uploadDate', descending: true).snapshots().map(
          (snap) => snap.docs
              .map(
                (doc) => ClassMaterial.fromDoc(doc),
              )
              .toList(),
        );
  }

  // ── Add ───────────────────────────────────────────────────
  Future<void> addMaterial(Map<String, dynamic> data) async {
    await _col.add(data);
  }

  // ── Update ────────────────────────────────────────────────
  Future<void> updateMaterial(String docId, Map<String, dynamic> data) async {
    await _col.doc(docId).update(data);
  }

  // ── Delete ────────────────────────────────────────────────
  Future<void> deleteMaterial(String docId) async {
    await _col.doc(docId).delete();
  }

  // ── Upload file to Firebase Storage ──────────────────────
  // Returns the public download URL, or null on cancel/error.
  Future<String?> uploadFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ref = _storage.ref().child('uploads/$fileName');
    final task = ref.putData(bytes);
    final snapshot = await task.whenComplete(() {});
    return snapshot.ref.getDownloadURL();
  }

  // ── Pick + upload helper (cross-platform) ─────────────────
  Future<String?> pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null || result.files.first.bytes == null) return null;
      final bytes = result.files.first.bytes!;
      final name = result.files.first.name;
      return uploadFile(bytes: bytes, fileName: name);
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────
class ClassesScreen extends StatefulWidget {
  const ClassesScreen({Key? key}) : super(key: key);

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen>
    with SingleTickerProviderStateMixin {
  // ── Services ──────────────────────────────────────────────
  final ClassesFirebaseService _svc = ClassesFirebaseService();

  // ── UI state ──────────────────────────────────────────────
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _filterClass = '';
  String _filterSubject = '';
  String _filterDivision = '';
  bool _isGridView = true;

  // Tracks upload progress for add/edit dialogs
  bool _uploading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // FILTERING (client-side on streamed list)
  // ─────────────────────────────────────────────────────────
  List<ClassMaterial> _filtered(List<ClassMaterial> all, String tabType) {
    final q = _searchCtrl.text.toLowerCase();
    return all.where((m) {
      final matchTab = tabType == 'All' || m.type == tabType;
      final matchQ = q.isEmpty ||
          m.title.toLowerCase().contains(q) ||
          m.description.toLowerCase().contains(q);
      final matchC = _filterClass.isEmpty || m.cls == _filterClass;
      final matchS = _filterSubject.isEmpty || m.subject == _filterSubject;
      final matchD =
          _filterDivision.isEmpty || m.division.contains(_filterDivision);
      return matchTab && matchQ && matchC && matchS && matchD;
    }).toList();
  }

  // ─────────────────────────────────────────────────────────
  // FIREBASE CRUD WRAPPERS
  // ─────────────────────────────────────────────────────────
  Future<void> _addMaterial(Map<String, dynamic> data) async {
    try {
      await _svc.addMaterial(data);
      _toast('Material added successfully ✓');
    } catch (e) {
      _toast('Error adding material: $e', error: true);
    }
  }

  Future<void> _updateMaterial(String docId, Map<String, dynamic> data) async {
    try {
      await _svc.updateMaterial(docId, data);
      _toast('Material updated successfully ✓');
    } catch (e) {
      _toast('Error updating material: $e', error: true);
    }
  }

  Future<void> _deleteMaterial(String docId) async {
    try {
      await _svc.deleteMaterial(docId);
      _toast('Material deleted');
    } catch (e) {
      _toast('Error deleting material: $e', error: true);
    }
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          error ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ─────────────────────────────────────────────────────────
  // URL LAUNCHER
  // ─────────────────────────────────────────────────────────
  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _toast('Could not launch URL', error: true);
    }
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ClassMaterial>>(
      stream: _svc.streamMaterials(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final totalVideos = all.where((m) => m.type == 'Video').length;
        final totalDocs = all.where((m) => m.type == 'Document').length;
        final classesCovered = all.map((m) => m.cls).toSet().length;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            elevation: 0,
            title: const Text(
              'Class Materials — LMS',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 17),
            ),
            actions: [
              // Loading indicator for stream
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white70, strokeWidth: 2),
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: () => setState(() => _isGridView = !_isGridView),
                icon: Icon(
                  _isGridView ? Icons.view_list : Icons.grid_view,
                  color: Colors.white70,
                  size: 18,
                ),
                label: Text(
                  _isGridView ? 'List view' : 'Grid view',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'All Materials'),
                Tab(text: 'Videos'),
                Tab(text: 'Documents'),
              ],
            ),
          ),
          body: Column(
            children: [
              _buildToolbar(),
              _buildStats(all.length, totalVideos, totalDocs, classesCovered),
              Expanded(
                child: snapshot.hasError
                    ? _buildError(snapshot.error.toString())
                    : TabBarView(
                        controller: _tabController,
                        children: ['All', 'Video', 'Document']
                            .map((t) => _buildTabContent(all, t))
                            .toList(),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openAddDialog,
            backgroundColor: const Color(0xFF2563EB),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // TOOLBAR
  // ─────────────────────────────────────────────────────────
  Widget _buildToolbar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 38,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search materials...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          _filterDropdown('Class', ['', ...kClasses], _filterClass,
              (v) => setState(() => _filterClass = v ?? '')),
          _filterDropdown('Subject', ['', ...kSubjects], _filterSubject,
              (v) => setState(() => _filterSubject = v ?? '')),
          _filterDropdown('Division', ['', ...kDivisions], _filterDivision,
              (v) => setState(() => _filterDivision = v ?? '')),
          // Clear filters
          if (_filterClass.isNotEmpty ||
              _filterSubject.isNotEmpty ||
              _filterDivision.isNotEmpty ||
              _searchCtrl.text.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() {
                _filterClass = '';
                _filterSubject = '';
                _filterDivision = '';
                _searchCtrl.clear();
              }),
              icon: const Icon(Icons.clear, size: 15),
              label: const Text('Clear', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _filterDropdown(String label, List<String> items, String value,
      void Function(String?) onChanged) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
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
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // STATS BAR
  // ─────────────────────────────────────────────────────────
  Widget _buildStats(int total, int videos, int docs, int classes) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _statCard('Total', total, const Color(0xFF7C3AED)),
          const SizedBox(width: 10),
          _statCard('Videos', videos, const Color(0xFFDC2626)),
          const SizedBox(width: 10),
          _statCard('Documents', docs, const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          _statCard('Classes', classes, const Color(0xFF059669)),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w600, color: color)),
            Text(label,
                style: TextStyle(fontSize: 11, color: color.withOpacity(0.75))),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TAB CONTENT
  // ─────────────────────────────────────────────────────────
  Widget _buildTabContent(List<ClassMaterial> all, String tabType) {
    final list = _filtered(all, tabType);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No materials found',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('Adjust filters or add a new material.',
                style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      );
    }
    return _isGridView ? _buildGrid(list) : _buildListView(list);
  }

  Widget _buildError(String err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
          const SizedBox(height: 12),
          Text('Firebase error', style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 4),
          Text(err,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // GRID VIEW
  // ─────────────────────────────────────────────────────────
  Widget _buildGrid(List<ClassMaterial> list) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          childAspectRatio: 0.70,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: list.length,
        itemBuilder: (_, i) => _buildCard(list[i]),
      ),
    );
  }

  Widget _buildCard(ClassMaterial m) {
    final isVideo = m.type == 'Video';
    final thumbColor =
        isVideo ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF);
    final badgeColor =
        isVideo ? const Color(0xFFDC2626) : const Color(0xFF2563EB);
    final badgeBg = isVideo ? const Color(0xFFFEE2E2) : const Color(0xFFDBEAFE);

    return GestureDetector(
      onTap: () => _openViewDialog(m),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ──────────────────────
            Stack(
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: thumbColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Center(
                    child: Icon(
                      isVideo ? Icons.play_circle_fill : Icons.description,
                      size: 44,
                      color: badgeColor.withOpacity(0.6),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(m.type,
                        style: TextStyle(
                            fontSize: 11,
                            color: badgeColor,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            // ── Body ───────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(m.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _chip(m.cls, const Color(0xFF2563EB),
                            const Color(0xFFDBEAFE)),
                        _chip(m.subject, const Color(0xFF854D0E),
                            const Color(0xFFFEFCE8)),
                        ...m.division.take(2).map((d) => _chip(d,
                            const Color(0xFF166534), const Color(0xFFF0FDF4))),
                        if (m.division.length > 2)
                          _chip('+${m.division.length - 2}',
                              const Color(0xFF166534), const Color(0xFFF0FDF4)),
                      ],
                    ),
                    const Spacer(),
                    // ── Footer row ─────────────
                    Row(
                      children: [
                        Expanded(
                          child: Text(m.uploadDate,
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 10)),
                        ),
                        if (m.url.isNotEmpty)
                          _iconBtn(Icons.open_in_new, const Color(0xFF059669),
                              () => _launchURL(m.url)),
                        const SizedBox(width: 4),
                        _iconBtn(Icons.remove_red_eye_outlined,
                            const Color(0xFF2563EB), () => _openViewDialog(m)),
                        const SizedBox(width: 4),
                        _iconBtn(Icons.edit_outlined, const Color(0xFF7C3AED),
                            () => _openEditDialog(m)),
                        const SizedBox(width: 4),
                        _iconBtn(Icons.delete_outline, const Color(0xFFDC2626),
                            () => _openDeleteDialog(m)),
                      ],
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

  // ─────────────────────────────────────────────────────────
  // LIST VIEW
  // ─────────────────────────────────────────────────────────
  Widget _buildListView(List<ClassMaterial> list) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildListRow(list[i]),
    );
  }

  Widget _buildListRow(ClassMaterial m) {
    final isVideo = m.type == 'Video';
    final badgeColor =
        isVideo ? const Color(0xFFDC2626) : const Color(0xFF2563EB);
    final badgeBg = isVideo ? const Color(0xFFFEE2E2) : const Color(0xFFDBEAFE);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: badgeBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(
              isVideo ? Icons.play_circle_fill : Icons.description,
              color: badgeColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Title + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(m.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Tags
          Wrap(
            spacing: 4,
            children: [
              _chip(m.cls, const Color(0xFF2563EB), const Color(0xFFDBEAFE)),
              _chip(
                  m.subject, const Color(0xFF854D0E), const Color(0xFFFEFCE8)),
              ...m.division.take(2).map((d) =>
                  _chip(d, const Color(0xFF166534), const Color(0xFFF0FDF4))),
              if (m.division.length > 2)
                _chip('+${m.division.length - 2}', const Color(0xFF166534),
                    const Color(0xFFF0FDF4)),
            ],
          ),
          const SizedBox(width: 12),
          // Date
          Text(m.uploadDate,
              style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          const SizedBox(width: 12),
          // Actions
          Row(
            children: [
              if (m.url.isNotEmpty)
                _iconBtn(Icons.open_in_new, const Color(0xFF059669),
                    () => _launchURL(m.url)),
              const SizedBox(width: 6),
              _iconBtn(Icons.remove_red_eye_outlined, const Color(0xFF2563EB),
                  () => _openViewDialog(m)),
              const SizedBox(width: 6),
              _iconBtn(Icons.edit_outlined, const Color(0xFF7C3AED),
                  () => _openEditDialog(m)),
              const SizedBox(width: 6),
              _iconBtn(Icons.delete_outline, const Color(0xFFDC2626),
                  () => _openDeleteDialog(m)),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SHARED WIDGETS
  // ─────────────────────────────────────────────────────────
  Widget _chip(String label, Color text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: text, fontWeight: FontWeight.w600)),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 27,
        height: 27,
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // VIEW DIALOG
  // ─────────────────────────────────────────────────────────
  void _openViewDialog(ClassMaterial m) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumb header
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: m.type == 'Video'
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFEFF6FF),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Icon(
                    m.type == 'Video'
                        ? Icons.play_circle_fill
                        : Icons.description,
                    size: 56,
                    color: (m.type == 'Video'
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF2563EB))
                        .withOpacity(0.55),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _chip(
                          m.type,
                          m.type == 'Video'
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF2563EB),
                          m.type == 'Video'
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFDBEAFE),
                        ),
                        const Spacer(),
                        Text(m.uploadDate,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(m.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(m.description,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.5)),
                    const SizedBox(height: 16),
                    _viewMetaRow('Class', m.cls),
                    const SizedBox(height: 8),
                    _viewMetaRow('Subject', m.subject),
                    const SizedBox(height: 8),
                    _viewDivisionRow('Divisions', m.division),
                    if (m.url.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text('URL',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500])),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _launchURL(m.url),
                              child: Text(m.url,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2563EB),
                                      decoration: TextDecoration.underline)),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close')),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _openEditDialog(m);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewMetaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ),
        Expanded(
          child: Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _viewDivisionRow(String label, List<String> divisions) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: divisions
                .map((d) =>
                    _chip(d, const Color(0xFF166534), const Color(0xFFF0FDF4)))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // ADD DIALOG
  // ─────────────────────────────────────────────────────────
  void _openAddDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String type = 'Video';
    String cls = kClasses.first;
    String subject = kSubjects.first;
    List<String> selectedDivs = ['M1'];
    String? uploadedFileUrl; // set after Storage upload
    bool uploading = false;
    double progress = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => _materialDialog(
          title: 'Add New Material',
          titleCtrl: titleCtrl,
          descCtrl: descCtrl,
          urlCtrl: urlCtrl,
          type: type,
          cls: cls,
          subject: subject,
          selectedDivs: selectedDivs,
          uploading: uploading,
          uploadProgress: progress,
          uploadedFileUrl: uploadedFileUrl,
          onTypeChanged: (v) => setS(() => type = v),
          onClassChanged: (v) => setS(() => cls = v),
          onSubjectChanged: (v) => setS(() => subject = v),
          onDivToggle: (d) => setS(() {
            selectedDivs.contains(d)
                ? selectedDivs.remove(d)
                : selectedDivs.add(d);
          }),
          onUploadFile: () async {
            setS(() => uploading = true);
            try {
              final result =
                  await FilePicker.platform.pickFiles(withData: true);
              if (result != null && result.files.first.bytes != null) {
                final bytes = result.files.first.bytes!;
                final name = result.files.first.name;
                final ref = FirebaseStorage.instanceFor(bucket: kStorageBucket)
                    .ref()
                    .child('uploads/$name');
                final task = ref.putData(bytes);
                task.snapshotEvents.listen((event) {
                  setS(() {
                    progress = event.bytesTransferred / event.totalBytes;
                  });
                });
                final snap = await task.whenComplete(() {});
                final dlUrl = await snap.ref.getDownloadURL();
                setS(() {
                  uploadedFileUrl = dlUrl;
                  urlCtrl.text = dlUrl;
                  uploading = false;
                  progress = 0;
                });
                _toast('File uploaded ✓');
              } else {
                setS(() => uploading = false);
              }
            } catch (e) {
              setS(() => uploading = false);
              _toast('Upload failed: $e', error: true);
            }
          },
          onConfirm: () async {
            if (titleCtrl.text.trim().isEmpty) {
              _toast('Please enter a title', error: true);
              return;
            }
            if (selectedDivs.isEmpty) {
              _toast('Select at least one division', error: true);
              return;
            }
            final date = DateFormat('dd-MM-yyyy').format(DateTime.now());
            final data = {
              'title': titleCtrl.text.trim(),
              'description': descCtrl.text.trim(),
              'type': type,
              'class': cls,
              'division': selectedDivs,
              'subject': subject,
              'uploadDate': date,
              'url': type == 'Video'
                  ? urlCtrl.text.trim()
                  : (uploadedFileUrl ?? urlCtrl.text.trim()),
            };
            Navigator.pop(context);
            await _addMaterial(data);
          },
          confirmLabel: 'Add Material',
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // EDIT DIALOG
  // ─────────────────────────────────────────────────────────
  void _openEditDialog(ClassMaterial m) {
    final titleCtrl = TextEditingController(text: m.title);
    final descCtrl = TextEditingController(text: m.description);
    final urlCtrl = TextEditingController(text: m.url);
    String type = m.type;
    String cls = m.cls;
    String subject = m.subject;
    List<String> selectedDivs = List.from(m.division);
    String? uploadedFileUrl;
    bool uploading = false;
    double progress = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => _materialDialog(
          title: 'Edit Material',
          titleCtrl: titleCtrl,
          descCtrl: descCtrl,
          urlCtrl: urlCtrl,
          type: type,
          cls: cls,
          subject: subject,
          selectedDivs: selectedDivs,
          uploading: uploading,
          uploadProgress: progress,
          uploadedFileUrl: uploadedFileUrl,
          onTypeChanged: (v) => setS(() => type = v),
          onClassChanged: (v) => setS(() => cls = v),
          onSubjectChanged: (v) => setS(() => subject = v),
          onDivToggle: (d) => setS(() {
            selectedDivs.contains(d)
                ? selectedDivs.remove(d)
                : selectedDivs.add(d);
          }),
          onUploadFile: () async {
            setS(() => uploading = true);
            try {
              final result =
                  await FilePicker.platform.pickFiles(withData: true);
              if (result != null && result.files.first.bytes != null) {
                final bytes = result.files.first.bytes!;
                final name = result.files.first.name;
                final ref = FirebaseStorage.instanceFor(bucket: kStorageBucket)
                    .ref()
                    .child('uploads/$name');
                final task = ref.putData(bytes);
                task.snapshotEvents.listen((event) {
                  setS(() {
                    progress = event.bytesTransferred / event.totalBytes;
                  });
                });
                final snap = await task.whenComplete(() {});
                final dlUrl = await snap.ref.getDownloadURL();
                setS(() {
                  uploadedFileUrl = dlUrl;
                  urlCtrl.text = dlUrl;
                  uploading = false;
                  progress = 0;
                });
                _toast('File replaced ✓');
              } else {
                setS(() => uploading = false);
              }
            } catch (e) {
              setS(() => uploading = false);
              _toast('Upload failed: $e', error: true);
            }
          },
          onConfirm: () async {
            if (titleCtrl.text.trim().isEmpty) {
              _toast('Please enter a title', error: true);
              return;
            }
            if (selectedDivs.isEmpty) {
              _toast('Select at least one division', error: true);
              return;
            }
            final data = {
              'title': titleCtrl.text.trim(),
              'description': descCtrl.text.trim(),
              'type': type,
              'class': cls,
              'division': selectedDivs,
              'subject': subject,
              'url': type == 'Video'
                  ? urlCtrl.text.trim()
                  : (uploadedFileUrl ?? urlCtrl.text.trim()),
            };
            Navigator.pop(context);
            await _updateMaterial(m.docId, data);
          },
          confirmLabel: 'Save Changes',
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SHARED ADD/EDIT DIALOG LAYOUT
  // ─────────────────────────────────────────────────────────
  Widget _materialDialog({
    required String title,
    required TextEditingController titleCtrl,
    required TextEditingController descCtrl,
    required TextEditingController urlCtrl,
    required String type,
    required String cls,
    required String subject,
    required List<String> selectedDivs,
    required bool uploading,
    required double uploadProgress,
    required String? uploadedFileUrl,
    required void Function(String) onTypeChanged,
    required void Function(String) onClassChanged,
    required void Function(String) onSubjectChanged,
    required void Function(String) onDivToggle,
    required Future<void> Function() onUploadFile,
    required Future<void> Function() onConfirm,
    required String confirmLabel,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ───────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: Colors.grey.shade200))),
              child: Row(
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            // ── Body ─────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _formField('Title', titleCtrl, hint: 'Enter title'),
                    const SizedBox(height: 14),
                    _formField('Description', descCtrl,
                        hint: 'Enter description', maxLines: 3),
                    const SizedBox(height: 14),
                    _formDropdown(
                        'Type', ['Video', 'Document'], type, onTypeChanged),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: _formDropdown(
                                'Class', kClasses, cls, onClassChanged)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _formDropdown('Subject', kSubjects, subject,
                                onSubjectChanged)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // ── Division chips ──────────────
                    const Text('Divisions',
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: kDivisions.map((d) {
                          final sel = selectedDivs.contains(d);
                          return GestureDetector(
                            onTap: () => onDivToggle(d),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: sel
                                    ? const Color(0xFF2563EB)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: sel
                                        ? const Color(0xFF2563EB)
                                        : Colors.grey.shade300),
                              ),
                              child: Text(d,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          sel ? Colors.white : Colors.black54,
                                      fontWeight: sel
                                          ? FontWeight.w600
                                          : FontWeight.normal)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (selectedDivs.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Selected: ${selectedDivs.join(', ')}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF1D4ED8)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    // ── URL / File upload ───────────
                    if (type == 'Video')
                      _formField('Video URL', urlCtrl,
                          hint: 'https://youtube.com/...')
                    else ...[
                      const Text('Document File',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: uploading ? null : onUploadFile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: uploading
                                  ? const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.upload_file, size: 18),
                              label: Text(uploading
                                  ? 'Uploading...'
                                  : uploadedFileUrl != null
                                      ? 'Replace File'
                                      : 'Upload File'),
                            ),
                          ),
                        ],
                      ),
                      // Progress bar
                      if (uploading) ...[
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: uploadProgress,
                          backgroundColor: Colors.grey.shade200,
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(uploadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF2563EB)),
                        ),
                      ],
                      // Uploaded confirmation
                      if (!uploading && uploadedFileUrl != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 14, color: Color(0xFF059669)),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text('File uploaded to Storage',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF166534))),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            // ── Footer ───────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: uploading ? null : onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(confirmLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // DELETE DIALOG
  // ─────────────────────────────────────────────────────────
  void _openDeleteDialog(ClassMaterial m) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline,
                    size: 24, color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 14),
              const Text('Delete Material',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  children: [
                    const TextSpan(text: 'Are you sure you want to delete "'),
                    TextSpan(
                        text: m.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                    const TextSpan(text: '"? This cannot be undone.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteMaterial(m.docId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // FORM HELPERS
  // ─────────────────────────────────────────────────────────
  Widget _formField(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13),
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
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _formDropdown(String label, List<String> items, String value,
      void Function(String) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2563EB))),
          ),
          isExpanded: true,
          items: items
              .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChange(v);
          },
        ),
      ],
    );
  }
}
