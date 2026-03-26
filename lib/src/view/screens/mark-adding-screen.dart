// import 'package:corona_lms/controller/localStorage/shared_preference.dart';
// import 'package:corona_lms/controller/providers/attendance_controller.dart';
// import 'package:corona_lms_webapp/src/controller/attendance_controller/attendance_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter/services.dart';

// import 'package:provider/provider.dart';

// // void main() {
// //   runApp(MyApp());
// // }

// // class MyApp extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Mark Management System',
// //       theme: ThemeData(
// //         primarySwatch: Colors.blue,
// //         visualDensity: VisualDensity.adaptivePlatformDensity,
// //       ),
// //       home:
// //     );
// //   }
// // }

// // Data Models
// class MarkRecord {
//   final String id;
//   final String studentId;
//   final String studentName;
//   final String className;
//   final String division;
//   final String subject;
//   final double mark;
//   final String examName;
//   final DateTime date;
//   final String teacherId;
//   final String teacherName;

//   MarkRecord({
//     required this.id,
//     required this.studentId,
//     required this.studentName,
//     required this.className,
//     required this.division,
//     required this.subject,
//     required this.mark,
//     required this.examName,
//     required this.date,
//     required this.teacherId,
//     required this.teacherName,
//   });

//   factory MarkRecord.fromMap(String id, Map<String, dynamic> data) {
//     return MarkRecord(
//       id: id,
//       studentId: data['studentId'] ?? '',
//       studentName: data['studentName'] ?? '',
//       className: data['className'] ?? '',
//       division: data['division'] ?? '',
//       subject: data['subject'] ?? '',
//       mark: (data['mark'] ?? 0).toDouble(),
//       examName: data['examName'] ?? '',
//       date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
//       teacherId: data['teacherId'] ?? '',
//       teacherName: data['teacherName'] ?? '',
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'studentId': studentId,
//       'studentName': studentName,
//       'className': className,
//       'division': division,
//       'subject': subject,
//       'mark': mark,
//       'examName': examName,
//       'date': Timestamp.fromDate(date),
//       'teacherId': teacherId,
//       'teacherName': teacherName,
//       'createdAt': FieldValue.serverTimestamp(),
//     };
//   }
// }

// class Student {
//   final String id;
//   final String name;
//   final String className;
//   final String division;

//   Student({
//     required this.id,
//     required this.name,
//     required this.className,
//     required this.division,
//   });

//   factory Student.fromMap(String id, Map<String, dynamic> data) {
//     return Student(
//       id: id,
//       name: data['name'] ?? '',
//       className: data['class'] ?? '',
//       division: data['division'] ?? '',
//     );
//   }
// }

// // Main Mark Adding Page
// class MarkAddingPage extends StatefulWidget {
//   final MarkRecord? editingMark;

//   const MarkAddingPage({
//     Key? key,
//     this.editingMark,
//   }) : super(key: key);

//   @override
//   State<MarkAddingPage> createState() => _MarkAddingPageState();
// }

// class _MarkAddingPageState extends State<MarkAddingPage> {
//   final _formKey = GlobalKey<FormState>();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final TextEditingController _markController = TextEditingController();
//   final TextEditingController _examNameController = TextEditingController();
//   final TextEditingController _searchController = TextEditingController();
//   final TextEditingController _outOfController = TextEditingController();
//   final TextEditingController _gradeController = TextEditingController();

//   List<dynamic> _students = [];
//   final List<String> _classes = [
//     '6th',
//     '7th',
//     '8th',
//     '9th',
//     '10th',
//     '11th',
//     '12th'
//   ];
//   final List<String> _divisions = [
//     'M1',
//     'M2',
//     'M3',
//     'M4',
//     'M5',
//     'M6',
//     'M7',
//     'E1',
//     'E2',
//     'E3',
//     'E4',
//     'E5',
//     'S1',
//     'S2',
//     'S3'
//   ];

//   String? _selectedClass;
//   String? _selectedDivision;
//   String? _selectedStudent;
//   DateTime _selectedDate = DateTime.now();
//   bool _isLoading = false;
//   bool _isStudentsLoading = false;
//   String _studentSearchQuery = '';
//   List<dynamic> datas = [];
//   String teacherName = '';
//   String teacherSubject = '';

//   @override
//   void initState() {
//     super.initState();
//     _initializeMockData(datas);

