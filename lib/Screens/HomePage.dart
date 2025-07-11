import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_database/firebase_database.dart';

import '../Chats/ChatsScreen.dart';
import '../add product features/Product_Request.dart';
import '../add product features/exchange_product.dart';
import 'DonorVerificationScreen.dart';
import 'ItemDetailsScreen.dart';
import 'ListedItem.dart';
import 'AccountScreen.dart';
import 'AddItemScreen.dart';
import 'DonationItems.dart';
import '../Widgets/PendingVerificationPage.dart';
import 'Notifications.dart';

class ItemModel {
  final String image;
  final String itemType;
  final String productName;
  final String productDescription;
  final String productPrice;
  final int timestamp;
  final String uid;
  final String userId;

  ItemModel({
    required this.image,
    required this.itemType,
    required this.productName,
    required this.productDescription,
    required this.productPrice,
    required this.timestamp,
    required this.uid,
    required this.userId,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      image: map['image'] ?? '',
      itemType: map['itemType'] ?? '',
      productName: map['productName'] ?? '',
      productDescription: map['productDescription'] ?? '',
      productPrice: map['productPrice'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      uid: map['uid'] ?? '',
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'image': image,
      'itemType': itemType,
      'productName': productName,
      'productDescription': productDescription,
      'productPrice': productPrice,
      'timestamp': timestamp,
      'uid': uid,
      'userId': userId,
    };
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child('items');
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    timeDilation = 1.5;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationItemsScreen()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatsScreen()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
        break;
    }
  }

  void _showAddItemDialog(BuildContext context) {
    bool sellChecked = false;
    bool donateChecked = false;
    bool exchangeChecked = false;
    bool requestChecked = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Select Item Type", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text("Sell Product"),
                  value: sellChecked,
                  onChanged: (value) {
                    setState(() {
                      sellChecked = value!;
                      donateChecked = exchangeChecked = requestChecked = false;
                    });
                  },
                  activeColor: Colors.deepPurple,
                ),
                CheckboxListTile(
                  title: const Text("Donate Product"),
                  value: donateChecked,
                  onChanged: (value) {
                    setState(() {
                      donateChecked = value!;
                      sellChecked = exchangeChecked = requestChecked = false;
                    });
                  },
                  activeColor: Colors.deepPurple,
                ),
                CheckboxListTile(
                  title: const Text("Exchange Product"),
                  value: exchangeChecked,
                  onChanged: (value) {
                    setState(() {
                      exchangeChecked = value!;
                      sellChecked = donateChecked = requestChecked = false;
                    });
                  },
                  activeColor: Colors.deepPurple,
                ),
                CheckboxListTile(
                  title: const Text("Request Product"),
                  value: requestChecked,
                  onChanged: (value) {
                    setState(() {
                      requestChecked = value!;
                      sellChecked = donateChecked = exchangeChecked = false;
                    });
                  },
                  activeColor: Colors.deepPurple,
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.deepPurple))),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (sellChecked || donateChecked) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AddItemScreen(itemType: sellChecked ? "Sell" : "Donate", isDonation: donateChecked)));
                  } else if (exchangeChecked) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExchangeProduct()));
                  } else if (requestChecked) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestProduct()));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                child: const Text("Continue"),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Welcome, Share Mart!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.deepPurple),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const Notifications()));
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120), // Increased bottom padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Find items to donate or request", style: TextStyle(color: Colors.deepPurple)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.deepPurple),
                      SizedBox(width: 10),
                      Expanded(child: TextField(decoration: InputDecoration(hintText: 'Search for items...', border: InputBorder.none))),
                      Icon(Icons.tune, color: Colors.deepPurple),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Featured Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    TextButton(onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ItemListed())); },
                        child: const Text("See all", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple))),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFeaturedItemsGrid(isLargeScreen),
                const SizedBox(height: 32),
                _buildBrowseByCategory(),
                const SizedBox(height: 100), // Additional space at bottom
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _showAddItemDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomAppBar(
          height: 80, // Increased height further
          color: Colors.white,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildNavItem(Icons.home, "Home", 0)),
                Expanded(child: _buildNavItem(Icons.volunteer_activism, "Donations", 1)),
                const SizedBox(width: 40), // Space for FAB
                Expanded(child: _buildNavItem(Icons.chat_bubble_outline, "Chats", 3)),
                Expanded(child: _buildNavItem(Icons.person_outline, "Account", 4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseByCategory() {
    final categories = [
      {'name': 'Electronics', 'icon': Icons.phone_android, 'color': Colors.purple.shade100},
      {'name': 'Watches', 'icon': Icons.watch, 'color': Colors.blue.shade100},
      {'name': 'Furniture', 'icon': Icons.chair, 'color': Colors.green.shade100},
      {'name': 'Books', 'icon': Icons.book, 'color': Colors.orange.shade100},
      {'name': 'Kitchenware', 'icon': Icons.kitchen, 'color': Colors.red.shade100},
      {'name': 'Toys', 'icon': Icons.toys, 'color': Colors.pink.shade100},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Browse by Category",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all categories page
              },
              child: const Text(
                "See all",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    // Handle category tap
                    print('Tapped on ${category['name']}');
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          category['icon'] as IconData,
                          color: Colors.deepPurple,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Scroll indicator dots
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                (categories.length / 3).ceil(),
                    (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == 0 ? Colors.deepPurple : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurple : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.deepPurple : Colors.grey,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedItemsGrid(bool isLargeScreen) {
    return StreamBuilder(
      stream: _databaseRef.onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final itemsMap = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
        if (itemsMap == null || itemsMap.isEmpty) return const Center(child: Text('No items available'));

        final items = itemsMap.entries.map((entry) {
          final data = entry.value as Map<dynamic, dynamic>;
          return ItemModel.fromMap(Map<String, dynamic>.from(data));
        }).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length > 4 ? 4 : items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isLargeScreen ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: item.toMap())));
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: item.image.isNotEmpty
                            ? Image.memory(base64Decode(item.image), fit: BoxFit.contain, width: double.infinity)
                            : Container(color: Colors.grey.shade200, child: const Icon(Icons.image, size: 50, color: Colors.grey)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  item.productPrice == "Free" ? "Free" : "Rs. ${item.productPrice}",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                ),
                              ),
                              Icon(Icons.favorite_border, size: 20, color: Colors.grey.shade600),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}