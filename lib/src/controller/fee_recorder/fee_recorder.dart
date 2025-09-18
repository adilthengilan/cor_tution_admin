import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FeeRecorder with ChangeNotifier {
  final CollectionReference feelist =
      FirebaseFirestore.instance.collection('studentList');
  List feedetails = [];

  /// CREATE a new document with empty studentDetails array

  /// ADD a new student to the studentDetails array
  Future<void> addfee(feeData) async {
    await feelist.doc('student_fees').update({
      'studentfees': FieldValue.arrayUnion([feeData])
    });
  }

  Future<List<Map<String, dynamic>>> fetchStudents(
      String docId, BuildContext context) async {
    final doc = await feelist.doc('student_fees').get();
    // print('=====');

    if (doc.exists) {
      List students = doc['studentfees'];
      print(students);
      feedetails = students;
      return List<Map<String, dynamic>>.from(students);
    } else {
      return [];
    }
  }

  // void checkaddorupdate(newStudentData) async {
  //   final doc = await feelist.doc('student_fee').get();
  //   List currentStudents = doc['studentfees'];
  //   final index =
  //       currentStudents.indexWhere((student) => student['id'] == studentId);
  //   if (index != -1) {
  //     addfee(newStudentData);
  //   } else {
  //     updatefees(newStudentData, studentId);
  //   }
  // }

  Future<void> updatefees(newStudentData, studentId) async {
    final doc = await feelist.doc('student_fees').get();
    List currentStudents = doc['studentfees'];

    // Remove old student
    currentStudents.removeWhere((student) => student['id'] == studentId);
    // Add updated student
    currentStudents.add(newStudentData);

    await feelist.doc('student_fee').update({
      'studentfees': currentStudents,
    });
  }
}

Future<void> addOrUpdateStudentByName({
  required String docId,
  required String studentName,
  required String studentId,
  required String phoneNumber,
  required int amount,
  required DateTime date,
  required String status, // Required to calculate payment status
}) async {
  final docRef =
      FirebaseFirestore.instance.collection('studentList').doc(docId);

  try {
    final snapshot = await docRef.get();

    List<dynamic> studentFees = [];

    if (snapshot.exists && snapshot.data()!.containsKey('studentfees')) {
      studentFees = List.from(snapshot['studentfees']);
    }

    // Match by name (case-insensitive)
    int index = studentFees.indexWhere(
      (student) =>
          student['name'].toString().toLowerCase() == studentName.toLowerCase(),
    );

    if (index != -1) {
      // Update existing student
      var student = studentFees[index];

      List payments = List.from(student['payment'] ?? []);
      payments.add({
        'amount': amount,
        'date': Timestamp.fromDate(date),
      });

      int updatedTotal = (student['totalAmountPaid'] ?? 0) + amount;

      // String status = getStatus(updatedTotal, fullFee);

      studentFees[index] = {
        ...student,
        'payment': payments,
        'totalAmountPaid': updatedTotal,
        'status': status,
      };

      // print("Updated existing student: $studentName");
    } else {
      // Add new student
      // String status = getStatus(amount, fullFee);

      studentFees.add({
        'id': studentId,
        'name': studentName,
        'totalAmountPaid': amount,
        'status': status,
        'payment': [
          {
            'amount': amount,
            'date': Timestamp.fromDate(date),
          }
        ]
      });

      // print("Added new student: $studentName");
    }

    await docRef.set({'studentfees': studentFees}, SetOptions(merge: true));
    // print('Student fee record updated with status.');
  } catch (e) {
    print('Error: $e');
  }
}

// 🔁 Helper function to calculate status
String getStatus(int totalPaid, int fullFee) {
  if (totalPaid >= fullFee) return 'paid';
  if (totalPaid == 0) return 'unpaid';
  return 'partial';
}

Future<void> addToTotalAmount(String docId, int amountToAdd) async {
  final docRef =
      FirebaseFirestore.instance.collection('studentList').doc(docId);

  try {
    await docRef.update({
      'amount': FieldValue.increment(amountToAdd),
    });
    // print('Added $amountToAdd to total amount.');
  } catch (e) {
    print('Failed to add amount: $e');
  }
}

Future<int> fetchTotalAmount(String docId) async {
  final docRef =
      FirebaseFirestore.instance.collection('studentList').doc(docId);

  try {
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      return snapshot.data()?['amount'] ?? 0;
    } else {
      print('Document not found.');
      return 0;
    }
  } catch (e) {
    print('Error fetching amount: $e');
    return 0;
  }
}
