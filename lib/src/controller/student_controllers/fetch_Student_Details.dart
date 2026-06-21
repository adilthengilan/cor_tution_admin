import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class StudentData {}

class StudentDetailsProvider extends ChangeNotifier {
  var docids = '';
  List studentDetails = [];
  List TeacherDetails = [];
  List mark_list = [];
  List cources_lists = [];
  String teacher_name = '';

  bool isLoadingStudents = false;
  bool _hasFetchedStudentsOnce = false;

  final CollectionReference studentsList =
      FirebaseFirestore.instance.collection('studentList');
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference markfinding =
      FirebaseFirestore.instance.collection('exams');
  final CollectionReference courses_list =
      FirebaseFirestore.instance.collection('classes');

  /// Fetch students from the `users` collection where role == 'student'.
  /// The `docId` param is kept for backward compatibility with existing
  /// call sites (e.g. fetchStudents('Student_list_@12', context)) but is
  /// no longer used to look up a document — it's now a flat query.
  Future<List<Map<String, dynamic>>> fetchStudents(
      String docId, BuildContext context,
      {bool forceRefresh = false}) async {
    if (_hasFetchedStudentsOnce && !forceRefresh) {
      return List<Map<String, dynamic>>.from(studentDetails);
    }

    isLoadingStudents = true;
    notifyListeners();

    try {
      final snapshot =
          await usersCollection.where('role', isEqualTo: 'student').get();

      final students = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'uid': doc.id,
          'student_name': data['student_name'] ?? '',
          'admissionNumber': data['admissionNumber'] ?? '',
          'email': data['email'] ?? '',
          'contact': data['contact'] ?? '',
          'rollNo': data['rollNo'] ?? '',
          'dob': data['dob'] ?? '',
          'doj': data['doj'] ?? '',
          'class': data['class'] ?? '',
          'division': data['division'] ?? '',
          'course': data['course'] ?? '',
          'status': data['status'] ?? '',
          'fee_status': data['fee_status'] ?? '',
          'image': data['image'] ?? '',
          'attendance': 'present', // local UI state default
        };
      }).toList();

      studentDetails = students;
      _hasFetchedStudentsOnce = true;
      return List<Map<String, dynamic>>.from(students);
    } catch (e) {
      debugPrint('Error fetching students: $e');
      studentDetails = [];
      return [];
    } finally {
      isLoadingStudents = false;
      notifyListeners();
    }
  }

  /// Force a refresh of the students list (e.g. pull-to-refresh, or after
  /// adding a new student).
  Future<void> refreshStudents(String docId, BuildContext context) async {
    await fetchStudents(docId, context, forceRefresh: true);
  }

  Future<List<String>> fetchCourses(BuildContext context) async {
    final doc = await courses_list.doc('courses-list').get();
    print('=====');

    if (doc.exists) {
      List students = doc['courses'];
      print(students);
      cources_lists = students;
      return List<String>.from(students);
    } else {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchTeachers(
      String docId, BuildContext context) async {
    final doc = await studentsList.doc(docId).get();
    // print('=====');

    if (doc.exists) {
      List students = doc['TeachersList'];
      // print(students);
      TeacherDetails = students;
      return List<Map<String, dynamic>>.from(students);
    } else {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchMarkList(
      String docId, BuildContext context) async {
    final doc = await markfinding.doc('mark-list').get();
    // print('=====');

    if (doc.exists) {
      List mark_l = doc['marks'];
      mark_list = mark_l;
      return List<Map<String, dynamic>>.from(mark_list);
    } else {
      return [];
    }
  }

  void updateindex() {
    FirebaseFirestore.instance
        .collection('studentList') // Replace with your collection name
        .doc('id_index') // Replace with your document ID
        .update({
      'number': FieldValue.increment(1),
    });
  }

  var index = 0;
  Future<int?> fetchNumber() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('studentList')
          .doc('id_index')
          .get();

      if (doc.exists) {
        index = doc.get('number');
        // print(doc.get('number'));
        return doc.get('number');
      } else {
        print('Document does not exist');
        return null;
      }
    } catch (e) {
      print('Error fetching number: $e');
      return null;
    }
  }

// Student DOc List for detailed activities for students
  final CollectionReference studentscollection =
      FirebaseFirestore.instance.collection('StudentDocList');

  /// CREATE a new document with empty studentDetails array
  Future<void> createStudentDocList(String docId) async {
    await studentscollection.doc(docId).set({
      'attendance': [],
      'Mark': [],
      'count': 0,
    });
  }
}
