import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class ProfileInformationScreen extends StatefulWidget {
  final Map<String, String> userData;
  final Function(Map<String, String>) onSave;

  const ProfileInformationScreen({
    super.key,
    required this.userData,
    required this.onSave,
  });

  @override
  State<ProfileInformationScreen> createState() => _ProfileInformationScreenState();
}

class _ProfileInformationScreenState extends State<ProfileInformationScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  File? _profileImage;
  String? _profileImageBase64;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name'] ?? "");
    _emailController = TextEditingController(text: widget.userData['email'] ?? "");
    _phoneController = TextEditingController(text: widget.userData['phone'] ?? "");
    _addressController = TextEditingController(text: widget.userData['address'] ?? "");
    _profileImageBase64 = widget.userData['profileImage'];

    // Load user data from Realtime Database
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _database.ref('users/${user.uid}').get();
        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          setState(() {
            _nameController.text = data['name'] ?? '';
            // Use Firebase Auth email as fallback if database email is empty
            _emailController.text = data['email']?.isNotEmpty == true
                ? data['email']
                : (user.email ?? '');
            _phoneController.text = data['phone'] ?? '';
            _addressController.text = data['address'] ?? '';
            _profileImageBase64 = data['profileImage'];
          });
        } else {
          // If no data exists in database, use Firebase Auth email
          setState(() {
            _emailController.text = user.email ?? '';
          });
        }
      }
    } catch (e) {
      _showErrorMessage('Failed to load profile data: ${e.toString()}');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Reduced quality to keep base64 size manageable
        maxWidth: 500,
        maxHeight: 500,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });

        // Convert image to base64
        await _convertImageToBase64();
      }
    } catch (e) {
      _showErrorMessage('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _convertImageToBase64() async {
    if (_profileImage == null) return;

    try {
      final Uint8List imageBytes = await _profileImage!.readAsBytes();
      final String base64String = base64Encode(imageBytes);

      setState(() {
        _profileImageBase64 = base64String;
      });
    } catch (e) {
      _showErrorMessage('Failed to process image: ${e.toString()}');
    }
  }

  Future<void> _saveProfileToDatabase(Map<String, dynamic> profileData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showErrorMessage('User not authenticated');
        return;
      }

      final userRef = _database.ref('users/${user.uid}');

      await userRef.set({
        ...profileData,
        'updatedAt': ServerValue.timestamp,
        'userId': user.uid,
      });

    } catch (e) {
      _showErrorMessage('Failed to save profile: ${e.toString()}');
      rethrow;
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile Information",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.save, color: Colors.white),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          children: [
            // Profile Picture with Image Picker
            Center(
              child: GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepPurple.shade100,
                        image: _getProfileImage(),
                      ),
                      child: _getProfileImage() == null
                          ? Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.deepPurple,
                      )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form Fields
            _buildFormField(
              label: "Full Name",
              icon: Icons.person,
              controller: _nameController,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              label: "Email Address",
              icon: Icons.email,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              label: "Phone Number",
              icon: Icons.phone,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              label: "Address",
              icon: Icons.location_on,
              controller: _addressController,
              maxLines: 2,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isLoading
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text("Saving..."),
                  ],
                )
                    : const Text(
                  "Save Changes",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DecorationImage? _getProfileImage() {
    if (_profileImage != null) {
      return DecorationImage(
        image: FileImage(_profileImage!),
        fit: BoxFit.cover,
      );
    } else if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(_profileImageBase64!);
        return DecorationImage(
          image: MemoryImage(bytes),
          fit: BoxFit.cover,
        );
      } catch (e) {
        // If base64 decoding fails, return null
        return null;
      }
    }
    return null;
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade50,
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        if (_profileImageBase64 != null) 'profileImage': _profileImageBase64!,
      };

      // Save to Realtime Database
      await _saveProfileToDatabase(updatedData);

      // Update local state
      widget.onSave(updatedData.map((key, value) => MapEntry(key, value.toString())));

      _showSuccessMessage("Profile updated successfully!");
      Navigator.pop(context);
    } catch (e) {
      _showErrorMessage("Failed to save profile: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}