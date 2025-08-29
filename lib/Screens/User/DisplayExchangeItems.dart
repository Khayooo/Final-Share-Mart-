import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../Model/ExchangeItemModel.dart';
import 'DetailsScreen/ExchangeItemDetailScreen.dart';

class DisplayExchangeItems extends StatefulWidget {
  const DisplayExchangeItems({super.key});

  @override
  State<DisplayExchangeItems> createState() => _DisplayExchangeItemsState();
}

class _DisplayExchangeItemsState extends State<DisplayExchangeItems> {
  final DatabaseReference _databaseRef =
  FirebaseDatabase.instance.ref('exchange_products');
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
          if (value is Map) {
            items.add(value);
          }
        });

        setState(() {
          _exchangeItems = items.reversed.toList(); // newest first
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
            : LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 2;
            if (constraints.maxWidth > 1200) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth > 800) {
              crossAxisCount = 3;
            }

            return GridView.builder(
              itemCount: _exchangeItems.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (context, index) {
                final item = _exchangeItems[index];

                Uint8List? imageBytes;
                try {
                  if (item['productImage'] != null &&
                      item['productImage'] != "") {
                    imageBytes = base64Decode(item['productImage']);
                  }
                } catch (e) {
                  imageBytes = null;
                }

                return GestureDetector(
                  onTap: () {
                    final selectedItem = ExchangeItemModel.fromMap(item);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExchangeItemDetailScreen(
                          item: selectedItem,

                        ),
                      ),
                    );
                  },
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: imageBytes != null
                                  ? Image.memory(
                                imageBytes,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                                  : Container(
                                height: 120,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
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
                                        fontSize: 12,
                                        color: Colors.black54),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Divider(),
                                  const Text(
                                    "Wants to Exchange With",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['desiredProductDescription'] ??
                                        '',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black45),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