//     if (widget.editingMark != null) {
//       _initializeForEditing();
//     }
//   }

//   void _initializeMockData(data) {
//     _students = data;
//   }

//   void _initializeForEditing() {
//     // final mark = widget.editingMark!;
//     // _selectedClass = mark.className;
//     // _selectedDivision = mark.division;
//     // _markController.text = mark.mark.toString();
//     // _examNameController.text = mark.examName;
//     // _selectedDate = mark.date;

//     // _loadStudents(mark.className, mark.division).then((_) {
//     //   setState(() {
//     //     _selectedStudent = _students.firstWhere(
//     //       (s) => s.id == mark.studentId,
//     //       orElse: () => Student(
//     //         id: mark.studentId,
//     //         name: mark.studentName,
//     //         className: mark.className,
//     //         division: mark.division,
//     //       ),
//     //     );
//     //   });
//     // });
//   }

//   List<dynamic> get filteredStudents {
//     var filtered = _students
//         .where((student) =>
//             student['class'] == _selectedClass &&
//             student['division'] == _selectedDivision)
//         .toList();

//     if (_studentSearchQuery.isNotEmpty) {
//       final query = _studentSearchQuery.toLowerCase();
//       filtered = filtered
//           .where((student) =>
//               student['student_name'].toLowerCase().contains(query) ||
//               student['id'].toLowerCase().contains(query))
//           .toList();
//     }

//     // Sort by name for better organization
//     filtered.sort((a, b) => a['student_name'].compareTo(b['student_name']));

//     return filtered;
//   }

//   Future<void> _loadStudents(String className, String division) async {
//     if (className.isEmpty || division.isEmpty) return;

//     setState(() => _isStudentsLoading = true);

//     try {
//       await Future.delayed(Duration(milliseconds: 300));
//       setState(() {
//         _studentSearchQuery = '';
//       });
//     } catch (e) {
//       _showErrorSnackbar('Failed to load students: $e');
//     } finally {
//       setState(() => _isStudentsLoading = false);
//     }
//   }

//   bool _validateForm() {
//     bool isValid = _formKey.currentState?.validate() ?? false;

//     if (_selectedClass == null) {
//       _showErrorSnackbar('Please select a class');
//       return false;
//     }

//     if (_selectedDivision == null) {
//       _showErrorSnackbar('Please select a division');
//       return false;
//     }

//     if (_selectedStudent == null) {
//       _showErrorSnackbar('Please select a student');
//       return false;
//     }

//     return isValid;
//   }

//   Future<void> _saveOrUpdateMark(Mark) async {
//     if (!_validateForm()) return;

//     setState(() => _isLoading = true);

//     try {
//       // Simulate save operation
//       await Future.delayed(Duration(seconds: 1));

//       _showSuccessSnackbar(widget.editingMark == null
//           ? 'Mark added successfully!'
//           : 'Mark updated successfully!');

//       await Future.delayed(Duration(milliseconds: 500));
//       if (mounted) {
//         final controller =
//             Provider.of<AttendanceController>(context, listen: false);
//         // controller.addTeacher(Mark);
//         // Navigator.pop(context, true);
//       }
//     } catch (e) {
//       _showErrorSnackbar('Error saving mark: $e');
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   void _showErrorSnackbar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.error_outline, color: Colors.white),
//             SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         margin: EdgeInsets.all(16),
//       ),
//     );
//   }

//   void _showSuccessSnackbar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.check_circle_outline, color: Colors.white),
//             SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         margin: EdgeInsets.all(16),
//       ),
//     );
//   }

//   Color _getMarkGradeColor(double mark) {
//     if (mark >= 90) return Colors.purple;
//     if (mark >= 80) return Colors.blue;
//     if (mark >= 70) return Colors.green;
//     if (mark >= 60) return Colors.orange;
//     if (mark >= 40) return Colors.amber;
//     return Colors.red;
//   }

//   String _getGrade(double mark) {
//     if (mark >= 90) return 'A+';
//     if (mark >= 80) return 'A';
//     if (mark >= 70) return 'B+';
//     if (mark >= 60) return 'B';
//     if (mark >= 50) return 'C';
//     if (mark >= 40) return 'D';
//     return 'F';
//   }

