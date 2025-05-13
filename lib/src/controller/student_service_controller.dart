import 'package:cloud_firestore/cloud_firestore.dart';

class StudentService {
  final CollectionReference studentsList =
      FirebaseFirestore.instance.collection('studentList');

  /// CREATE a new document with empty studentDetails array
  Future<void> createStudentList(String docId) async {
    await studentsList.doc(docId).set({
      'studentDetails': [],
    });
  }

  /// ADD a new student to the studentDetails array
  Future<void> addStudent(
      String docId, Map<String, dynamic> studentData) async {
    await studentsList.doc(docId).update({
      'studentDetails': FieldValue.arrayUnion([studentData])
    });
  }

  /// UPDATE a student from the studentDetails array
  Future<void> updateStudent(String docId, String studentId,
      Map<String, dynamic> newStudentData) async {
    final doc = await studentsList.doc(docId).get();
    List currentStudents = doc['studentDetails'];

    // Remove old student
    currentStudents
        .removeWhere((student) => student['student_name'] == studentId);
    // Add updated student
    currentStudents.add(newStudentData);

    await studentsList.doc(docId).update({
      'studentDetails': currentStudents,
    });
  }

  /// DELETE a student from the studentDetails array
  Future<void> deleteStudent(String docId, String studentId) async {
    final doc = await studentsList.doc(docId).get();
    List currentStudents = doc['studentDetails'];

    currentStudents.removeWhere((student) => student['id'] == studentId);

    await studentsList.doc(docId).update({
      'studentDetails': currentStudents,
    });
  }
}
