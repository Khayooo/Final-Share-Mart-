import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../Model/ExchangeItemModel.dart';
import '../Chat/ChatWithUserScreen.dart';

class ExchangeItemDetailScreen extends StatefulWidget {
  final ExchangeItemModel item;
  final String currentUserId;

  const ExchangeItemDetailScreen({
    Key? key,
    required this.item,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<ExchangeItemDetailScreen> createState() => _ExchangeItemDetailScreenState();
}

class _ExchangeItemDetailScreenState extends State<ExchangeItemDetailScreen> {
  Map<String, dynamic>? _exchangerData;
  bool _isLoadingExchanger = true;

  @override
  void initState() {
    super.initState();
    _fetchExchangerInfo(widget.item.userId);
  }

  Future<void> _fetchExchangerInfo(String userId) async {
    try {
      final ref = FirebaseDatabase.instance.ref().child("users").child(userId);
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value is Map) {
        setState(() {
          _exchangerData = Map<String, dynamic>.from(snapshot.value as Map);
          _isLoadingExchanger = false;
        });
      } else {
        setState(() {
          _exchangerData = null;
          _isLoadingExchanger = false;
        });
      }
    } catch (e) {
      print("Error fetching exchanger info: $e");
      setState(() {
        _exchangerData = null;
        _isLoadingExchanger = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMd().add_jm().format(
      DateTime.fromMillisecondsSinceEpoch(widget.item.timestamp),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Exchange Item Details",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            if (widget.item.productImage.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  base64Decode(widget.item.productImage),
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text("No Image Available"),
              ),

            const SizedBox(height: 16),

            _infoRow('Posted on:', formattedDate),
            const Divider(height: 30),

            _infoRow('Product Name:', widget.item.productName),
            _infoRow('Product Description:', widget.item.productDescription),
            const Divider(height: 30),

            _infoRow('Wants to Exchange With:', widget.item.desiredProductName),
            _infoRow('Exchange Product Description:', widget.item.desiredProductDescription),
            const Divider(height: 30),

            _infoRow('Status:', widget.item.status),

            const SizedBox(height: 24),

            // Exchanger Information
            Text(
              "Exchanger's Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade800,
              ),
            ),
            const SizedBox(height: 12),
            _isLoadingExchanger
                ? const Center(child: CircularProgressIndicator())
                : _exchangerData == null
                ? const Text("Exchanger information not available.")
                : _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow("Name:", _exchangerData!['name'] ?? "N/A"),
                  _infoRow("Email:", _exchangerData!['email'] ?? "N/A"),
                  _infoRow("Address:", _exchangerData!['address'] ?? "No Address Saved"),
                  _infoRow("Phone:", _exchangerData!['phone'] ?? "No Phone Number"),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            if (widget.item.userId != widget.currentUserId)
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
                              currentUserId: widget.currentUserId,
                              receiverId: widget.item.userId,
                              itemType: 'exchange',
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
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
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
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