//   @override
//   void dispose() {
//     _markController.dispose();
//     _examNameController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final controller = Provider.of<fetchclass>(context, listen: false);
//     _students = controller.studentLoginDetails;
//     final index_Controller =
//         Provider.of<LocalStorageService>(context, listen: false);
//     final indexofid = controller.teachers.indexWhere(
//         (element) => element['contact'] == index_Controller.index2!);
//     teacherName = controller.teachers[indexofid]['student_name'];
//     teacherSubject = controller.teachers[indexofid]['class'];
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.editingMark == null ? 'Add Mark' : 'Edit Mark'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         elevation: 2,
//       ),
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             padding: EdgeInsets.all(16),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildSubjectCard(),
//                   SizedBox(height: 16),
//                   _buildClassDivisionRow(),
//                   SizedBox(height: 16),
//                   _buildStudentSelection(),
//                   SizedBox(height: 16),
//                   buildMarkExamRow(
//                       context,
//                       _markController,
//                       _examNameController,
//                       _outOfController,
//                       _gradeController,
//                       () {}),
//                   SizedBox(height: 16),
//                   _buildDatePicker(),
//                   SizedBox(height: 16),
//                   _buildMarkPreview(),
//                   SizedBox(height: 24),
//                   _buildActionButtons(),
//                 ],
//               ),
//             ),
//           ),
//           if (_isLoading) _buildLoadingOverlay(),
//         ],
//       ),
//     );
//   }

