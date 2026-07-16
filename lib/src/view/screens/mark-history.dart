import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corona_lms_webapp/src/controller/student_controllers/fetch_Student_Details.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corona_lms_webapp/main.dart';

class WebMarkHistoryScreen extends StatefulWidget {
  @override
  _WebMarkHistoryScreenState createState() => _WebMarkHistoryScreenState();
}

class _WebMarkHistoryScreenState extends State<WebMarkHistoryScreen> {
  List<dynamic> allMarksList = [];
  List filteredMarksList = [];
  bool isLoading = true;

  // Filter controllers
  String selectedClass = 'All';
  String selectedDivision = 'All';
  String selectedStudent = 'All';
  TextEditingController searchController = TextEditingController();

  // Available filter options
  List<String> availableClasses = [
    'All',
    '12th',
    '11th',
    '10th',
    '9th',
    '8th',
    '7th',
    '6th'
  ];
  List<String> availableDivisions = [
    'All',
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
  // List<String> availableStudents = ['All'];

  @override
  void initState() {
    super.initState();
    loadMarksList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadMarksList() async {
    try {
      setState(() => isLoading = true);
      await fetchMarkList(context);

      final tempseg =
          Provider.of<StudentDetailsProvider>(context, listen: false);
      final markList = tempseg.mark_list;

      setState(() {
        allMarksList = List.from(markList);
        filteredMarksList = List.from(allMarksList);
        // _populateFilterOptions();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading marks: $e')),
      );
    }
  }

  // void _populateFilterOptions() {
  //   Set<String> classes = {};
  //   Set<String> divisions = {};
  //   Set<String> students = {};

  //   for (var mark in allMarksList) {
  //     if (mark['class'] != null) classes.add(mark['class']);
  //     if (mark['division'] != null) divisions.add(mark['division']);
  //     if (mark['student_name'] != null) students.add(mark['student_name']);
  //   }

  //   setState(() {
  //     availableClasses = ['All', ...classes.toList()..sort()];
  //     availableDivisions = ['All', ...divisions.toList()..sort()];
  //     // availableStudents = ['All', ...students.toList()..sort()];
  //   });
  // }

  void _applyFilters() {
    setState(() {
      filteredMarksList = allMarksList.where((mark) {
        bool matchesClass =
            selectedClass == 'All' || mark['class'] == selectedClass;
        bool matchesDivision =
            selectedDivision == 'All' || mark['division'] == selectedDivision;
        bool matchesStudent =
            selectedStudent == 'All' || mark['student_name'] == selectedStudent;
        bool matchesSearch = searchController.text.isEmpty ||
            mark['student_name']
                    ?.toLowerCase()
                    .contains(searchController.text.toLowerCase()) ==
                true ||
            mark['subject']
                    ?.toLowerCase()
                    .contains(searchController.text.toLowerCase()) ==
                true ||
            mark['examName']
                    ?.toLowerCase()
                    .contains(searchController.text.toLowerCase()) ==
                true;

        return matchesClass &&
            matchesDivision &&
            matchesStudent &&
            matchesSearch;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      selectedClass = 'All';
      selectedDivision = 'All';
      selectedStudent = 'All';
      searchController.clear();
      filteredMarksList = List.from(allMarksList);
    });
  }

  Future<void> _showEditMarkDialog(Map<String, dynamic> mark, int index) async {
    final markController = TextEditingController(text: mark['mark'].toString());
    final subjectController =
        TextEditingController(text: mark['subject'] ?? '');
    final examNameController =
        TextEditingController(text: mark['examName'] ?? '');

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Mark', style: TextStyle(fontWeight: FontWeight.bold, color: MyApp.textPrimaryColor)),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: examNameController,
                style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Exam Name',
                  labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 12),
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
              const SizedBox(height: 16),
              TextField(
                controller: subjectController,
                style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 12),
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
              const SizedBox(height: 16),
              TextField(
                controller: markController,
                style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Mark',
                  labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 12),
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
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: MyApp.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateMark(index, {
                ...mark,
                'mark': markController.text,
                'subject': subjectController.text,
                'examName': examNameController.text,
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyApp.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMark(int index, Map<String, dynamic> updatedMark) async {
    try {
      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('exams')
          .doc('mark-list')
          .update({
        'marks': FieldValue.arrayRemove([allMarksList[index]])
      });

      await FirebaseFirestore.instance
          .collection('exams')
          .doc('mark-list')
          .update({
        'marks': FieldValue.arrayUnion([updatedMark])
      });

      // Update local state
      setState(() {
        allMarksList[index] = updatedMark;
        _applyFilters();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mark updated successfully!', style: TextStyle(color: Colors.white)),
          backgroundColor: MyApp.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating mark: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: MyApp.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _deleteMark(int index) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Mark', style: TextStyle(fontWeight: FontWeight.bold, color: MyApp.textPrimaryColor)),
        content: Text(
            'Are you sure you want to delete this mark? This action cannot be undone.',
            style: TextStyle(color: MyApp.textSecondaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: MyApp.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyApp.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(int index) async {
    try {
      final markToDelete = allMarksList[index];

      await FirebaseFirestore.instance
          .collection('exams')
          .doc('mark-list')
          .update({
        'marks': FieldValue.arrayRemove([markToDelete])
      });

      setState(() {
        allMarksList.removeAt(index);
        _applyFilters();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mark deleted successfully!', style: TextStyle(color: Colors.white)),
          backgroundColor: MyApp.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting mark: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: MyApp.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyApp.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        shape: Border(bottom: BorderSide(color: MyApp.borderColor)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mark History',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MyApp.textPrimaryColor)),
            Text('Manage student marks and performance',
                style: TextStyle(fontSize: 12, color: MyApp.textSecondaryColor)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: MyApp.textSecondaryColor),
            onPressed: loadMarksList,
          ),
          IconButton(
            icon: Icon(Icons.filter_list_off, color: MyApp.textSecondaryColor),
            onPressed: _resetFilters,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? _buildLoadingWidget()
          : Column(
              children: [
                _buildFilterSection(),
                Expanded(child: _buildMarksList()),
              ],
            ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(MyApp.primaryColor),
          ),
          const SizedBox(height: 20),
          Text('Loading marks... 📖',
              style: TextStyle(fontSize: 14, color: MyApp.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(24),
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
          Text('Filters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MyApp.textPrimaryColor)),
          const SizedBox(height: 16),

          // Search bar
          TextField(
            controller: searchController,
            style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Search by name, subject, or exam',
              labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 12),
              prefixIcon: Icon(Icons.search, color: MyApp.textSecondaryColor),
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
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: MyApp.textSecondaryColor),
                      onPressed: () {
                        searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
            ),
            onChanged: (value) => _applyFilters(),
          ),

          const SizedBox(height: 16),

          // Filter dropdowns
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildFilterDropdown('Class', selectedClass, availableClasses,
                  (value) {
                setState(() => selectedClass = value!);
                _applyFilters();
              }),
              _buildFilterDropdown(
                  'Division', selectedDivision, availableDivisions, (value) {
                setState(() => selectedDivision = value!);
                _applyFilters();
              }),
            ],
          ),

          const SizedBox(height: 16),

          // Results count
          Text(
              'Showing ${filteredMarksList.length} of ${allMarksList.length} records',
              style: TextStyle(fontSize: 13, color: MyApp.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> options,
      Function(String?) onChanged) {
    return Container(
      width: 200,
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: Colors.white,
        style: TextStyle(color: MyApp.textPrimaryColor, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: MyApp.textSecondaryColor, fontSize: 12),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: options
            .map((option) => DropdownMenuItem(
                  value: option,
                  child: Text(option),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMarksList() {
    if (filteredMarksList.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: loadMarksList,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: filteredMarksList.length,
        itemBuilder: (context, index) {
          final mark = filteredMarksList[index];
          final originalIndex = allMarksList.indexOf(mark);
          return _buildMarkCard(mark, originalIndex);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: MyApp.textSecondaryColor.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text('No marks found',
              style: TextStyle(fontSize: 16, color: MyApp.textPrimaryColor, fontWeight: FontWeight.bold)),
          Text('Try adjusting your filters',
              style: TextStyle(fontSize: 14, color: MyApp.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildMarkCard(Map<String, dynamic> mark, int originalIndex) {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mark['student_name'] ?? 'Unknown Student',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: MyApp.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${mark['class'] ?? 'N/A'} - ${mark['division'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 13, color: MyApp.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: MyApp.primaryColor),
                      onPressed: () => _showEditMarkDialog(mark, originalIndex),
                      tooltip: 'Edit Mark',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: MyApp.errorColor),
                      onPressed: () => _deleteMark(originalIndex),
                      tooltip: 'Delete Mark',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                    '📚 ${mark['examName'] ?? 'N/A'}', MyApp.primaryColor),
                const SizedBox(width: 10),
                _buildInfoChip(
                    '📖 ${mark['subject'] ?? 'N/A'}', MyApp.successColor),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: MyApp.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MyApp.primaryColor.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grade, color: MyApp.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'MARK: ${mark['mark'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: MyApp.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color baseColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: baseColor,
        ),
      ),
    );
  }
}

// Helper function to fetch marks (implement based on your provider)
Future<void> fetchMarkList(BuildContext context) async {
  final tempseg = Provider.of<StudentDetailsProvider>(context, listen: false);
  tempseg.fetchMarkList('', context);
}
