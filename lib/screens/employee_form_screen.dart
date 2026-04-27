import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'barcode_preview_screen.dart';

class EmployeeFormScreen extends StatefulWidget {
  const EmployeeFormScreen({super.key});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final jobTitleController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  DateTime? dob;
  File? selectedImage;

  @override
  void dispose() {
    nameController.dispose();
    jobTitleController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
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

  String _generateEmployeeId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return "EMP$ts";
  }

  void submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select Date of Birth")),
      );
      return;
    }

    final employeeId = _generateEmployeeId();
    final payload = <String, dynamic>{
      "id": employeeId,
      "employeeId": employeeId,
      "name": nameController.text.trim(),
      "role": jobTitleController.text.trim(),
      "email": emailController.text.trim().toLowerCase(),
      "phone": phoneController.text.trim(),
      "dob": DateUtils.dateOnly(dob!).toIso8601String(),
      "imagePath": selectedImage?.path,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodePreviewScreen(employeeData: payload),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Employee")),
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
                        backgroundImage:
                            selectedImage != null ? FileImage(selectedImage!) : null,
                        child: selectedImage == null
                            ? const Icon(Icons.person, size: 48)
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.photo),
                        label: const Text("Upload Photo"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Enter name" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: jobTitleController,
                  textInputAction: TextInputAction.next,
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
                  textInputAction: TextInputAction.next,
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
                  textInputAction: TextInputAction.done,
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
                  child: ElevatedButton(
                    onPressed: submitForm,
                    child: const Text("Preview ID Card"),
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