//   Widget _buildSubjectCard() {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Icon(Icons.subject, color: Colors.blue, size: 28),
//             SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Subject',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     teacherSubject,
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     'Teacher: ${teacherName}',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildClassDivisionRow() {
//     return Row(
//       children: [
//         Expanded(
//           child: DropdownButtonFormField<String>(
//             value: _selectedClass,
//             decoration: InputDecoration(
//               labelText: 'Class',
//               prefixIcon: Icon(Icons.school),
//               border:
//                   OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//             ),
//             items: _classes.map((item) {
//               return DropdownMenuItem(
//                 value: item,
//                 child: Text(item),
//               );
//             }).toList(),
//             onChanged: (value) {
//               setState(() {
//                 _selectedClass = value;
//                 _selectedDivision = null;
//                 _selectedStudent = null;
//               });
//             },
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please select class';
//               }
//               return null;
//             },
//           ),
//         ),
//         SizedBox(width: 16),
//         Expanded(
//           child: DropdownButtonFormField<String>(
//             value: _selectedDivision,
//             decoration: InputDecoration(
//               labelText: 'Division',
//               prefixIcon: Icon(Icons.groups),
//               border:
//                   OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//             ),
//             items: _divisions.map((item) {
//               return DropdownMenuItem(
//                 value: item,
//                 child: Text(item),
//               );
//             }).toList(),
//             onChanged: (value) {
//               setState(() {
//                 _selectedDivision = value;
//                 _selectedStudent = null;
//               });
//               if (_selectedClass != null && value != null) {
//                 _loadStudents(_selectedClass!, value);
//               }
//             },
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please select division';
//               }
//               return null;
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStudentSelection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (_selectedClass != null && _selectedDivision != null) ...[
//           TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               labelText: 'Search Students by Name or ID',
//               prefixIcon: Icon(Icons.search),
//               suffixIcon: _studentSearchQuery.isNotEmpty
//                   ? IconButton(
//                       icon: Icon(Icons.clear),
//                       onPressed: () {
//                         _searchController.clear();
//                         setState(() => _studentSearchQuery = '');
//                       },
//                     )
//                   : null,
//               border:
//                   OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//               hintText: 'Type student name or ID...',
//             ),
//             onChanged: (value) {
//               setState(() => _studentSearchQuery = value);
//             },
//           ),
//           SizedBox(height: 12),
//         ],
//         if (_isStudentsLoading)
//           Center(
//             child: Padding(
//               padding: EdgeInsets.all(20),
//               child: CircularProgressIndicator(),
//             ),
//           )
//         else if (filteredStudents.isNotEmpty)
//           Card(
//             elevation: 2,
//             child: Column(
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(4),
//                       topRight: Radius.circular(4),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.people, color: Colors.blue),
//                       SizedBox(width: 8),
//                       Text(
//                         'Select Student (${filteredStudents.length} students)',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue[800],
//                         ),
//                       ),
//                       // if (_selectedStudent != null) ...[
//                       //   Spacer(),
//                       //   Text(
//                       //     'Selected: ${_selectedStudent}',
//                       //     style: TextStyle(
//                       //       color: Colors.green[700],
//                       //       fontWeight: FontWeight.bold,
//                       //       fontSize: 12,
//                       //     ),
//                       //   ),
//                       // ],
//                     ],
//                   ),
//                 ),
//                 Container(
//                   height: 200,
//                   child: ListView.builder(
//                     itemCount: filteredStudents.length,
//                     itemBuilder: (context, index) {
//                       final student = filteredStudents[index];
//                       final isSelected =
//                           _selectedStudent == student['student_name'];

//                       return ListTile(
//                         leading: CircleAvatar(
//                           backgroundColor:
//                               isSelected ? Colors.blue : Colors.grey[300],
//                           child: Icon(
//                             Icons.person,
//                             color: isSelected ? Colors.white : Colors.grey[600],
//                           ),
//                         ),
//                         title: Text(
//                           student['student_name'],
//                           style: TextStyle(
//                             fontWeight: isSelected
//                                 ? FontWeight.bold
//                                 : FontWeight.normal,
//                           ),
//                         ),
//                         subtitle: Text(
//                             'ID: ${student['id']} | ${student['class']} - ${student['division']}'),
//                         trailing: isSelected
//                             ? Icon(Icons.check_circle, color: Colors.green)
//                             : null,
//                         selected: isSelected,
//                         onTap: () {
//                           setState(() {
//                             _selectedStudent = student['student_name'];
//                           });
//                         },
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           )
//         else if (_selectedClass != null && _selectedDivision != null)
//           Card(
//             child: Padding(
//               padding: EdgeInsets.all(20),
//               child: Column(
//                 children: [
//                   Icon(Icons.search_off, color: Colors.grey, size: 40),
//                   SizedBox(height: 12),
//                   Text(
//                     'No students found',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                   Text(
//                     '${_selectedClass} - ${_selectedDivision}',
//                     style: TextStyle(color: Colors.grey[600]),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//       ],
//     );
//   }

// // Updated _buildMarkExamRow method that you can use directly
//   Widget buildMarkExamRow(
//     BuildContext context,
//     TextEditingController markController,
//     TextEditingController examNameController,
//     TextEditingController outOfController,
//     TextEditingController gradeController,
//     VoidCallback onChanged,
//   ) {
//     double maxMark = MaxMarkManager.maxMark;

//     // Set initial value to controller if it's empty
//     if (outOfController.text.isEmpty) {
//       outOfController.text = maxMark.toInt().toString();
//     }

//     return Column(
//       children: [
//         // Main row with mark and exam name
//         Row(
//           children: [
//             Expanded(
//               child: TextFormField(
//                 controller: markController,
//                 keyboardType: TextInputType.number,
//                 inputFormatters: [
//                   FilteringTextInputFormatter.digitsOnly,
//                   // This prevents typing above maxMark
//                   TextInputFormatter.withFunction((oldValue, newValue) {
//                     if (newValue.text.isEmpty) return newValue;
//                     int? value = int.tryParse(newValue.text);
//                     // If user tries to type above maxMark, keep old value
//                     if (value == null || value > maxMark) return oldValue;
//                     return newValue;
//                   }),
//                 ],
//                 decoration: InputDecoration(
//                   labelText: 'Mark',
//                   prefixIcon: Icon(Icons.grade),
//                   border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8)),
//                   suffixText: '/${maxMark.toInt()}', // Shows current limit
//                   helperText: 'Max: ${maxMark.toInt()}', // Shows current limit
//                 ),
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Please enter mark';
//                   }
//                   int? mark = int.tryParse(value.trim());
//                   if (mark == null || mark < 0 || mark > maxMark) {
//                     return 'Enter valid mark (0-${maxMark.toInt()})';
//                   }
//                   return null;
//                 },
//                 onChanged: (value) => onChanged(),
//               ),
//             ),
//             SizedBox(width: 16),
//             Expanded(
//               flex: 2,
//               child: TextFormField(
//                 controller: examNameController,
//                 decoration: InputDecoration(
//                   labelText: 'Exam Name',
//                   prefixIcon: Icon(Icons.quiz),
//                   border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8)),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Please enter exam name';
//                   }
//                   return null;
//                 },
//               ),
//             ),
//           ],
//         ),

//         SizedBox(height: 12),

//         // Max mark setting row
//         Row(
//           children: [
//             Text('Out of: ',
//                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
//             SizedBox(width: 8),
//             SizedBox(
//               width: 70,
//               child: TextFormField(
//                 controller:
//                     outOfController, // Use controller instead of initialValue
//                 keyboardType: TextInputType.number,
//                 inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                 decoration: InputDecoration(
//                   border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8)),
//                   contentPadding:
//                       EdgeInsets.symmetric(horizontal: 8, vertical: 12),
//                   hintText: 'Max',
//                 ),
//                 onChanged: (value) {
//                   int? newMax = int.tryParse(value);
//                   if (newMax != null && newMax > 0) {
//                     MaxMarkManager.updateMaxMark(newMax.toDouble());
//                     // Clear mark field if current value exceeds new max
//                     int? currentMark = int.tryParse(markController.text);
//                     if (currentMark != null && currentMark > newMax) {
//                       markController.clear();
//                     }
//                     onChanged(); // This rebuilds the widget with new maxMark
//                   }
//                 },
//               ),
//             ),
//             SizedBox(width: 8),
//             Text('marks',
//                 style: TextStyle(fontSize: 14, color: Colors.grey[600])),
//             Spacer(),
//             SizedBox(width: 16),
//             Expanded(
//               flex: 2,
//               child: TextFormField(
//                 controller: gradeController,
//                 decoration: InputDecoration(
//                   labelText: 'Exam Grade',
//                   prefixIcon: Icon(Icons.grading),
//                   border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8)),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Please enter exam grade';
//                   }
//                   return null;
//                 },
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildDatePicker() {
//     return InkWell(
//       onTap: () async {
//         final DateTime? picked = await showDatePicker(
//           context: context,
//           initialDate: _selectedDate,
//           firstDate: DateTime(2020),
//           lastDate: DateTime.now().add(Duration(days: 365)),
//         );
//         if (picked != null && picked != _selectedDate) {
//           setState(() => _selectedDate = picked);
//         }
//       },
//       child: InputDecorator(
//         decoration: InputDecoration(
//           labelText: 'Date',
//           prefixIcon: Icon(Icons.calendar_today),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//         ),
//         child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
//       ),
//     );
//   }

//   Widget _buildMarkPreview() {
//     if (_markController.text.isEmpty || _selectedStudent == null) {
//       return SizedBox.shrink();
//     }

//     double? mark = double.tryParse(_markController.text);
//     if (mark == null) return SizedBox.shrink();

//     return Card(
//       color: Colors.white,
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.blue,
//                 shape: BoxShape.circle,
//               ),
//               child: Text(
//                 '${_gradeController.text}',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Mark Preview',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[600],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     '${_selectedStudent}',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Text(
//               '${mark.toInt()}/${_outOfController.text}',
//               style: TextStyle(
//                 color: Colors.black,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         Expanded(
//           child: OutlinedButton(
//             onPressed: _isLoading ? null : () => Navigator.pop(context),
//             child: Text('Cancel'),
//             style: OutlinedButton.styleFrom(
//               padding: EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8)),
//             ),
//           ),
//         ),
//         SizedBox(width: 16),
//         Expanded(
//           flex: 2,
//           child: ElevatedButton(
//             onPressed: () {
//               final mark = {
//                 'class': _selectedClass,
//                 'date': _selectedDate,
//                 'division': _selectedDivision,
//                 'student_name': _selectedStudent,
//                 'examName': _examNameController.text,
//                 'mark': '${_markController.text}/ ${_outOfController.text}',
//                 'subject': teacherSubject,
//                 'grade': _gradeController.text
//               };
//               _isLoading ? null : _saveOrUpdateMark(mark);
//             },
//             child: _isLoading
//                 ? Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           valueColor:
//                               AlwaysStoppedAnimation<Color>(Colors.white),
//                         ),
//                       ),
//                       SizedBox(width: 8),
//                       Text('Saving...'),
//                     ],
//                   )
//                 : Text(widget.editingMark == null ? 'Add Mark' : 'Update Mark'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue,
//               foregroundColor: Colors.white,
//               padding: EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8)),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildLoadingOverlay() {
//     return Container(
//       color: Colors.black.withOpacity(0.3),
//       child: Center(
//         child: Card(
//           child: Padding(
//             padding: EdgeInsets.all(20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text(
//                   'Processing...',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class MaxMarkManager {
//   static double maxMark = 100;

//   static void updateMaxMark(double newMax) {
//     maxMark = newMax;
//   }
// }
