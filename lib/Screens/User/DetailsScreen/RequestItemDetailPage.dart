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
        title: const Text("Requested Item Detail"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['name'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              item['description'] ?? '',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text("Type: ${item['type']}"),
            const SizedBox(height: 8),
            Text("Posted on: $date"),
            const Spacer(),

            if (item['userId'] != currentUserId)
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.chat,
                      label: "Chat",
                      color: Colors.deepPurple,
                      onPressed: () {

print(item );
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
