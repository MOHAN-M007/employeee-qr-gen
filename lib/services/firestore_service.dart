import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _employees =>
      _db.collection("employees");

  static Future<void> addEmployee(Map<String, dynamic> employee) async {
    await _employees.add(employee);
  }

  // Prevent duplicate employees: use email (lowercase) as the document id.
  // Returns true if this created a new record, false if it updated an existing one.
  static Future<bool> upsertEmployeeByEmail(
    Map<String, dynamic> employee,
  ) async {
    final email = (employee["email"] ?? "").toString().trim().toLowerCase();
    if (email.isEmpty) {
      throw ArgumentError("Employee email is required");
    }

    final ref = _employees.doc(email);
    final snap = await ref.get();
    final isNew = !snap.exists;

    final payload = <String, dynamic>{
      ...employee,
      "email": email,
      "timestamp": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    };

    if (isNew) {
      payload["createdAt"] = FieldValue.serverTimestamp();
    } else {
      // Don't let UI accidentally overwrite createdAt on updates.
      payload.remove("createdAt");
    }

    await ref.set(payload, SetOptions(merge: true));
    return isNew;
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
