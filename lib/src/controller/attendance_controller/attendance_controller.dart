import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceController with ChangeNotifier {
  final CollectionReference studentsList =
      FirebaseFirestore.instance.collection('StudentDocList');

  /// CREATE a new document with empty studentDetails array
  // Future<void> createStudentList(String docId) async {
  //   await studentsList.doc(docId).set({
  //     'studentDetails': [],
  //   });
  // }

  /// ADD a new student to the studentDetails array
  Future<void> addAttendance(
      String docId, String dateKey, String status) async {
    await studentsList
        .doc(docId)
        .collection('attendance')
        .doc(dateKey)
        .set({'status': status});
  }
}
