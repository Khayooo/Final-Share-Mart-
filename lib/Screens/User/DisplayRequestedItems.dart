import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'DetailsScreen/RequestItemDetailPage.dart';

class DisplayRequestedItems extends StatefulWidget {
  const DisplayRequestedItems({super.key});

  @override
  State<DisplayRequestedItems> createState() => _DisplayRequestedItemsState();
}

class _DisplayRequestedItemsState extends State<DisplayRequestedItems> {
  final DatabaseReference _databaseRef =
  FirebaseDatabase.instance.ref().child('request product');

  List<Map<dynamic, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchRequestedItems();
  }

  void _fetchRequestedItems() {
    _databaseRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final List<Map<dynamic, dynamic>> loadedItems = [];

        data.forEach((key, value) {
          if (value is Map) {
            loadedItems.add({
              'name': value['name'] ?? '',
              'description': value['description'] ?? '',
              'itemType': value['itemType'] ?? '',
              'userId': value['userId'] ?? '',
              'timestamp': value['timestamp'] ?? '',
            });
          }
        });

        setState(() {
          _items = loadedItems.reversed.toList(); // newest first
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Requested Items",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _items.isEmpty
          ? const Center(child: Text("No requested items found."))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RequestedItemDetailPage(item: item),
                ),
              );
            },
            child: Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text(
                          item['name'],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.description, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item['description']),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}