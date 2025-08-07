import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DisplayExchangeItems extends StatefulWidget {
  const DisplayExchangeItems({super.key});

  @override
  State<DisplayExchangeItems> createState() => _DisplayExchangeItemsState();
}

class _DisplayExchangeItemsState extends State<DisplayExchangeItems> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('exchange_products');
  List<Map<dynamic, dynamic>> _exchangeItems = [];

  @override
  void initState() {
    super.initState();
    _fetchExchangeItems();
  }

  void _fetchExchangeItems() {
    _databaseRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        List<Map<dynamic, dynamic>> items = [];
        data.forEach((key, value) {
          items.add(value as Map);
        });

        setState(() {
          _exchangeItems = items;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Exchange Items",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _exchangeItems.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
          itemCount: _exchangeItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemBuilder: (context, index) {
            final item = _exchangeItems[index];

            Uint8List? imageBytes;
            if (item['productImage'] != null) {
              imageBytes = base64Decode(item['productImage']);
            }

            return Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (imageBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            imageBytes,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 100,
                          alignment: Alignment.center,
                          child: const Text("No Image"),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        item['productName'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['productDescription'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      const Divider(thickness: 1),
                      const Text(
                        "Wants to Exchange With",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['desiredProductName'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['desiredProductDescription'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
