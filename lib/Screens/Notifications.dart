import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Model/DonateItemModel.dart';
import 'User/DetailsScreen/DonateItemDetailScreen.dart';
import 'User/DetailsScreen/ItemDetailsScreen.dart';

class NotificationsPage extends StatelessWidget {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final DatabaseReference notifRef =
    FirebaseDatabase.instance.ref('notifications');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: notifRef
            .orderByChild('receiverId')
            .equalTo(currentUserId)
            .onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawData =
          snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;

          if (rawData == null || rawData.isEmpty) {
            return const Center(child: Text("No notifications"));
          }

          // Combine key + data, then sort
          final notificationsList = rawData.entries
              .map((e) => {
            "id": e.key,
            ...Map<String, dynamic>.from(e.value as Map),
          })
              .toList();

          notificationsList.sort((a, b) =>
              (b['timestamp'] as int).compareTo(a['timestamp'] as int));

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: notificationsList.length,
            itemBuilder: (context, index) {
              final notif = notificationsList[index];
              final notifId = notif['id'];

              String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(
                DateTime.fromMillisecondsSinceEpoch(notif['timestamp']),
              );

              bool isRead = notif['isRead'] == true;

              return Card(
                elevation: 3,
                color: isRead ? Colors.white : Colors.blue.shade50,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Icon(
                    Icons.notifications,
                    color: isRead ? Colors.grey : Colors.blueAccent,
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif['message'] ?? "No message",
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getBadgeColor(notif['itemType']),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          notif['itemType'] ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      formattedDate,
                      style:
                      TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await notifRef.child(notifId).remove();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification deleted')),
                      );
                    },
                  ),
                  onTap: () async {
                    await notifRef.child(notifId).update({"isRead": true});

                    if (notif['itemType']?.toLowerCase() != "admin") {
                      await _openDetailScreen(
                        context,
                        notif['itemType'],
                        notif['productId'],
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getBadgeColor(String? type) {
    switch (type?.toLowerCase()) {
      case "donate":
        return Colors.green;
      case "sell":
        return Colors.orange;
      case "request":
        return Colors.blueAccent;
      case "admin":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openDetailScreen(
      BuildContext context, String? itemType, String productId) async {
    if (itemType == null || productId.isEmpty) return;

    String dbPath = '';
    Widget Function(Map<String, dynamic>) screenBuilder;

    switch (itemType.toLowerCase()) {
      case "donate":
        dbPath = "donations";
        screenBuilder = (item) =>
            DonateItemDetailScreen(item: DonateItemModel.fromMap(item));
        break;
      case "sell":
        dbPath = "items";
        screenBuilder = (item) => ItemDetailsScreen(item: item);
        break;
      default:
        return;
    }

    DatabaseEvent event =
    await FirebaseDatabase.instance.ref("$dbPath/$productId").once();

    if (event.snapshot.value != null) {
      final itemMap =
      Map<String, dynamic>.from(event.snapshot.value as Map);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => screenBuilder(itemMap),
        ),
      );
    } else {
      print("Item not found in DB.");
    }
  }
}