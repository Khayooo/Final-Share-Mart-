import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 📌 Added

class ChatWithUserScreen extends StatefulWidget {
  final String currentUserId;
  final String receiverId;
  final String itemType;

  const ChatWithUserScreen({
    Key? key,
    required this.currentUserId,
    required this.receiverId,
    required this.itemType,
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
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final chatId = getChatId(widget.currentUserId, widget.receiverId, widget.itemType);

    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();

    if (chatDoc.exists) {
      final existingItemType = chatDoc.data()?['itemType'];
      if (existingItemType == widget.itemType) {
        print("✅ Chat already exists with same itemType");
      } else {
        print("🆕 Same users, different itemType — treating as new conversation");
      }
    } else {
      print("🆕 New chat will be created on message send.");
    }

    setState(() {
      chatStream = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp')
          .snapshots();
    });
  }

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
        print("⚠️ No user data found");
      }
    } catch (e) {
      print('❌ Error fetching user data: $e');
    }
  }

  String getChatId(String id1, String id2, String itemType) {
    final sorted = [id1, id2]..sort();
    return '${sorted[0]}-${sorted[1]}-$itemType';
  }

  void _sendMessage({String? text, String? base64Image}) async {
    if ((text == null || text.trim().isEmpty) && base64Image == null) return;

    final chatId = getChatId(widget.currentUserId, widget.receiverId, widget.itemType);

    try {
      final newMessage = {
        'senderId': widget.currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': base64Image != null ? 'image' : 'text',
      };

      if (base64Image != null) {
        newMessage['image'] = base64Image;
      } else {
        newMessage['text'] = text as Object;
      }

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(newMessage);

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set({
        'participants': {
          widget.currentUserId: true,
          widget.receiverId: true,
        },
        'itemType': widget.itemType,
        'lastMessage': base64Image != null ? '[Image]' : text,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _messageController.clear();
      _pendingImageBase64 = null;

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

  String? _pendingImageBase64; // 📌 holds the image before sending

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60, // 📌 compress to reduce Firestore size
        maxWidth: 800,    // 📌 resize for smaller storage
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);

        setState(() {
          _pendingImageBase64 = base64String;
        });
      }
    } catch (e) {
      print("❌ Error picking image: $e");
    }
  }

  void _handleSend() {
    if (_pendingImageBase64 != null) {
      _sendMessage(base64Image: _pendingImageBase64);
      setState(() => _pendingImageBase64 = null); // clear after sending
    } else {
      _sendMessage(text: _messageController.text);
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
                    final type = msg['type'] ?? 'text';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
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
                        child: type == 'image'
                            ? Image.memory(
                          base64Decode(msg['image']),
                          fit: BoxFit.cover,
                        )
                            : Text(
                          msg['text'] ?? '',
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
                  IconButton(
                    icon: const Icon(Icons.image, color: Colors.deepPurple),
                    onPressed: _pickImageFromGallery,
                  ),
                  if (_pendingImageBase64 != null) // 📌 Show preview if image selected
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: MemoryImage(base64Decode(_pendingImageBase64!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
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
                    onPressed: _handleSend, // 📌 Now uses our combined send logic
                  ),
                ],
              )

            ),
          ),
        ],
      ),
    );
  }
}
