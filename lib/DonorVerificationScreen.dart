import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:file_picker/file_picker.dart';

class DonorVerificationScreen extends StatefulWidget {
  const DonorVerificationScreen({super.key});

  @override
  State<DonorVerificationScreen> createState() => _DonorVerificationScreenState();
}

class _DonorVerificationScreenState extends State<DonorVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  Uint8List? _characterCertificateBytes;
  Uint8List? _disabilityCardBytes;
  Uint8List? _studentCardBytes;
  String? _characterCertificateName;
  String? _disabilityCardName;
  String? _studentCardName;
  bool _isSubmitting = false;

  Future<void> _uploadFile(String fieldName) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        // Check if we have valid bytes
        if (file.bytes == null) {
          // If bytes are null, try to read from path
          if (file.path != null) {
            File ioFile = File(file.path!);
            Uint8List bytes = await ioFile.readAsBytes();
            _updateFileState(fieldName, bytes, file.name);
          } else {
            throw Exception('Could not load file bytes');
          }
        } else {
          _updateFileState(fieldName, file.bytes!, file.name);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      print('File picker error: $e');
    }
  }

  void _updateFileState(String fieldName, Uint8List bytes, String fileName) {
    if (bytes.length > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File size must be less than 5MB')),
      );
      return;
    }

    setState(() {
      switch (fieldName) {
        case 'character':
          _characterCertificateBytes = bytes;
          _characterCertificateName = fileName;
          break;
        case 'disability':
          _disabilityCardBytes = bytes;
          _disabilityCardName = fileName;
          break;
        case 'student':
          _studentCardBytes = bytes;
          _studentCardName = fileName;
          break;
      }
    });
  }

  String? _encodeFile(Uint8List? bytes) {
    if (bytes == null) return null;
    return base64Encode(bytes);
  }

  Future<void> _submitForm() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    if (_characterCertificateBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Character certificate is required')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();

    try {
      // Encode files to Base64
      final characterBase64 = _encodeFile(_characterCertificateBytes);
      final disabilityBase64 = _encodeFile(_disabilityCardBytes);
      final studentBase64 = _encodeFile(_studentCardBytes);

      // Get reference to Realtime Database
      final databaseRef = FirebaseDatabase.instance.ref();
      final donorRef = databaseRef.child('donor_verifications').push();

      // Save data to Realtime Database
      await donorRef.set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'cnic': _cnicController.text.trim(),
        'address': _addressController.text.trim(),
        'character_certificate': characterBase64,
        'disability_card': disabilityBase64,
        'student_card': studentBase64,
        'timestamp': ServerValue.timestamp,
        'status': 'pending',
        'key': donorRef.key,
      });

      // Clear form
      _formKey.currentState!.reset();
      setState(() {
        _characterCertificateBytes = null;
        _disabilityCardBytes = null;
        _studentCardBytes = null;
        _characterCertificateName = null;
        _disabilityCardName = null;
        _studentCardName = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission successful!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      print('Submission error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donor Verification'),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name*',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required field' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number*',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.length < 10 ? 'Invalid number' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cnicController,
                  decoration: const InputDecoration(
                    labelText: 'CNIC*',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  validator: (value) => value!.length < 13 ? 'Invalid CNIC' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address*',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 3,
                  validator: (value) => value!.isEmpty ? 'Required field' : null,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),
                _buildFileUpload('Character Certificate*', _characterCertificateName, 'character'),
                const SizedBox(height: 16),
                _buildFileUpload('Disability Card (optional)', _disabilityCardName, 'disability'),
                const SizedBox(height: 16),
                _buildFileUpload('Student Card (if applicable)', _studentCardName, 'student'),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: _isSubmitting
                      ? const SizedBox.shrink()
                      : const Icon(Icons.upload_file, color: Colors.white),
                  label: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Verification'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: _isSubmitting ? null : _submitForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileUpload(String title, String? fileName, String fieldName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () => _uploadFile(fieldName),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.upload_file, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                fileName == null ? 'Choose File' : 'File Selected',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        if (fileName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              fileName,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500
              ),
            ),
          ),
      ],
    );
  }
}