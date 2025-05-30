import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'ItemDetailsScreen.dart';

class DonationItemsScreen extends StatefulWidget {
  const DonationItemsScreen({super.key});

  @override
  State<DonationItemsScreen> createState() => _DonationItemsScreenState();
}

class _DonationItemsScreenState extends State<DonationItemsScreen> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref().child('donations');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Free Items for Donation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _ref.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No donation items available'));
          }

          final itemsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final items = itemsMap.entries.map((entry) {
            final data = entry.value as Map<dynamic, dynamic>;
            return ItemModel.fromMap(Map<String, dynamic>.from(data));
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailsScreen(
                          item: {
                            "image": item.image,
                            "title": item.productName,
                            "price": item.productPrice,
                            "description": item.productDescription,
                            "itemType": "Donation",
                          },
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: item.image.isNotEmpty
                                ? Image.memory(
                              base64Decode(item.image),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                                : Container(
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
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "FREE",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ItemModel {
  final String productName;
  final String productPrice;
  final String productDescription;
  final String image;
  final String uid;
  final String itemType;

  ItemModel({
    required this.productName,
    required this.productPrice,
    required this.productDescription,
    required this.image,
    required this.uid,
    required this.itemType,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      productName: map['productName'] ?? '',
      productPrice: map['productPrice'] ?? '',
      productDescription: map['productDescription'] ?? '',
      image: map['image'] ?? '',
      uid: map['uid'] ?? '',
      itemType: map['itemType'] ?? 'Donate',
    );
  }
}