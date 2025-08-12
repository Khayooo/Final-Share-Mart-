import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  bool _isSending = false;

  Future<void> _sendNotificationToAllUsers() async {
    String message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a message")),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Fetch all users
      DatabaseReference usersRef = _dbRef.child("users");
      DataSnapshot snapshot = await usersRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;

        for (var entry in users.entries) {
          String receiverId = entry.key;

          String newNotificationId = _dbRef.child("notifications").push().key!;

          await _dbRef.child("notifications").child(newNotificationId).set({
            "id": newNotificationId,
            "isRead": false,
            "itemType": "Admin",
            "message": message,
            "productId": "",
            "receiverId": receiverId,
            "senderId": currentUserId,
            "timestamp": DateTime.now().millisecondsSinceEpoch,
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notification sent to all users")),
        );
        _messageController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No users found")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() {
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Notifications"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Notification Message",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSending ? null : _sendNotificationToAllUsers,
              icon: const Icon(Icons.send),
              label: Text(_isSending ? "Sending..." : "Send Notification"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}