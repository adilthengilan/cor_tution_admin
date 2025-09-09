import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClassDetailsProvider extends ChangeNotifier {
  List classDetails = [];
  final CollectionReference studentsList =
      FirebaseFirestore.instance.collection('classes');

  /// Fetch the studentDetails array from a document
  Future<List<Map<String, dynamic>>> fetchclass(
      String docId, BuildContext context) async {
    final doc = await studentsList.doc(docId).get();
    print('=====');

    if (doc.exists) {
      List classes = doc['classes'];
      print(classes);
      classDetails = classes;
      return List<Map<String, dynamic>>.from(classes);
    } else {
      return [];
    }
  }
}

Future<void> updateStudentsArray() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Reference to your document
  DocumentReference docRef =
      firestore.collection('studentList').doc('Student_list_@12');

  // Get the current data
  DocumentSnapshot snapshot = await docRef.get();

  if (snapshot.exists) {
    List<dynamic> students = snapshot['studentDetails'];

    // Loop and add new fields
    List updatedStudents = students.map((student) {
      Map<String, dynamic> s = Map<String, dynamic>.from(student);

      // Add new fields only if not already present
      s.putIfAbsent("rollNo", () => "");
      // s.putIfAbsent("dob", () => "");
      // s.putIfAbsent("doj", () => "");

      return s;
    }).toList();

    // Write back updated array
    await docRef.update({"studentDetails": updatedStudents});

    print("✅ All students updated with image, DOB, DOJ fields");
  }
}
