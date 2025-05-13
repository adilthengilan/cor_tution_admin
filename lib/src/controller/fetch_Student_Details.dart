import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StudentData {
  final CollectionReference studentsList =
      FirebaseFirestore.instance.collection('studentList');

  /// Fetch the studentDetails array from a document
  Future<List<Map<String, dynamic>>> fetchStudents(
      String docId, BuildContext context) async {
    final doc = await studentsList.doc(docId).get();
    print('=====');

    final studentProvider =
        Provider.of<StudentDetailsProvider>(context, listen: false);

    if (doc.exists) {
      List students = doc['studentDetails'];
      print(students);
      studentProvider.studentDetails = students;
      return List<Map<String, dynamic>>.from(students);
    } else {
      return [];
    }
  }
}

class StudentDetailsProvider extends ChangeNotifier {
  List studentDetails = [];
}
