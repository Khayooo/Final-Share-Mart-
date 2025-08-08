import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../Model/ExchangeItemModel.dart';
import '../Chat/ChatWithUserScreen.dart';

class ExchangeItemDetailScreen extends StatelessWidget {
  final ExchangeItemModel item;
  final String currentUserId;

  const ExchangeItemDetailScreen({
    Key? key,
    required this.item,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMd().add_jm().format(
      DateTime.fromMillisecondsSinceEpoch(item.timestamp),
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
            if (item.productImage.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  base64Decode(item.productImage),
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

            _infoRow('Product Name:', item.productName),
            _infoRow('Product Description:', item.productDescription),
            const Divider(height: 30),

            _infoRow('Wants to Exchange With:', item.desiredProductName),
            _infoRow('Exchange Product Description:', item.desiredProductDescription),
            const Divider(height: 30),

            _infoRow('Status:', item.status),

            const SizedBox(height: 32),

            // Action Buttons (only show if it's not the user's own post)
            if (item.userId != currentUserId)
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
                              receiverId: item.userId,
                              itemType: 'exchange', // static type for this screen
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
                        // TODO: Implement SMS functionality
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
                        // TODO: Implement Call functionality
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
          Text(
            '$title ',
            style: const TextStyle(fontWeight: FontWeight.bold),
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