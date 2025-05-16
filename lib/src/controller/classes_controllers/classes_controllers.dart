import 'package:cloud_firestore/cloud_firestore.dart';

class ClassesService {
  final CollectionReference classesList =
      FirebaseFirestore.instance.collection('classes');

  /// CREATE a new document with empty studentDetails array
  Future<void> createClasses(String docId) async {
    await classesList.doc(docId).set({
      'classes': [],
    });
  }

  /// ADD a new student to the studentDetails array
  Future<void> addClasses(
      String docId, Map<String, dynamic> classesData) async {
    await classesList.doc(docId).update({
      'classes': FieldValue.arrayUnion([classesData])
    });
  }

  /// UPDATE a student from the studentDetails array
  Future<void> updateClasses(String docId, String studentId,
      Map<String, dynamic> newStudentData) async {
    final doc = await classesList.doc(docId).get();
    List currentStudents = doc['classes'];

    // Remove old student
    currentStudents
        .removeWhere((student) => student['student_name'] == studentId);
    // Add updated student
    currentStudents.add(newStudentData);

    await classesList.doc(docId).update({
      'studentDetails': currentStudents,
    });
  }

  /// DELETE a student from the studentDetails array
  Future<void> deleteClasses(String docId, String studentId) async {
    final doc = await classesList.doc(docId).get();
    List currentStudents = doc['studentDetails'];

    currentStudents.removeWhere((student) => student['id'] == studentId);

    await classesList.doc(docId).update({
      'studentDetails': currentStudents,
    });
  }
}
