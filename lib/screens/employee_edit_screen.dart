import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class EmployeeEditScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EmployeeEditScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<EmployeeEditScreen> createState() => _EmployeeEditScreenState();
}

class _EmployeeEditScreenState extends State<EmployeeEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController roleController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  DateTime? dob;
  File? selectedImage;

  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: (widget.data["name"] ?? "").toString());
    roleController =
        TextEditingController(text: (widget.data["role"] ?? "").toString());
    emailController =
        TextEditingController(text: (widget.data["email"] ?? "").toString());
    phoneController =
        TextEditingController(text: (widget.data["phone"] ?? "").toString());

    final rawDob = (widget.data["dob"] ?? "").toString();
    if (rawDob.isNotEmpty) {
      dob = DateTime.tryParse(rawDob);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    roleController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => selectedImage = File(picked.path));
  }

  Future<void> pickDob() async {
    final now = DateTime.now();
    final initial = dob ?? DateTime(now.year - 22, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime(now.year - 10, now.month, now.day),
    );
    if (picked == null) return;
    setState(() => dob = picked);
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;
    if (dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select Date of Birth")),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final employeeId =
          (widget.data["employeeId"] ?? widget.data["id"] ?? "").toString();

      String? imageUrl = (widget.data["imageUrl"] ?? "").toString();
      if (selectedImage != null && await selectedImage!.exists()) {
        imageUrl = await StorageService.uploadEmployeePhoto(
          file: selectedImage!,
          employeeId: employeeId,
        );
      }

      await FirestoreService.updateEmployee(widget.docId, {
        "name": nameController.text.trim(),
        "role": roleController.text.trim(),
        "email": emailController.text.trim().toLowerCase(),
        "phone": phoneController.text.trim(),
        "dob": DateUtils.dateOnly(dob!).toIso8601String(),
        "imageUrl": imageUrl.isEmpty ? null : imageUrl,
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingUrl = (widget.data["imageUrl"] ?? "").toString();
    ImageProvider? avatar;
    if (selectedImage != null) {
      avatar = FileImage(selectedImage!);
    } else if (existingUrl.isNotEmpty) {
      avatar = NetworkImage(existingUrl);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Employee")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.12),
                        backgroundImage: avatar,
                        child: avatar == null
                            ? const Icon(Icons.person, size: 48)
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.photo),
                        label: const Text("Change Photo"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Enter name" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: roleController,
                  decoration: const InputDecoration(
                    labelText: "Role (Job title)",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Enter role" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? "";
                    if (value.isEmpty) return "Enter email";
                    if (!value.contains("@")) return "Enter valid email";
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? "";
                    if (value.isEmpty) return "Enter phone";
                    if (value.length < 8) return "Enter valid phone";
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: pickDob,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Date of Birth",
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            dob == null
                                ? "Select DOB"
                                : "${dob!.day.toString().padLeft(2, "0")}/"
                                    "${dob!.month.toString().padLeft(2, "0")}/"
                                    "${dob!.year}",
                          ),
                        ),
                        const Icon(Icons.calendar_month),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: saving ? null : save,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text("Save Changes"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
