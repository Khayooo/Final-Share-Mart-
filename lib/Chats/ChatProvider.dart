import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fypnewproject/Chats/serverkey.dart';
import 'package:http/http.dart' as http;

import 'Notification_Services.dart';



class ChatProvider with ChangeNotifier {
  final _messagesRef = FirebaseDatabase.instance.ref().child('messages');
  final _chatsRef = FirebaseDatabase.instance.ref().child('chats');
  final _userChatsRef = FirebaseDatabase.instance.ref().child('userChats');
  final _usersRef = FirebaseDatabase.instance.ref().child('users');

  final NotificationServices notificationServices = NotificationServices();

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _chatId;
  String? get chatId => _chatId;

  Future<void> initChat(String senderId, String receiverId) async {
    _chatId = await _getOrCreateChatId(senderId, receiverId);
    fetchMessages(_chatId!);
  }

  Future<String> _getOrCreateChatId(String senderId, String receiverId) async {
    final snapshot = await _userChatsRef.child(senderId).get();
    if (snapshot.exists) {
      final chats = snapshot.value as Map<dynamic, dynamic>;
      for (final id in chats.keys) {
        final chatData = (await _chatsRef.child(id).get()).value as Map?;
        if (chatData != null &&
            chatData['participants'][receiverId] == true) {
          return id;
        }
      }
    }

    // Create new chat
    final newChatRef = _chatsRef.push();
    final newChatId = newChatRef.key!;
    await newChatRef.set({
      'lastMessage': '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'unreadCount': 0,
      'participants': {
        senderId: true,
        receiverId: true,
      },
    });

    await _userChatsRef.child('$senderId/$newChatId').set(true);
    await _userChatsRef.child('$receiverId/$newChatId').set(true);

    return newChatId;
  }

  void fetchMessages(String chatId) {
    _messagesRef.child(chatId).onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        _messages = data.entries.map((e) {
          return {
            'messageId': e.key,
            ...Map<String, dynamic>.from(e.value),
          };
        }).toList()
          ..sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

        notifyListeners();
      }
    });
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    if (_chatId == null) {
      _chatId = await _getOrCreateChatId(senderId, receiverId);
    }

    final msgRef = _messagesRef.child(_chatId!).push();
    await msgRef.set({
      'senderId': senderId,
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isRead': false,
    });

    await _chatsRef.child(_chatId!).update({
      'lastMessage': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'unreadCount': ServerValue.increment(1),
    });

    // Send notification (optional)
    try {
      final senderSnapshot = await _usersRef.child(senderId).get();
      final receiverSnapshot = await _usersRef.child(receiverId).get();

      if (receiverSnapshot.exists) {
        final senderName = senderSnapshot.child('name').value;
        final receiverToken = receiverSnapshot.child('deviceToken').value;

        final token = await GetServerKey();

        await http.post(
          Uri.parse('https://fcm.googleapis.com/v1/projects/installmentapp-1cf69/messages:send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            "message": {
              "token": receiverToken,
              "notification": {
                "title": senderName,
                "body": message,
              },
              "data": {"type": "chat"}
            }
          }),
        );
      }
    } catch (e) {
      print('Notification error: $e');
    }

    notifyListeners();
  }

  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    final snapshot = await _usersRef.child(userId).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      return {
        'name': data['name'] ?? '',
        'profileImage': data['profileImage'] ?? '',
      };
    }
    return null;
  }
}
