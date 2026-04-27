import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;

  static Future<String> getUserRole(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();

      // Preferred schema (per spec): docId = email, fields: { role: "admin"|"user" }
      final docSnap = await _db.collection("users").doc(cleanEmail).get();
      if (docSnap.exists) {
        final data = docSnap.data() ?? <String, dynamic>{};
        final role = (data["role"] ?? "user").toString().trim().toLowerCase();
        return role.isEmpty ? "user" : role;
      }

      // Backward-compatible fallback: docs contain an `email` field.
      final query = await _db
          .collection("users")
          .where("email", isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        final role = (data["role"] ?? "user").toString().trim().toLowerCase();
        return role.isEmpty ? "user" : role;
      }

      return "user";
    } catch (e) {
      print("User role fetch error: $e");
      return "user";
    }
  }
}

