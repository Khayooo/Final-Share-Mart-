import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

// Import your detail screens here
import '../../Model/DonateItemModel.dart';
import '../../Model/ExchangeItemModel.dart';
import 'User/DetailsScreen/DonateItemDetailScreen.dart';
import 'User/DetailsScreen/ExchangeItemDetailScreen.dart';
import 'User/DetailsScreen/ItemDetailsScreen.dart';
import 'User/DetailsScreen/RequestItemDetailPage.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
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

  void navigateToDetail(Map item, String type) {
    if (type == "Sell") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ItemDetailsScreen(
            item: Map<String, dynamic>.from(item), // Convert here
          ),
        ),
      );
    } else if (type == "Donate") {
      final selectedItem = DonateItemModel.fromMap(Map<String, dynamic>.from(item));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DonateItemDetailScreen(
            item: selectedItem,
          ),
        ),
      );
    } else if (type == "Exchange") {
      final selectedItem = ExchangeItemModel.fromMap(Map<String, dynamic>.from(item));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExchangeItemDetailScreen(
            item: selectedItem,
          ),
        ),
      );
    } else if (type == "Request") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RequestedItemDetailPage(
            item: Map<String, dynamic>.from(item),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Items", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "🔍 Search by product name...",
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              style: const TextStyle(fontSize: 16),
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
              ],
            ),
            onTap: () => navigateToDetail(item, type),
          ),
        );
      },
    );
  }
}