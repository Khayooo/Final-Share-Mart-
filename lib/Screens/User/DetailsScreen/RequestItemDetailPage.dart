import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Chat/ChatWithUserScreen.dart';

class RequestedItemDetailPage extends StatelessWidget {
  final Map<dynamic, dynamic> item;

  const RequestedItemDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final DateTime date = DateTime.fromMillisecondsSinceEpoch(
      int.tryParse(item['timestamp'].toString()) ?? 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Requested Item Detail",
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF3E5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name
            Text(
              item['name'] ?? '',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.description, color: Colors.deepPurple),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

// ✅ Add Container with border around description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple), // Border color
                borderRadius: BorderRadius.circular(8), // Rounded corners
                color: Colors.deepPurple.withOpacity(0.05), // Light background
              ),
              child: Text(
                item['description'] ?? 'No description available.',
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 24),


            // Posted On
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  "Posted on: ${date.toLocal()}",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const Spacer(),

            // Action Buttons (if not owner)
            if (item['userId'] != currentUserId)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Contact Options",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                                  receiverId: item['userId'],
                                  itemType: item['itemType'] ?? 'Unknown',
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
                            // TODO: Implement call functionality
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: 24),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
