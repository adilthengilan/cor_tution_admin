import 'package:corona_lms_webapp/src/controller/attendance_controller/attendance_controller.dart';
import 'package:corona_lms_webapp/src/controller/student_controllers/fetch_Student_Details.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDivisions = 'All Divisions';
  String _selectedClass = 'All Classes';
  String _selectedCourse = 'All Courses';
  List courses = [];

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
    'S3'
  ];

  DateTime _selectedDate = DateTime.now();

  final Map<String, Map<String, dynamic>> _attendanceData = {};

  List<dynamic> _students = [];

  @override
  void initState() {
    super.initState();
    // Fetch once here instead of in build() to avoid refetch loops.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final list = Provider.of<StudentDetailsProvider>(context, listen: false);
      list.fetchStudents('Student_list_@12', context);
    });
  }

  List<dynamic> get _filteredStudents {
    return _students.where((student) {
      final name = (student['student_name'] ?? '').toString().toLowerCase();
      final uid = (student['uid'] ?? '').toString().toLowerCase();
      final rollNo = (student['rollNo'] ?? '').toString().toLowerCase();
      final query = _searchController.text.toLowerCase();

      final matchesSearch =
          name.contains(query) || uid.contains(query) || rollNo.contains(query);

      final matchesClass =
          _selectedClass == 'All Classes' || student['class'] == _selectedClass;
      final matchDivision = _selectedDivisions == 'All Divisions' ||
          student['division'] == _selectedDivisions;
      final matchCourse = _selectedCourse == 'All Courses' ||
          student['course'] == _selectedCourse;

      return matchesSearch && matchesClass && matchDivision && matchCourse;
    }).toList();
  }

  Map<String, dynamic> get _currentAttendanceSummary {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return _attendanceData[dateKey] ??
        {
          'present': 0,
          'absent': 0,
          'late': 0,
          'total': _filteredStudents.length,
        };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateAttendance(int index, String status, String uid) {
    final prolist = Provider.of<AttendanceController>(context, listen: false);
    setState(() {
      _filteredStudents[index]['attendance'] = status;

      final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
      if (!_attendanceData.containsKey(dateKey)) {
        _attendanceData[dateKey] = {
          'present': 0,
          'absent': 0,
          'late': 0,
          'total': _filteredStudents.length,
        };
      }
      prolist.addAttendance(uid, dateKey, status);

      int present = 0;
      int absent = 0;
      int late = 0;

      for (var student in _filteredStudents) {
        switch (student['attendance']) {
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

      _attendanceData[dateKey] = {
        'present': present,
        'absent': absent,
        'late': late,
        'total': _filteredStudents.length,
      };
    });
  }

  void _markAllAttendance(String status) {
    final prolist = Provider.of<AttendanceController>(context, listen: false);
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    setState(() {
      for (var i = 0; i < _filteredStudents.length; i++) {
        _filteredStudents[i]['attendance'] = status;
        prolist.addAttendance(_filteredStudents[i]['uid'], dateKey, status);
      }

      _attendanceData[dateKey] = {
        'present': status == 'present' ? _filteredStudents.length : 0,
        'absent': status == 'absent' ? _filteredStudents.length : 0,
        'late': status == 'late' ? _filteredStudents.length : 0,
        'total': _filteredStudents.length,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = Provider.of<StudentDetailsProvider>(context);
    _students = list.studentDetails;
    courses = list.cources_lists;

    List<String> listedCourse = courses
        .map((item) => item['title']?.toString() ?? '')
        .where((title) => title.isNotEmpty)
        .toList();

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
        elevation: 0,
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=13'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: list.isLoadingStudents
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search and filter
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
                            onChanged: (value) {
                              setState(() {});
                            },
                            decoration: const InputDecoration(
                              hintText: 'Search students...',
                              prefixIcon: Icon(Icons.search),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedClass,
                            hint: const Text('Class'),
                            items: _classes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedClass = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: listedCourse.contains(_selectedCourse)
                                ? _selectedCourse
                                : null,
                            hint: const Text("Select a course"),
                            items: listedCourse.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedCourse = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDivisions,
                            hint: const Text('Division'),
                            items: _divisions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedDivisions = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Mark all buttons
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _markAllAttendance('present'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.1),
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Mark All Present'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _markAllAttendance('absent'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Mark All Absent'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Students list
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
                          // Table header
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: const [
                                SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Student',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Roll No',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Division',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Attendance',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),

                          // Table body
                          Expanded(
                            child: _filteredStudents.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No students found',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _filteredStudents.length,
                                    itemBuilder: (context, index) {
                                      final student = _filteredStudents[index];
                                      return Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  flex: 3,
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        backgroundImage: (student[
                                                                        'image'] !=
                                                                    null &&
                                                                student['image']
                                                                    .toString()
                                                                    .isNotEmpty)
                                                            ? NetworkImage(
                                                                student[
                                                                    'image'])
                                                            : null,
                                                        child: (student['image'] ==
                                                                    null ||
                                                                student['image']
                                                                    .toString()
                                                                    .isEmpty)
                                                            ? const Icon(
                                                                Icons.person)
                                                            : null,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          student['student_name'] ??
                                                              '',
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                      student['rollNo'] ?? ''),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                      student['division'] ??
                                                          ''),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Row(
                                                    children: [
                                                      _buildAttendanceButton(
                                                          index,
                                                          'present',
                                                          'Present',
                                                          Colors.green,
                                                          Icons.check_circle,
                                                          student['uid']),
                                                      const SizedBox(width: 8),
                                                      _buildAttendanceButton(
                                                          index,
                                                          'absent',
                                                          'Absent',
                                                          Colors.red,
                                                          Icons.cancel,
                                                          student['uid']),
                                                      const SizedBox(width: 8),
                                                      _buildAttendanceButton(
                                                          index,
                                                          'late',
                                                          'Late',
                                                          Colors.orange,
                                                          Icons.schedule,
                                                          student['uid']),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (index <
                                              _filteredStudents.length - 1)
                                            const Divider(),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Attendance saved successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Attendance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAttendanceButton(int index, String value, String label,
      Color color, IconData icon, String uid) {
    final isSelected = _filteredStudents[index]['attendance'] == value;

    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () => _updateAttendance(index, value, uid),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.grey[700],
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
