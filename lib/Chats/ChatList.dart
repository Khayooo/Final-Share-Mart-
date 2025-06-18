import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fypnewproject/Chats/ChatWithUserScreen.dart';
import 'package:fypnewproject/Chats/NoMessageWidget.dart';

class ChatList extends StatelessWidget {
  final String roleFilter;
  final String currentUserId;

  const ChatList({
    super.key,
    required this.roleFilter,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    print("Building ChatList for role: $roleFilter and user: $currentUserId");

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          print("Waiting for chats...");
          return const Center(child: CircularProgressIndicator());
        }

        final allChats = snapshot.data!.docs;
        print("Total chats fetched from Firestore: ${allChats.length}");

        // Filter only chats involving the current user
        final userChats = allChats.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final participants = data['participants'] as Map<String, dynamic>;
          return participants.containsKey(currentUserId);
        }).toList();

        print("Chats involving current user: ${userChats.length}");

        if (userChats.isEmpty) {
          print("No chats found for user $currentUserId");
          return const NoMessageWidget();
        }

        return ListView.builder(
          itemCount: userChats.length,
          itemBuilder: (context, index) {
            final chatDoc = userChats[index];
            final participants = chatDoc['participants'] as Map<String, dynamic>;

            // Get the other participant
            final otherUserId = participants.keys.firstWhere(
                  (id) => id != currentUserId,
              orElse: () => '',
            );

            if (otherUserId.isEmpty) return const SizedBox();


            return FutureBuilder<DataSnapshot>(
              future: FirebaseDatabase.instance.ref('users/$otherUserId').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data?.value == null) {
                  print("Loading user data for $otherUserId...");
                  return const ListTile(title: Text("Loading..."));
                }

                final userData = snapshot.data!.value as Map?;
                final name = userData?['name'] ?? 'User';

                print("Loaded user $name");

                return ListTile(
                  leading: CircleAvatar(child: Text(name[0].toUpperCase())),
                  title: Text(name),
                  subtitle: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatDoc.id)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .limit(1)
                        .get(),
                    builder: (context, msgSnap) {
                      if (msgSnap.hasData && msgSnap.data!.docs.isNotEmpty) {
                        final msgDoc = msgSnap.data!.docs.first;
                        final lastMsg = msgDoc['text'];
                        final timestamp = msgDoc['timestamp'];

                        if (timestamp is Timestamp) {
                          final time = timestamp.toDate();
                          final now = DateTime.now();
                          final diff = now.difference(time);

                          String timeLabel;
                          if (diff.inMinutes < 60) {
                            timeLabel = '${diff.inMinutes}m ago';
                          } else if (diff.inHours < 24) {
                            timeLabel = '${diff.inHours}h ago';
                          } else {
                            timeLabel = '${diff.inDays}d ago';
                          }

                          print("Last message in chat with $otherUserId: $lastMsg at $timeLabel");

                          return Text(
                            '$lastMsg · $timeLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        } else {
                          return Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis);
                        }
                      }
                      return const Text('No messages yet');
                    },
                  ),

                  onTap: () {
                    print("Opening chat with $otherUserId");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatWithUserScreen(

                          currentUserId: currentUserId,
                          receiverId: otherUserId,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
