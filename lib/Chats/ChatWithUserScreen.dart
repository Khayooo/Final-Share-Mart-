import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ChatWithUserScreen extends StatefulWidget {
  final String currentUserId;
  final String receiverId;

  const ChatWithUserScreen({
    Key? key,
    required this.currentUserId,
    required this.receiverId,
  }) : super(key: key);

  @override
  State<ChatWithUserScreen> createState() => _ChatWithUserScreenState();
}

class _ChatWithUserScreenState extends State<ChatWithUserScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Stream<QuerySnapshot>? chatStream;

  String receiverName = '';
  bool isLoadingReceiver = true;

  @override
  void initState() {
    super.initState();

    _fetchReceiverData();

    final chatId = getChatId(widget.currentUserId, widget.receiverId);
    chatStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  // 🔍 Fetch receiver's data from Realtime Database
  Future<void> _fetchReceiverData() async {
    try {

      final snapshot = await FirebaseDatabase.instance
          .ref('users/${widget.receiverId}')
          .once();


      final rawData = snapshot.snapshot.value;

      if (rawData != null && rawData is Map) {
        final data = rawData;

        setState(() {
          receiverName = data['name'] ?? 'User';
          isLoadingReceiver = false;
        });

      } else {
        print("⚠️ No user data found at users/${widget.receiverId}");
      }
    } catch (e) {
      print('❌ Error fetching user data: $e');
    }
  }

  String getChatId(String id1, String id2) {
    return id1.hashCode <= id2.hashCode ? '$id1-$id2' : '$id2-$id1';
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatId = getChatId(widget.currentUserId, widget.receiverId);

    try {
      final newMessage = {
        'senderId': widget.currentUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(newMessage);

// ✅ Also update the parent chat document with the latest message
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set({
        'participants': {
          widget.currentUserId: true,
          widget.receiverId: true,
        },
        'lastMessage': text,
        'timestamp': FieldValue.serverTimestamp(), // This makes ChatList auto-refresh
      }, SetOptions(merge: true));


      _messageController.clear();

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

    } catch (e) {
      print('❌ Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.currentUserId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: isLoadingReceiver
            ? const Text("Loading...")
            : Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                receiverName.isNotEmpty
                    ? receiverName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.deepPurple),
              ),
            ),
            const SizedBox(width: 10),
            Text(receiverName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Say hi 👋"));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUser;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth:
                          MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color:
                          isMe ? const Color(0xFFDCF8C6) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          msg['text'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.deepPurple),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
