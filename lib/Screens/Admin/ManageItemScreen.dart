import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ManageItemsScreen extends StatefulWidget {
  const ManageItemsScreen({super.key});

  @override
  State<ManageItemsScreen> createState() => _ManageItemsScreenState();
}

class _ManageItemsScreenState extends State<ManageItemsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  String searchQuery = "";

  Map<String, List<Map<dynamic, dynamic>>> itemsData = {
    "Sell": [],
    "Donate": [],
    "Exchange": [],
    "Request": [],
  };

  Map<String, Map<dynamic, dynamic>> usersData = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetchData();
  }

  void fetchData() async {
    await fetchUsers();

    dbRef.child("items").onValue.listen((event) {
      setState(() => itemsData["Sell"] = _parseData(event.snapshot, "Sell"));
    });
    dbRef.child("donations").onValue.listen((event) {
      setState(() => itemsData["Donate"] = _parseData(event.snapshot, "Donate"));
    });
    dbRef.child("exchange_products").onValue.listen((event) {
      setState(() => itemsData["Exchange"] = _parseData(event.snapshot, "Exchange"));
    });
    dbRef.child("request product").onValue.listen((event) {
      setState(() => itemsData["Request"] = _parseData(event.snapshot, "Request"));
    });

    setState(() => loading = false);
  }

  Future<void> fetchUsers() async {
    final snapshot = await dbRef.child("users").once();
    if (snapshot.snapshot.exists) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      usersData = data.map((key, value) => MapEntry(key, Map<dynamic, dynamic>.from(value)));
    }
  }

  List<Map<dynamic, dynamic>> _parseData(DataSnapshot snapshot, String type) {
    if (!snapshot.exists) return [];
    final data = snapshot.value as Map<dynamic, dynamic>;
    return data.entries.map((e) {
      final item = Map<dynamic, dynamic>.from(e.value);
      item["id"] = e.key;
      item["itemType"] = type;
      return item;
    }).toList();
  }

  void deleteItem(String type, String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Item"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (!confirm) return;

    String table = switch (type) {
      "Sell" => "items",
      "Donate" => "donations",
      "Exchange" => "exchange_products",
      _ => "request product"
    };

    await dbRef.child(table).child(id).remove();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Item deleted successfully"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Items", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Sell"),
            Tab(text: "Donate"),
            Tab(text: "Exchange"),
            Tab(text: "Request"),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by product name...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                setState(() => searchQuery = value.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildItemsList("Sell"),
                buildItemsList("Donate"),
                buildItemsList("Exchange"),
                buildItemsList("Request"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItemsList(String type) {
    final filteredList = itemsData[type]!.where((item) {
      final name = (item["productName"] ?? item["name"] ?? "").toString().toLowerCase();
      return name.contains(searchQuery);
    }).toList();

    if (filteredList.isEmpty) {
      return const Center(child: Text("No items found", style: TextStyle(fontSize: 16, color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final item = filteredList[index];
        final user = usersData[item["userId"]] ?? {};
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item["image"] != null || item["productImage"] != null
                  ? Image.memory(
                const Base64Decoder().convert(item["image"] ?? item["productImage"]),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 30, color: Colors.grey),
              ),
            ),
            title: Text(
              item["productName"] ?? item["name"] ?? "Unnamed",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((item["productDescription"] ?? item["description"] ?? "").toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item["productDescription"] ?? item["description"] ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                const SizedBox(height: 4),
                Text("User: ${user["name"] ?? "Unknown"}", style: const TextStyle(color: Colors.deepPurple)),
                Text("Email: ${user["email"] ?? "No email"}", style: const TextStyle(color: Colors.black54)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => deleteItem(type, item["id"]),
            ),
          ),
        );
      },
    );
  }
}
