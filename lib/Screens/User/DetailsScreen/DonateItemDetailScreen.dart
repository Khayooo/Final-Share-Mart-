import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../../Model/DonateItemModel.dart';
import '../Chat/ChatWithUserScreen.dart';

class DonateItemDetailScreen extends StatefulWidget {
  final DonateItemModel item;

  const DonateItemDetailScreen({super.key, required this.item});

  @override
  State<DonateItemDetailScreen> createState() => _DonateItemDetailScreenState();
}

class _DonateItemDetailScreenState extends State<DonateItemDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Map<String, dynamic>? _donorData;
  bool _isLoadingDonor = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _fetchDonorInfo(widget.item.userId);
  }

  Future<void> _fetchDonorInfo(String donorId) async {
    try {
      final ref = FirebaseDatabase.instance.ref().child("users").child(donorId);
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value is Map) {
        setState(() {
          _donorData = Map<String, dynamic>.from(snapshot.value as Map);
          _isLoadingDonor = false;
        });
      } else {
        setState(() {
          _donorData = null;
          _isLoadingDonor = false;
        });
      }
    } catch (e) {
      print("Error fetching donor info: $e");
      setState(() {
        _donorData = null;
        _isLoadingDonor = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          "Donate Item Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Hero(
                  tag: widget.item.uid,
                  child: Container(
                    height: isSmallScreen ? 250 : 350,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.1),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        base64Decode(widget.item.image),
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  widget.item.productName,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                _buildSectionHeader("Description"),
                const SizedBox(height: 12),
                _buildCard(
                  child: Text(
                    widget.item.productDescription,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),

                // Price
                _buildSectionHeader("Price"),
                const SizedBox(height: 12),
                _buildCard(
                  child: Text(
                    widget.item.productPrice,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24),

                // Donor's Information
                _buildSectionHeader("Donor's Information"),
                const SizedBox(height: 12),
                _isLoadingDonor
                    ? const Center(child: CircularProgressIndicator())
                    : _donorData == null
                    ? const Text("Donor information not available.")
                    : _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow("Name", _donorData!['name'] ?? "N/A"),
                      const SizedBox(height: 12),
                      _buildInfoRow("Email", _donorData!['email'] ?? "N/A"),
                      const SizedBox(height: 12),
                      _buildInfoRow("Address", _donorData!['address'] ?? "No Address Saved"),
                      const SizedBox(height: 12),
                      _buildInfoRow("Phone", _donorData!['phone'] ?? "No Phone Number"),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                if (widget.item.userId != currentUserId)
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.chat,
                          label: "Chat",
                          color: Colors.deepPurple,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatWithUserScreen(
                                  currentUserId: currentUserId,
                                  receiverId: widget.item.userId,
                                  itemType: widget.item.itemType ?? 'Unknown',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.sms,
                          label: "SMS",
                          color: Colors.blue,
                          onPressed: () {
                            // Implement SMS
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.call,
                          label: "Call",
                          color: Colors.green,
                          onPressed: () {
                            // Implement Call
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(
    title,
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.deepPurple.shade800,
    ),
  );

  Widget _buildInfoRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 80,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    ],
  );

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) =>
      ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _buildCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}