import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatDetailScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhone;

  const ChatDetailScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhone,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  late String _chatId;

  @override
  void initState() {
    super.initState();
    _chatId = _generateChatId(_auth.currentUser!.uid, widget.otherUserId);
  }

  String _generateChatId(String user1, String user2) {
    List<String> ids = [user1, user2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  void _sendMessage({String type = 'text', String? imageBase64}) {
    String messageId = _dbRef.child('chats/$_chatId').push().key!;
    _dbRef.child('chats/$_chatId/$messageId').set({
      'senderId': _auth.currentUser!.uid,
      'type': type,
      'content': type == 'text' ? _messageController.text : imageBase64,
      'timestamp': ServerValue.timestamp,
    });
    _messageController.clear();
  }

  Future<void> _sendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    List<int> bytes = await image.readAsBytes();
    String base64Image = base64Encode(bytes);
    _sendMessage(type: 'image', imageBase64: base64Image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => launchUrl(Uri.parse('tel:${widget.otherUserPhone}')),
          ),
        ],
      ),
      body: Column(
          children: [
      Expanded(
      child: StreamBuilder(
      stream: _dbRef.child('chats/$_chatId').orderByChild('timestamp').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        Map<dynamic, dynamic> messages =
        (snapshot.data!.snapshot.value as Map? ?? {});
        List<MapEntry> sortedMessages = messages.entries.toList()
          ..sort((a, b) => b.value['timestamp'].compareTo(a.value['timestamp']));

        return ListView.builder(
          reverse: true,
          itemCount: sortedMessages.length,
          itemBuilder: (context, index) {
            final message = sortedMessages[index].value;
            final bool isMe = message['senderId'] == _auth.currentUser!.uid;

            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? Colors.deepPurple : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: message['type'] == 'text'
                    ? Text(message['content'],
                    style: TextStyle(color: isMe ? Colors.white : Colors.black))
                    : Image.memory(base64Decode(message['content'])),
              ),
            );
          },
        );
      },
    ),
    ),
    Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
    children: [
    IconButton(
    icon: const Icon(Icons.image),
    onPressed: _sendImage,
    ),
    Expanded(
    child: TextField(
    controller: _messageController,
    decoration: InputDecoration(
    hintText: 'Type a message...',
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    ),
    ),
    ),
    ),
      IconButton(
        icon: Icon(Icons.send),
        onPressed: (){},
      ),
    ],
    ),
    ),
    ],
    ),
    );
  }
}