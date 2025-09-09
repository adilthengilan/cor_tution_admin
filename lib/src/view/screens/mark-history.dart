import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corona_lms_webapp/src/controller/student_controllers/fetch_Student_Details.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      print('=============================================');
      print(markList);

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
        title: Text('Edit Mark', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: examNameController,
                decoration: InputDecoration(
                  labelText: 'Exam Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: markController,
                decoration: InputDecoration(
                  labelText: 'Mark',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
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
            child: Text('Update'),
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
        SnackBar(content: Text('Mark updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating mark: $e')),
      );
    }
  }

  Future<void> _deleteMark(int index) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Mark'),
        content: Text(
            'Are you sure you want to delete this mark? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete(index);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
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
        SnackBar(content: Text('Mark deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting mark: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[400]!, Colors.purple[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📊 Mark History',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text('Manage student marks and performance',
                style: TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: loadMarksList,
          ),
          IconButton(
            icon: Icon(Icons.filter_list_off, color: Colors.white),
            onPressed: _resetFilters,
          ),
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
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 20),
          Text('Loading marks... 📖',
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔍 Filters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),

          // Search bar
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Search by name, subject, or exam',
              prefixIcon: Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
            ),
            onChanged: (value) => _applyFilters(),
          ),

          SizedBox(height: 16),

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
              // _buildFilterDropdown(
              //     'Student', selectedStudent, availableStudents, (value) {
              //   setState(() => selectedStudent = value!);
              //   _applyFilters();
              // }),
            ],
          ),

          SizedBox(height: 16),

          // Results count
          Text(
              'Showing ${filteredMarksList.length} of ${allMarksList.length} records',
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        padding: EdgeInsets.symmetric(horizontal: 16),
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
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text('No marks found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          Text('Try adjusting your filters',
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildMarkCard(Map<String, dynamic> mark, int originalIndex) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${mark['class'] ?? 'N/A'} - ${mark['division'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditMarkDialog(mark, originalIndex),
                      tooltip: 'Edit Mark',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteMark(originalIndex),
                      tooltip: 'Delete Mark',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                    '📚 ${mark['examName'] ?? 'N/A'}', Colors.blue[100]!),
                SizedBox(width: 10),
                _buildInfoChip(
                    '📖 ${mark['subject'] ?? 'N/A'}', Colors.green[100]!),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.blue[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grade, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'MARK: ${mark['mark'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildInfoChip(String text, Color backgroundColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}

// Helper function to fetch marks (implement based on your provider)
Future<void> fetchMarkList(BuildContext context) async {
  // Implementation depends on your existing provider structure

  final tempseg = Provider.of<StudentDetailsProvider>(context, listen: false);
  tempseg.fetchMarkList('', context);
  // Add your fetch logic here
}
