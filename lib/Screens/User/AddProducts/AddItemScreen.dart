import 'dart:io';
import 'dart:convert';
import '../../../Model/ItemModel.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AddItemScreen extends StatefulWidget {
  final String itemType;
  final bool isDonation;

  const AddItemScreen({
    super.key,
    required this.itemType,
    required this.isDonation,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseReference _ref = FirebaseDatabase.instance.ref();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String? _base64image;
  bool _isLoading = false;


  final currentUser = FirebaseAuth.instance.currentUser;



  @override
  void initState() {
    super.initState();

    // AUTO-SET PRICE TO "FREE" FOR DONATIONS
    if (widget.isDonation) {
      _priceController.text = "Free";
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = File(pickedFile.path);
        _base64image = base64Encode(bytes);
      });
    }
  }

  void _uploadData() async {
    setState(() => _isLoading = true);

    try {
      String uid = _ref.push().key!;
      String path = widget.isDonation ? 'donations' : 'items';

      ItemModel itemModel = ItemModel(
        productName: _nameController.text,
        productPrice: _priceController.text,
        productDescription: _descriptionController.text,
        image: _base64image ?? '',
        uid: uid,
        itemType: widget.itemType,
        userId: FirebaseAuth.instance.currentUser!.uid,
        timestamp: DateTime.now().millisecondsSinceEpoch, // ✅ add this line
      );


      await _ref.child(path).child(uid).set(itemModel.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.itemType} item added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedImage != null) {
      _uploadData();
    } else if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add ${widget.itemType} Item',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.deepPurple.shade200,
                      width: 1,
                    ),
                  ),
                  child: _selectedImage == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 48,
                        color: Colors.deepPurple.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add image',
                        style: TextStyle(
                          color: Colors.deepPurple.shade400,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.fitHeight,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  prefixIcon: Icon(Icons.shopping_bag, color: Colors.deepPurple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price Field (Disabled for donations)
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                enabled: !widget.isDonation,
                decoration: InputDecoration(
                  labelText: widget.isDonation ? 'Price (Fixed to Free)' : 'Price (Rs.)',
                  prefixIcon: Icon(Icons.money, color: Colors.deepPurple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (!widget.isDonation && double.tryParse(value) == null) {
                    return 'Please enter valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.description, color: Colors.deepPurple),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(
                  'Add ${widget.itemType} Item',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // elevation: 4,
                ),

              ),

              // Donation Info Note
              if (widget.isDonation)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Note: Donated items will be listed for free and cannot be sold',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.deepPurple.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
