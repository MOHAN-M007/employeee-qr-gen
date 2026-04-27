import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadEmployeePhoto({
    required File file,
    required String employeeId,
  }) async {
    final ref = _storage.ref().child("employee_photos/$employeeId.jpg");
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }
}

