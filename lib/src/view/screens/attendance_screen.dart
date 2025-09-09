import 'package:corona_lms_webapp/src/controller/attendance_controller/attendance_controller.dart';
import 'package:corona_lms_webapp/src/controller/student_controllers/fetch_Student_Details.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

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
  CalendarFormat _calendarFormat = CalendarFormat.week;
  bool _showCalendar = false;

  // Sample attendance data
  final Map<String, Map<String, dynamic>> _attendanceData = {
    // '2023-05-15': {
    //   'present': 42,
    //   'absent': 8,
    //   'leave': 5,
    //   'total': 55,
    // },
    // '2023-05-16': {
    //   'present': 45,
    //   'absent': 7,
    //   'leave': 3,
    //   'total': 55,
    // },
    // '2023-05-17': {
    //   'present': 40,
    //   'absent': 10,
    //   'leave': 5,
    //   'total': 55,
    // },
  };

  // Sample students data
  List<dynamic> _students = [
    // {
    //   'id': 'ST-1001',
    //   'name': 'John Smith',
    //   'class': '10th',
    //   'rollNo': '101',
    //   'avatar': 'https://i.pravatar.cc/150?img=1',
    //   'attendance': 'present', // present, absent, leave
    // },
    // {
    //   'id': 'ST-1002',
    //   'name': 'Emily Johnson',
    //   'class': '12th',
    //   'rollNo': '201',
    //   'avatar': 'https://i.pravatar.cc/150?img=5',
    //   'attendance': 'present',
    // },
    // {
    //   'id': 'ST-1003',
    //   'name': 'Michael Brown',
    //   'class': '11th',
    //   'rollNo': '301',
    //   'avatar': 'https://i.pravatar.cc/150?img=3',
    //   'attendance': 'absent',
    // },
    // {
    //   'id': 'ST-1004',
    //   'name': 'Sarah Davis',
    //   'class': '10th',
    //   'rollNo': '102',
    //   'avatar': 'https://i.pravatar.cc/150?img=4',
    //   'attendance': 'present',
    // },
    // {
    //   'id': 'ST-1005',
    //   'name': 'David Wilson',
    //   'class': '9th',
    //   'rollNo': '401',
    //   'avatar': 'https://i.pravatar.cc/150?img=6',
    //   'attendance': 'leave',
    // },
    // {
    //   'id': 'ST-1006',
    //   'name': 'Jessica Taylor',
    //   'class': '8th',
    //   'rollNo': '501',
    //   'avatar': 'https://i.pravatar.cc/150?img=7',
    //   'attendance': 'present',
    // },
    // {
    //   'id': 'ST-1007',
    //   'name': 'Robert Martinez',
    //   'class': '10th',
    //   'rollNo': '103',
    //   'avatar': 'https://i.pravatar.cc/150?img=8',
    //   'attendance': 'present',
    // },
    // {
    //   'id': 'ST-1008',
    //   'name': 'Lisa Anderson',
    //   'class': '12th',
    //   'rollNo': '202',
    //   'avatar': 'https://i.pravatar.cc/150?img=9',
    //   'attendance': 'absent',
    // },
    // {
    //   'id': 'ST-1009',
    //   'name': 'Daniel Thomas',
    //   'class': '11th',
    //   'rollNo': '302',
    //   'avatar': 'https://i.pravatar.cc/150?img=10',
    //   'attendance': 'present',
    // },
    // {
    //   'id': 'ST-1010',
    //   'name': 'Jennifer White',
    //   'class': '9th',
    //   'rollNo': '402',
    //   'avatar': 'https://i.pravatar.cc/150?img=11',
    //   'attendance': 'present',
    // },
  ];

  List<dynamic> get _filteredStudents {
    return _students.where((student) {
      final name = student['student_name'].toString().toLowerCase();
      final id = student['id'].toString().toLowerCase();
      final rollNo = student['class'].toString().toLowerCase();
      final query = _searchController.text.toLowerCase();

      // Filter by search query
      final matchesSearch =
          name.contains(query) || id.contains(query) || rollNo.contains(query);

      // Filter by class
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

  void _updateAttendance(int index, String status, docid) {
    final prolist = Provider.of<AttendanceController>(context, listen: false);
    setState(() {
      _filteredStudents[index]['attendance'] = status;

      // Update attendance summary
      final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
      if (!_attendanceData.containsKey(dateKey)) {
        _attendanceData[dateKey] = {
          'present': 0,
          'absent': 0,
          'late': 0,
          'total': _filteredStudents.length,
        };
      }
      prolist.addAttendance(docid, dateKey, status);
      // Recalculate attendance counts
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
    setState(() {
      for (var i = 0; i < _filteredStudents.length; i++) {
        _filteredStudents[i]['attendance'] = status;
      }

      // Update attendance summary
      final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
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
    final list = Provider.of<StudentDetailsProvider>(context, listen: false);
    _students = list.studentDetails;

    list.fetchStudents('Student_list_@12', context);
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
        // backgroundColor: Colors.white,
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selector and calendar toggle
            // Row(
            //   children: [
            //     Expanded(
            //       child: GestureDetector(
            //         onTap: () {
            //           setState(() {
            //             _showCalendar = !_showCalendar;
            //           });
            //         },
            //         child: Container(
            //           padding: const EdgeInsets.symmetric(
            //               horizontal: 16, vertical: 12),
            //           decoration: BoxDecoration(
            //             color: Colors.white,
            //             borderRadius: BorderRadius.circular(12),
            //             border: Border.all(color: Colors.grey.shade300),
            //           ),
            //           child: Row(
            //             children: [
            //               const Icon(Icons.calendar_today),
            //               const SizedBox(width: 12),
            //               Text(
            //                 DateFormat('EEEE, MMMM d, yyyy')
            //                     .format(_selectedDate),
            //                 style: const TextStyle(
            //                   fontSize: 16,
            //                   fontWeight: FontWeight.bold,
            //                 ),
            //               ),
            //               const Spacer(),
            //               Icon(
            //                 _showCalendar
            //                     ? Icons.keyboard_arrow_up
            //                     : Icons.keyboard_arrow_down,
            //                 color: Colors.grey,
            //               ),
            //             ],
            //           ),
            //         ),
            //       ),
            //     ),
            //     const SizedBox(width: 16),
            //     ElevatedButton.icon(
            //       onPressed: () {
            //         _showAttendanceHistoryDialog();
            //       },
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: const Color(0xFF3B82F6),
            //         foregroundColor: Colors.white,
            //         padding: const EdgeInsets.symmetric(
            //             horizontal: 20, vertical: 12),
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //       ),
            //       icon: const Icon(Icons.history),
            //       label: const Text('History'),
            //     ),
            //   ],
            // ),

            // // Calendar (collapsible)
            // if (_showCalendar)
            //   Container(
            //     margin: const EdgeInsets.only(top: 16),
            //     padding: const EdgeInsets.all(16),
            //     decoration: BoxDecoration(
            //       color: Colors.white,
            //       borderRadius: BorderRadius.circular(12),
            //       boxShadow: [
            //         BoxShadow(
            //           color: Colors.black.withOpacity(0.05),
            //           blurRadius: 10,
            //           offset: const Offset(0, 4),
            //         ),
            //       ],
            //     ),
            //     child: TableCalendar(
            //       firstDay: DateTime.utc(2023, 1, 1),
            //       lastDay: DateTime.utc(2030, 12, 31),
            //       focusedDay: _selectedDate,
            //       calendarFormat: _calendarFormat,
            //       selectedDayPredicate: (day) {
            //         return isSameDay(_selectedDate, day);
            //       },
            //       onDaySelected: (selectedDay, focusedDay) {
            //         setState(() {
            //           _selectedDate = selectedDay;
            //           _showCalendar = false;
            //         });
            //       },
            //       onFormatChanged: (format) {
            //         setState(() {
            //           _calendarFormat = format;
            //         });
            //       },
            //       calendarStyle: const CalendarStyle(
            //         todayDecoration: BoxDecoration(
            //           color: Color(0xFF3B82F6),
            //           shape: BoxShape.circle,
            //         ),
            //         selectedDecoration: BoxDecoration(
            //           color: Color(0xFFFFC107),
            //           shape: BoxShape.circle,
            //         ),
            //       ),
            //       headerStyle: const HeaderStyle(
            //         formatButtonVisible: true,
            //         titleCentered: true,
            //       ),
            //     ),
            //   ),

            // const SizedBox(height: 24),

            // // Attendance summary cards
            // Row(
            //   children: [
            //     _buildAttendanceCard(
            //       'Present',
            //       _currentAttendanceSummary['present'],
            //       _currentAttendanceSummary['total'],
            //       Colors.green,
            //       Icons.check_circle,
            //     ),
            //     const SizedBox(width: 16),
            //     _buildAttendanceCard(
            //       'Absent',
            //       _currentAttendanceSummary['absent'],
            //       _currentAttendanceSummary['total'],
            //       Colors.red,
            //       Icons.cancel,
            //     ),
            //     const SizedBox(width: 16),
            //     _buildAttendanceCard(
            //       'Leave',
            //       _currentAttendanceSummary['leave'],
            //       _currentAttendanceSummary['total'],
            //       Colors.orange,
            //       Icons.schedule,
            //     ),
            //   ],
            // ),

            // const SizedBox(height: 24),

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
                      // isExpanded: true,
                      hint:
                          const Text("Select a course"), // 👈 shows placeholder
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
                                                    // backgroundImage: NetworkImage(
                                                    //     student['avatar']),
                                                    ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    student['student_name'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(student['id']),
                                          ),
                                          Expanded(
                                            child: Text(student['division']),
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
                                                    student['id']),
                                                const SizedBox(width: 8),
                                                _buildAttendanceButton(
                                                    index,
                                                    'absent',
                                                    'Absent',
                                                    Colors.red,
                                                    Icons.cancel,
                                                    student['id']),
                                                const SizedBox(width: 8),
                                                _buildAttendanceButton(
                                                    index,
                                                    'late',
                                                    'Late',
                                                    Colors.orange,
                                                    Icons.schedule,
                                                    student['id']),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (index < _filteredStudents.length - 1)
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

  Widget _buildAttendanceCard(
      String title, int count, int total, Color color, IconData icon) {
    final percentage =
        total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$percentage% of total',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceButton(int index, String value, String label,
      Color color, IconData icon, String docid) {
    final isSelected = _filteredStudents[index]['attendance'] == value;

    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () => _updateAttendance(index, value, docid),
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

  void _showAttendanceHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance History'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter by month
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'May 2023',
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: 'May 2023', child: Text('May 2023')),
                      DropdownMenuItem(
                          value: 'April 2023', child: Text('April 2023')),
                      DropdownMenuItem(
                          value: 'March 2023', child: Text('March 2023')),
                    ],
                    onChanged: (value) {},
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // History table
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      // Table header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: const [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Date',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Present',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Absent',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Late',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            SizedBox(width: 40),
                          ],
                        ),
                      ),
                      const Divider(),

                      // Table body
                      Expanded(
                        child: ListView.builder(
                          itemCount: _attendanceData.length,
                          itemBuilder: (context, index) {
                            final dateKey =
                                _attendanceData.keys.elementAt(index);
                            final data = _attendanceData[dateKey]!;
                            final date = DateTime.parse(dateKey);

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          DateFormat('EEEE, MMMM d, yyyy')
                                              .format(date),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('${data['present']}'),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('${data['absent']}'),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.orange,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('${data['late']}'),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Text('${data['total']}'),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: IconButton(
                                          icon: const Icon(Icons.visibility,
                                              color: Color(0xFF3B82F6)),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            setState(() {
                                              _selectedDate = date;
                                            });
                                          },
                                          iconSize: 20,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (index < _attendanceData.length - 1)
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Export attendance logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attendance exported successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}
