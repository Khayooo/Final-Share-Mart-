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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _uploadFile(String fieldName) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
        withData: true, // Ensure bytes are loaded
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        // Check file size before processing
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File size must be less than 5MB')),
            );
          }
          return;
        }

        Uint8List? bytes;

        // Try to get bytes from the file
        if (file.bytes != null) {
          bytes = file.bytes!;
        } else if (file.path != null) {
          try {
            File ioFile = File(file.path!);
            bytes = await ioFile.readAsBytes();
          } catch (e) {
            print('Error reading file from path: $e');
          }
        }

        if (bytes != null) {
          _updateFileState(fieldName, bytes, file.name);
        } else {
          throw Exception('Could not load file bytes');
        }
      }
    } catch (e) {
      print('File picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: ${e.toString()}')),
        );
      }
    }
  }

  void _updateFileState(String fieldName, Uint8List bytes, String fileName) {
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

    print('File updated: $fieldName - ${fileName} (${bytes.length} bytes)');
  }

  String? _encodeFile(Uint8List? bytes) {
    if (bytes == null) return null;
    try {
      return base64Encode(bytes);
    } catch (e) {
      print('Error encoding file to base64: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    print('Submit form called');

    if (_isSubmitting) {
      print('Already submitting, returning');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    if (_characterCertificateBytes == null) {
      print('Character certificate is missing');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Character certificate is required')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();

    try {
      print('Starting form submission...');

      // Encode files to Base64
      final characterBase64 = _encodeFile(_characterCertificateBytes);
      final disabilityBase64 = _encodeFile(_disabilityCardBytes);
      final studentBase64 = _encodeFile(_studentCardBytes);

      if (characterBase64 == null) {
        throw Exception('Failed to encode character certificate');
      }

      print('Files encoded successfully');

      // Get reference to Realtime Database
      final databaseRef = FirebaseDatabase.instance.ref();
      final donorRef = databaseRef.child('donor_verifications').push();

      print('Database reference created: ${donorRef.key}');

      // Prepare data object
      Map<String, dynamic> donorData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'cnic': _cnicController.text.trim(),
        'address': _addressController.text.trim(),
        'character_certificate': characterBase64,
        'timestamp': ServerValue.timestamp,
        'status': 'pending',
        'key': donorRef.key,
      };

      // Add optional files only if they exist
      if (disabilityBase64 != null) {
        donorData['disability_card'] = disabilityBase64;
      }
      if (studentBase64 != null) {
        donorData['student_card'] = studentBase64;
      }

      print('Pushing data to Firebase...');

      // Save data to Realtime Database
      await donorRef.set(donorData);

      print('Data pushed successfully');

      // Clear form only after successful submission
      if (mounted) {
        _formKey.currentState!.reset();
        _clearControllers();
        setState(() {
          _characterCertificateBytes = null;
          _disabilityCardBytes = null;
          _studentCardBytes = null;
          _characterCertificateName = null;
          _disabilityCardName = null;
          _studentCardName = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Submission error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _clearControllers() {
    _nameController.clear();
    _phoneController.clear();
    _cnicController.clear();
    _addressController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donor Verification'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
                const Text(
                  'Please fill all required fields and upload necessary documents',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name*',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number*',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    hintText: '03XXXXXXXXX',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (value.trim().length < 10) {
                      return 'Invalid phone number';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _cnicController,
                  decoration: const InputDecoration(
                    labelText: 'CNIC*',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                    hintText: 'XXXXX-XXXXXXX-X',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'CNIC is required';
                    }
                    // Remove dashes and check length
                    String cleanCnic = value.replaceAll('-', '');
                    if (cleanCnic.length != 13) {
                      return 'CNIC must be 13 digits';
                    }
                    return null;
                  },
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Address is required';
                    }
                    if (value.trim().length < 10) {
                      return 'Please provide a complete address';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),

                const Divider(),
                const Text(
                  'Document Upload',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _buildFileUpload('Character Certificate*', _characterCertificateName, 'character', isRequired: true),
                const SizedBox(height: 16),
                _buildFileUpload('Disability Card (optional)', _disabilityCardName, 'disability'),
                const SizedBox(height: 16),
                _buildFileUpload('Student Card (if applicable)', _studentCardName, 'student'),
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.upload_file, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Verification',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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

  Widget _buildFileUpload(String title, String? fileName, String fieldName, {bool isRequired = false}) {
    bool hasFile = fileName != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isRequired ? Colors.black : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            side: BorderSide(
              color: hasFile ? Colors.green : (isRequired ? Colors.blue : Colors.grey),
              width: hasFile ? 2 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _uploadFile(fieldName),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasFile ? Icons.check_circle : Icons.upload_file,
                color: hasFile ? Colors.green : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                hasFile ? 'File Selected' : 'Choose File',
                style: TextStyle(
                  color: hasFile ? Colors.green : Colors.grey.shade600,
                  fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        if (hasFile)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file, size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}