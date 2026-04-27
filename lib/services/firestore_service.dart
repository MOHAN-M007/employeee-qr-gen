import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _employees =>
      _db.collection("employees");

  static Future<void> addEmployee(Map<String, dynamic> employee) async {
    await _employees.add(employee);
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getEmployees() {
    // Backward compatible: older records used `timestamp`.
    return _employees.orderBy("timestamp", descending: true).snapshots();
  }

  static Future<void> deleteEmployee(String docId) async {
    await _employees.doc(docId).delete();
  }

  static Future<void> updateEmployee(
    String docId,
    Map<String, dynamic> patch,
  ) async {
    await _employees.doc(docId).update(patch);
  }
}
