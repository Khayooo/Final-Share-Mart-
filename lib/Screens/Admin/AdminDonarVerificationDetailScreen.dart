import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';

class AdminDonarVerificationDetailScreen extends StatefulWidget {
  final String donorId;
  final Map<String, dynamic> donor;

  const AdminDonarVerificationDetailScreen({
    super.key,
    required this.donorId,
    required this.donor,
  });

  @override
  State<AdminDonarVerificationDetailScreen> createState() =>
      _AdminDonarVerificationDetailScreenState();
}

class _AdminDonarVerificationDetailScreenState
    extends State<AdminDonarVerificationDetailScreen> {
  late String status;
  final DatabaseReference dbRef =
  FirebaseDatabase.instance.ref("donor_verifications");

  @override
  void initState() {
    super.initState();
    status = widget.donor['status'] ?? "pending";
  }

  Future<void> updateStatus(String newStatus) async {
    await dbRef.child(widget.donorId).update({"status": newStatus});
    setState(() => status = newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Status updated to $newStatus")),
    );
  }

  Future<void> _openPdf(String base64Data, String fileName) async {
    try {
      Uint8List bytes = base64Decode(base64Data);
      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/$fileName.pdf");
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    } catch (e) {
      debugPrint("Error opening PDF: $e");
    }
  }

  Widget buildDocumentTile(String title, String? base64Data) {
    if (base64Data == null || base64Data.isEmpty) {
      return ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("No document uploaded"),
      );
    }

    try {
      Uint8List bytes = base64Decode(base64Data);
      bool isPdf = bytes.length > 4 &&
          bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46;

      if (isPdf) {
        return ListTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text("PDF Document"),
          trailing: IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            onPressed: () => _openPdf(base64Data, title.replaceAll(" ", "")),
          ),
        );
      } else {
        return ListTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Image.memory(bytes, height: 150),
        );
      }
    } catch (e) {
      return ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Invalid file format"),
      );
    }
  }

  Widget buildInfoTile(String title, String value) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final donor = widget.donor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Donor Details"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildInfoTile("Name", donor["name"] ?? ""),
            buildInfoTile("Phone", donor["phone"] ?? ""),
            buildInfoTile("Address", donor["address"] ?? ""),
            buildInfoTile("CNIC", donor["cnic"] ?? ""),
            buildInfoTile("User ID", donor["userId"] ?? ""),
            buildInfoTile("Status", status),
            const Divider(),
            buildDocumentTile("Character Certificate", donor["character_certificate"]),
            buildDocumentTile("Disability Card", donor["disability_card"]),
            buildDocumentTile("Student Card", donor["student_card"]),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => updateStatus("approved"),
                  icon: const Icon(Icons.check),
                  label: const Text("Approve"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: () => updateStatus("rejected"),
                  icon: const Icon(Icons.close),
                  label: const Text("Reject"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}