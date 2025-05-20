import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StudentData {}

class StudentDetailsProvider extends ChangeNotifier {
  List studentDetails = [];
  final CollectionReference studentsList =
      FirebaseFirestore.instance.collection('studentList');

  /// Fetch the studentDetails array from a document
  Future<List<Map<String, dynamic>>> fetchStudents(
      String docId, BuildContext context) async {
    final doc = await studentsList.doc(docId).get();
    print('=====');

    if (doc.exists) {
      List students = doc['studentDetails'];
      print(students);
      studentDetails = students;
      return List<Map<String, dynamic>>.from(students);
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
        print(doc.get('number'));
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
}
