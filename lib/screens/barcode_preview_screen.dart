import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:screenshot/screenshot.dart';

import '../services/firestore_service.dart';

class BarcodePreviewScreen extends StatefulWidget {
  final Map<String, dynamic> employeeData;
  final bool allowSave;

  const BarcodePreviewScreen({
    super.key,
    required this.employeeData,
    this.allowSave = true,
  });

  @override
  State<BarcodePreviewScreen> createState() => _BarcodePreviewScreenState();
}

class _BarcodePreviewScreenState extends State<BarcodePreviewScreen> {
  final ScreenshotController screenshotController = ScreenshotController();
  bool saving = false;
  bool savedToFirestore = false;

  Future<String?> _readImageBase64(String? path) async {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _saveToFirestore() async {
    if (!widget.allowSave) return;
    if (savedToFirestore) return;
    setState(() => saving = true);

    try {
      // Spark plan friendly: store image as base64 in Firestore.
      final imageBase64 = await _readImageBase64(
        widget.employeeData["imagePath"],
      );

      final doc = <String, dynamic>{
        "id": widget.employeeData["employeeId"],
        "employeeId": widget.employeeData["employeeId"],
        "empCode6": widget.employeeData["empCode6"],
        "name": widget.employeeData["name"],
        "role": widget.employeeData["role"],
        "email": widget.employeeData["email"],
        "phone": widget.employeeData["phone"],
        "dob": widget.employeeData["dob"],
        "imageBase64": imageBase64,
      };

      final created = await FirestoreService.upsertEmployeeByEmail(doc);
      if (!mounted) return;
      setState(() => savedToFirestore = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(created ? "Employee created" : "Employee updated"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _exportToGallery() async {
    try {
      final Uint8List? bytes = await screenshotController.capture(
        delay: const Duration(milliseconds: 50),
        pixelRatio: 2.5,
      );
      if (bytes == null) return;
      await Gal.putImageBytes(bytes, name: widget.employeeData["employeeId"]);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ID card saved to gallery")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Export failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.employeeData;

    final name = (data["name"] ?? "").toString();
    final role = (data["role"] ?? "").toString();
    final email = (data["email"] ?? "").toString();
    final phone = (data["phone"] ?? "").toString();
    final dob = (data["dob"] ?? "").toString();
    final employeeId = (data["employeeId"] ?? "").toString();
    final imagePath = (data["imagePath"] ?? "").toString();
    final imageBase64 = (data["imageBase64"] ?? "").toString();
    final imageUrl = (data["imageUrl"] ?? "").toString();
    Uint8List? imageBytes;
    if (imageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(imageBase64);
      } catch (_) {
        imageBytes = null;
      }
    }

    String formatDob(String raw) {
      if (raw.trim().isEmpty) return raw;
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        final d = DateUtils.dateOnly(parsed);
        return "${d.day.toString().padLeft(2, '0')}/"
            "${d.month.toString().padLeft(2, '0')}/"
            "${d.year}";
      }
      // If already like DD/MM/YYYY, keep as-is.
      return raw.split(" ").first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("ID Card Preview")),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.10),
                Colors.white,
                Theme.of(context).colorScheme.primary.withOpacity(0.06),
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Screenshot(
                    controller: screenshotController,
                    child: _PremiumIdCard(
                      name: name,
                      role: role,
                      email: email,
                      phone: phone,
                      dob: formatDob(dob),
                      employeeId: employeeId,
                      imagePath: imagePath.isEmpty ? null : imagePath,
                      imageBytes: imageBytes,
                      imageUrl: imageUrl.isEmpty ? null : imageUrl,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.allowSave) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: saving ? null : _saveToFirestore,
                        icon: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_upload),
                        label: Text(
                          savedToFirestore ? "Saved" : "Save to Firestore",
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _exportToGallery,
                      icon: const Icon(Icons.download),
                      label: const Text("Export ID Card"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumIdCard extends StatelessWidget {
  final String name;
  final String role;
  final String email;
  final String phone;
  final String dob;
  final String employeeId;
  final String? imagePath;
  final Uint8List? imageBytes;
  final String? imageUrl;

  const _PremiumIdCard({
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.dob,
    required this.employeeId,
    this.imagePath,
    this.imageBytes,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoFile = imagePath == null ? null : File(imagePath!);
    final hasBytes = imageBytes != null && imageBytes!.isNotEmpty;
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Layer 1: glassy canvas
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.85),
                      theme.colorScheme.primary.withOpacity(0.08),
                      Colors.white.withOpacity(0.70),
                    ],
                  ),
                ),
              ),
            ),

            // Layer 1.5: watermark logo (behind content)
            Positioned(
              left: 16,
              right: 16,
              top: 80,
              bottom: 120,
              child: Opacity(
                opacity: 0.06,
                child: Image.asset("assets/logo.png", fit: BoxFit.contain),
              ),
            ),

            // Layer 2: content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 38,
                          height: 38,
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          child: Image.asset(
                            "assets/logo.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "She Software Solutions",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipOval(
                    child: Container(
                      width: 140,
                      height: 140,
                      color: Colors.black.withOpacity(0.05),
                      child: (!hasBytes && !hasUrl && photoFile == null)
                          ? const Icon(Icons.person, size: 64)
                          : (hasBytes
                                ? Image.memory(imageBytes!, fit: BoxFit.cover)
                                : (hasUrl
                                      ? Image.network(
                                          imageUrl!,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          photoFile!,
                                          fit: BoxFit.cover,
                                        ))),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(label: "DOB", value: dob),
                  _DetailRow(label: "Email", value: email),
                  _DetailRow(label: "Phone", value: phone),
                  _DetailRow(label: "Employee ID", value: employeeId),
                  const SizedBox(height: 16),
                  BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: employeeId,
                    drawText: false,
                    width: 280,
                    height: 74,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    employeeId,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black.withOpacity(0.7),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black.withOpacity(0.65),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
