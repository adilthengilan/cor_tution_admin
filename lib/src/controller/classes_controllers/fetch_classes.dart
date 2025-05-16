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
