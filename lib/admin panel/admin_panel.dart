// admin_panel.dart
import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Map UI tab index -> itemType string used in item documents
  final List<String> _tabs = ['Verification', 'Sell', 'Donate', 'Exchange', 'Request'];

  // firebase root paths - adjust to match your DB structure if needed
  final String usersNode = 'users';
  final String genericItemsNode = 'items'; // optional: items stored under /items with itemType field
  final Map<String, String> specificItemNodes = {
    'Sell': 'selling',
    'Donate': 'donation',
    'Exchange': 'exchange',
    'Request': 'request',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String formatTimestamp(int ts) {
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (e) {
      return 'Unknown time';
    }
  }

  /// Approve user by setting isVerified = true (modify per your rules)
  Future<void> _approveUser(String userId) async {
    try {
      final ref = FirebaseDatabase.instance.ref().child(usersNode).child(userId);
      await ref.update({'isVerified': true});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User approved')));
    } catch (e) {
      debugPrint('approve error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to approve')));
    }
  }

  /// Reject user - here we delete the user node (change to mark rejected if you prefer)
  Future<void> _rejectUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm reject'),
        content: const Text('Are you sure you want to remove this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final ref = FirebaseDatabase.instance.ref().child(usersNode).child(userId);
        await ref.remove();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User removed')));
      } catch (e) {
        debugPrint('reject error: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to remove user')));
      }
    }
  }

  /// Delete an item located at a known path. path = '/node/{key}'
  Future<void> _deleteItem(String nodePath, String key) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final ref = FirebaseDatabase.instance.ref().child(nodePath).child(key);
        await ref.remove();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item deleted')));
      } catch (e) {
        debugPrint('delete item error: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete item')));
      }
    }
  }

  /// Build stream that merges:
  ///  - items from /items where itemType == type (if exists)
  ///  - items from a type-specific top-level node (like /selling, /donation, etc.)
  ///
  /// Each emitted value is a List<Map<String, dynamic>> where each map contains:
  ///  - 'key' (firebase key)
  ///  - 'data' (Map<String, dynamic>)
  ///  - 'sourceNode' (string name of node, e.g. 'items' or 'selling')
  Stream<List<Map<String, dynamic>>> buildItemsStreamFor(String typeName) {
    // typeName expected 'Sell' / 'Donate' / 'Exchange' / 'Request'
    final StreamController<List<Map<String, dynamic>>> controller = StreamController();
    final List<Map<String, dynamic>> current = [];

    // helper to push current snapshot
    void push() {
      // clone before pushing
      controller.add(List<Map<String, dynamic>>.from(current));
    }

    // listen to generic items node and filter by itemType
    final genericRef = FirebaseDatabase.instance.ref().child(genericItemsNode);
    final genericSub = genericRef.onValue.listen((event) {
      try {
        current.removeWhere((m) => m['sourceNode'] == genericItemsNode);
        final value = event.snapshot.value;
        if (value is Map) {
          final filtered = <Map<String, dynamic>>[];
          value.forEach((k, v) {
            try {
              final map = Map<String, dynamic>.from(v);
              final itemType = (map['itemType'] ?? '').toString().toLowerCase();
              if (itemType == typeName.toLowerCase()) {
                filtered.add({'key': k.toString(), 'data': map, 'sourceNode': genericItemsNode});
              }
            } catch (_) {}
          });
          current.addAll(filtered);
        }
      } catch (e) {
        debugPrint('generic items parse error: $e');
      }
      push();
    }, onError: (err) {
      debugPrint('generic items stream error: $err');
      push();
    });

    // listen to a specific node if exists
    final specificNode = specificItemNodes[typeName] ?? '';
    StreamSubscription<DatabaseEvent>? specificSub;
    if (specificNode.isNotEmpty) {
      final ref = FirebaseDatabase.instance.ref().child(specificNode);
      specificSub = ref.onValue.listen((event) {
        try {
          current.removeWhere((m) => m['sourceNode'] == specificNode);
          final value = event.snapshot.value;
          if (value is Map) {
            value.forEach((k, v) {
              try {
                final map = Map<String, dynamic>.from(v);
                current.add({'key': k.toString(), 'data': map, 'sourceNode': specificNode});
              } catch (_) {}
            });
          }
        } catch (e) {
          debugPrint('specific items parse error: $e');
        }
        push();
      }, onError: (err) {
        debugPrint('specific items stream error: $err');
        push();
      });
    }

    controller.onCancel = () async {
      await genericSub.cancel();
      if (specificSub != null) await specificSub.cancel();
      await controller.close();
    };

    return controller.stream;
  }

  /// Build stream for unverified users under /users (isVerified == false or missing)
  Stream<List<Map<String, dynamic>>> buildUnverifiedUsersStream() {
    final StreamController<List<Map<String, dynamic>>> controller = StreamController();
    final List<Map<String, dynamic>> current = [];

    final ref = FirebaseDatabase.instance.ref().child(usersNode);
    final sub = ref.onValue.listen((event) {
      current.clear();
      final value = event.snapshot.value;
      if (value is Map) {
        value.forEach((k, v) {
          try {
            final map = Map<String, dynamic>.from(v);
            final isVerified = map['isVerified'] == true;
            if (!isVerified) {
              current.add({'key': k.toString(), 'data': map});
            }
          } catch (_) {}
        });
      }
      // sort optional: newest first if you store timestamp
      current.sort((a, b) {
        final aTs = (a['data']['timestamp'] ?? 0) as int;
        final bTs = (b['data']['timestamp'] ?? 0) as int;
        return bTs.compareTo(aTs);
      });
      controller.add(List<Map<String, dynamic>>.from(current));
    }, onError: (err) {
      debugPrint('users stream error: $err');
      controller.add([]);
    });

    controller.onCancel = () async {
      await sub.cancel();
      await controller.close();
    };

    return controller.stream;
  }

  Widget _buildItemCard(Map<String, dynamic> item, String nodeName) {
    final data = Map<String, dynamic>.from(item['data'] ?? {});
    final key = item['key'] ?? '';
    final title = data['productName'] ?? data['title'] ?? 'No title';
    final desc = data['productDescription'] ?? data['description'] ?? '';
    final price = data['productPrice']?.toString() ?? '';
    final posterId = data['userId'] ?? data['posterId'] ?? data['uid'] ?? 'Unknown';
    final ts = data['timestamp'] ?? 0;
    final base64Image = data['image'] ?? data['productImage'] ?? '';

    Widget leading = const SizedBox(width: 60, height: 60, child: Icon(Icons.image));
    if (base64Image is String && base64Image.isNotEmpty) {
      try {
        final imageBytes = base64Decode(base64Image);
        leading = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(imageBytes, width: 60, height: 60, fit: BoxFit.cover),
        );
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: leading,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (desc.isNotEmpty) Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (price.isNotEmpty) Text('Price: $price'),
            Text('Posted by: $posterId', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(formatTimestamp(ts is int ? ts : 0), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            // delete from the source node
            final source = item['sourceNode'] ?? specificItemNodes[title] ?? specificItemNodes['Sell'];
            final nodeToDeleteFrom = (item['sourceNode'] ?? nodeName) as String;
            _deleteItem(nodeToDeleteFrom, key);
          },
        ),
        onTap: () {
          // optional: show item detail modal or navigate to details
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userItem) {
    final data = Map<String, dynamic>.from(userItem['data'] ?? {});
    final key = userItem['key'] ?? '';
    final name = data['name'] ?? data['fullName'] ?? 'No name';
    final email = data['email'] ?? 'No email';
    final address = data['address'] ?? 'No address';
    final phone = data['phone'] ?? data['phoneNumber'] ?? 'No phone';
    final ts = data['timestamp'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email),
            Text(address),
            Text(phone),
            Text(formatTimestamp(ts is int ? ts : 0), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _approveUser(key),
              child: const Text('Approve', style: TextStyle(color: Colors.green)),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _rejectUser(key),
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabView(String tabName) {
    if (tabName == 'Verification') {
      // show unverified users
      return StreamBuilder<List<Map<String, dynamic>>>(
        stream: buildUnverifiedUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('No users pending verification'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, i) => _buildUserCard(users[i]),
          );
        },
      );
    }

    // For item tabs (Sell / Donate / Exchange / Request)
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: buildItemsStreamFor(tabName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(child: Text('No ${tabName.toLowerCase()} items found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, i) => _buildItemCard(items[i], specificItemNodes[tabName] ?? genericItemsNode),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((t) => _buildTabView(t)).toList(),
      ),
    );
  }
}