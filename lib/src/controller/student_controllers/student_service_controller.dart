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

  Future<void> addTeacher(
      String docId, Map<String, dynamic> studentData) async {
    await studentsList.doc(docId).update({
      'TeachersList': FieldValue.arrayUnion([studentData])
    });
  }

  /// UPDATE a student from the studentDetails array
  Future<void> updateStudent(
      String docId, String studentId, newStudentData) async {
    final doc = await studentsList.doc(docId).get();
    List currentStudents = doc['studentDetails'];

    // Remove old student
    currentStudents.removeWhere((student) => student['id'] == studentId);
    // Add updated student
    currentStudents.add(newStudentData);

    await studentsList.doc(docId).update({
      'studentDetails': currentStudents,
    });
  }

  /// UPDATE a student from the studentDetails array
  Future<void> updateTeacher(
      String docId, String studentId, newStudentData) async {
    final doc = await studentsList.doc(docId).get();
    List currentStudents = doc['TeachersList'];

    // Remove old student
    currentStudents.removeWhere((student) => student['contact'] == studentId);
    // Add updated student
    currentStudents.add(newStudentData);

    await studentsList.doc(docId).update({
      'TeachersList': currentStudents,
    });
  }

  /// DELETE a student from the studentDetails array
  Future<void> deleteStudent(String docId, String studentId) async {
    final docSnapshot = await studentsList.doc(docId).get();

    if (docSnapshot.exists) {
      List currentStudents = List.from(docSnapshot['studentDetails']);

      currentStudents.removeWhere((student) => student['id'] == studentId);

      // Update the Firestore document with the modified list
      await studentsList.doc(docId).update({
        'studentDetails': currentStudents,
      });
    } else {
      print('Document with ID $docId does not exist.');
    }
  }

  Future<void> deleteTeacher(String docId, String studentId) async {
    final docSnapshot = await studentsList.doc(docId).get();

    if (docSnapshot.exists) {
      List currentStudents = List.from(docSnapshot['TeachersList']);

      currentStudents.removeWhere((student) => student['contact'] == studentId);

      // Update the Firestore document with the modified list
      await studentsList.doc(docId).update({
        'TeachersList': currentStudents,
      });
    } else {
      print('Document with ID $docId does not exist.');
    }
  }
}
