import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String userId;


  const ChatScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    // Use recipientId to fetch/store messages in Firebase
    // Use recipientName for header display
    return Scaffold(
      appBar: AppBar(
        title: Text(userId),
      ),
      body: Center(
        child: Text("Akhtar  lava "),
      ),
    );
  }
}
