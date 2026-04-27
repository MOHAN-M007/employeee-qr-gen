import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'barcode_preview_screen.dart';

class HistoryScreen extends StatefulWidget {
  final String userRole;

  const HistoryScreen({super.key, required this.userRole});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String searchQuery = "";

  bool get isAdmin => widget.userRole.trim().toLowerCase() == "admin";

  void _showEditDialog({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final nameController = TextEditingController(text: (data["name"] ?? "").toString());
    final roleController = TextEditingController(text: (data["role"] ?? "").toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Employee"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: roleController,
              decoration: const InputDecoration(labelText: "Role"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirestoreService.updateEmployee(docId, {
                "name": nameController.text.trim(),
                "role": roleController.text.trim(),
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Employee"),
        content: const Text("Are you sure you want to delete this record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirestoreService.deleteEmployee(docId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _openPreview(Map<String, dynamic> data) {
    // Reuse the same preview screen as a read-only viewer.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodePreviewScreen(
          allowSave: false,
          employeeData: {
            "employeeId": data["employeeId"] ?? data["id"] ?? "",
            "name": data["name"] ?? "",
            "role": data["role"] ?? "",
            "email": data["email"] ?? "",
            "phone": data["phone"] ?? "",
            "dob": data["dob"] ?? "",
            // If record has base64 image we pass it through as a temp field.
            "imageBase64": data["imageBase64"],
            // keep imagePath empty so preview can still render.
            "imagePath": "",
          },
        ),
      ),
    );
  }

  Uint8List? _decodeBase64(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    try {
      return base64Decode(s);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employees"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search by name or ID",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() => searchQuery = value.trim().toLowerCase());
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirestoreService.getEmployees(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading employees"));
                  }
                  final docs = snapshot.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const Center(child: Text("No employee records found"));
                  }

                  final filtered = docs.where((d) {
                    final data = d.data();
                    final name = (data["name"] ?? "").toString().toLowerCase();
                    final id = (data["employeeId"] ?? data["id"] ?? "")
                        .toString()
                        .toLowerCase();
                    return name.contains(searchQuery) || id.contains(searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text("No matching results"));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final data = doc.data();
                      final employeeId = (data["employeeId"] ?? data["id"] ?? "")
                          .toString();
                      final name = (data["name"] ?? "").toString();
                      final role = (data["role"] ?? "").toString();
                      final imgBytes = _decodeBase64(data["imageBase64"]);

                      return Material(
                        color: Colors.white,
                        elevation: 1.5,
                        shadowColor: Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          onTap: () => _openPreview(data),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.12),
                            backgroundImage:
                                imgBytes == null ? null : MemoryImage(imgBytes),
                            child: imgBytes == null
                                ? const Icon(Icons.badge)
                                : null,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(role),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                employeeId,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 6),
                              if (isAdmin)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: "Edit",
                                      onPressed: () => _showEditDialog(
                                        docId: doc.id,
                                        data: data,
                                      ),
                                      icon: const Icon(Icons.edit),
                                    ),
                                    IconButton(
                                      tooltip: "Delete",
                                      onPressed: () => _confirmDelete(doc.id),
                                      icon: const Icon(Icons.delete),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
