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
        title: Text("Notifications"),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: notifRef
            .orderByChild('receiverId')
            .equalTo(currentUserId)
            .onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          Map<dynamic, dynamic>? data =
          snapshot.data!.snapshot.value as Map?;
          if (data == null) {
            return Center(child: Text("No notifications"));
          }

          final notifications = data.values.toList()
            ..sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final notifId = data.keys.elementAt(index);

              String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(
                DateTime.fromMillisecondsSinceEpoch(notif['timestamp']),
              );

              bool isUnread = notif['read'] == false;

              return Card(
                elevation: 3,
                color: isUnread ? Colors.blue.shade50 : Colors.white,
                margin: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Icon(
                    Icons.notifications,
                    color: isUnread ? Colors.blueAccent : Colors.grey,
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif['message'] ?? "No message",
                          style: TextStyle(
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Container(
                        padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getBadgeColor(notif['itemType']),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          notif['itemType'] ?? "",
                          style: TextStyle(
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  onTap: () async {
                    // Mark as read
                    await notifRef.child(notifId).update({"read": true});

                    // Fetch and print before navigation
                    await _openDetailScreen(
                      context,
                      notif['itemType'],
                      notif['productId'],
                    );
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
      default:
        return Colors.grey;
    }
  }

  Future<void> _openDetailScreen(
      BuildContext context, String? itemType, String productId) async {
    if (itemType == null) return;

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
        screenBuilder = (item) =>
             ItemDetailsScreen( item: item,);
        break;
      default:
        return;
    }

    DatabaseEvent event =
    await FirebaseDatabase.instance.ref("$dbPath/$productId").once();

    if (event.snapshot.value != null) {
      final itemMap =
      Map<String, dynamic>.from(event.snapshot.value as Map);

      print("Fetched item from DB: $itemMap"); // ✅ Now prints only the item data

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
