import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fypnewproject/Screens/User/DetailsScreen/ItemDetailsScreen.dart';
import 'dart:convert';
import '../../../Model/DonateItemModel.dart';
import '../../../Model/ExchangeItemModel.dart';
import '../DetailsScreen/DonateItemDetailScreen.dart';
import '../DetailsScreen/ExchangeItemDetailScreen.dart';
import '../DetailsScreen/RequestItemDetailPage.dart';



class MyAddsScreen extends StatefulWidget {
  const MyAddsScreen({super.key});

  @override
  State<MyAddsScreen> createState() => _MyAddsScreenState();
}

class _MyAddsScreenState extends State<MyAddsScreen> {
  String _selectedType = 'Sell';
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _adsData = {
    'Sell': [],
    'Donate': [],
    'Exchange': [],
    'Request item': [],
  };
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Firebase database reference
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Firebase Auth instance to get current user
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user ID
  String? _currentUserId;

  // Map tab names to Firebase node names
  final Map<String, String> _nodeMapping = {
    'Sell': 'items',
    'Donate': 'donations',
    'Exchange': 'exchange_products',
    'Request item': 'request product',
  };

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchAllData();
  }

  void _getCurrentUser() {
    User? user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
    } else {
      // Handle case where user is not logged in
      print('No user logged in');
      // You might want to navigate to login screen here
    }
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);

    // Check if user is logged in
    if (_currentUserId == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to view your ads'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Fetch data for all tabs
      for (String tabName in _nodeMapping.keys) {
        await _fetchDataForTab(tabName);
      }
    } catch (e) {
      print('Error fetching data: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchDataForTab(String tabName) async {
    if (_currentUserId == null) return;

    String nodeName = _nodeMapping[tabName]!;

    try {
      final snapshot = await _database.child(nodeName).get();

      List<Map<String, dynamic>> items = [];

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          if (value is Map) {
            Map<String, dynamic> item = Map<String, dynamic>.from(value);

            // Filter by current user ID
            // Check if the item belongs to the current user
            String? itemUserId = item['userId'] ?? item['uid'] ?? item['userUid'];

            if (itemUserId == _currentUserId) {
              item['key'] = key; // Add Firebase key for potential future use
              items.add(item);
            }
          }
        });

        // Sort by creation date (newest first)
        items.sort((a, b) {
          int timeA = a['createdAt'] ?? 0;
          int timeB = b['createdAt'] ?? 0;
          return timeB.compareTo(timeA);
        });
      }

      if (mounted) {
        setState(() {
          _adsData[tabName] = items;
        });
      }
    } catch (e) {
      print('Error fetching $tabName data: $e');
      throw e;
    }
  }

  Future<void> _refreshCurrentTab() async {
    await _fetchDataForTab(_selectedType);
  }

  // Navigate to appropriate detail screen based on tab type
  void _navigateToDetailScreen(Map<String, dynamic> item) {
    switch (_selectedType) {
      case 'Sell':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailsScreen(item: item),
          ),
        );
        break;
    case 'Donate':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DonateItemDetailScreen(
            item: DonateItemModel.fromMap(item),
          ),
        ),
      );
      break;
    case 'Exchange':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExchangeItemDetailScreen(
            item: ExchangeItemModel.fromMap(item), currentUserId: currentUserId,
          ),
        ),
      );
      break;
      case 'Request item':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestedItemDetailPage(item: item),
          ),
        );
        break;
    }
  }

  // Delete item function
  Future<void> _deleteItem(Map<String, dynamic> item, int index) async {
    // Verify that the item belongs to the current user before deleting
    String? itemUserId = item['userId'] ?? item['uid'] ?? item['userUid'];
    if (itemUserId != _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete your own items'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: Text(
            'Are you sure you want to delete "${item['productName'] ?? item['name'] ?? 'this item'}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleting item...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Get the Firebase node name for current tab
      String nodeName = _nodeMapping[_selectedType]!;
      String itemKey = item['key'];

      // Delete from Firebase
      await _database.child(nodeName).child(itemKey).remove();

      // Remove from local data
      if (mounted) {
        setState(() {
          _adsData[_selectedType]!.removeAt(index);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item deleted successfully'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Refresh',
              onPressed: _refreshCurrentTab,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error deleting item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildImageWidget(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.image_not_supported, color: Colors.grey.shade400),
      );
    }

    try {
      final bytes = base64Decode(base64Image);
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: MemoryImage(bytes),
            fit: BoxFit.cover,
          ),
        ),
      );
    } catch (_) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.broken_image, color: Colors.grey.shade400),
      );
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      int milliseconds;
      if (timestamp is int) {
        milliseconds = timestamp;
      } else if (timestamp is String) {
        milliseconds = int.parse(timestamp);
      } else {
        return 'Unknown';
      }

      final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ads = _adsData[_selectedType] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text('My Ads'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCurrentTab,
          ),
        ],
      ),
      body: _currentUserId == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Please log in to view your ads',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Tabs
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: ['Sell', 'Donate', 'Exchange', 'Request item']
                    .map((type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = type);
                      }
                    },
                    selectedColor: Colors.deepPurple.shade100,
                    checkmarkColor: Colors.deepPurple,
                  ),
                ))
                    .toList(),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurple,
              ),
            )
                : ads.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No $_selectedType items posted yet.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start posting to see your items here!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _refreshCurrentTab,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ads.length,
                itemBuilder: (context, index) {
                  final ad = ads[index];
                  return InkWell(
                    onTap: () => _navigateToDetailScreen(ad),
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row with delete button
                            Row(
                              children: [
                                if(_selectedType != 'Request item')
                                  _buildImageWidget(ad['image'] ?? ad['productImage']),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ad['productName'] ?? ad['name'] ?? 'No Title',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ad['category'] ?? _selectedType,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      // Sell section - Show price
                                      if (_selectedType == 'Sell' && ad['productPrice'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Price: Rs. ${ad['productPrice']}',
                                            style: TextStyle(
                                              color: Colors.deepPurple,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      // Exchange section - Show desired product
                                      if (_selectedType == 'Exchange' && ad['desiredProductName'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Want: ${ad['desiredProductName']}',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      // Request item section - Show type
                                      if (_selectedType == 'Request item' && ad['type'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Type: ${ad['itemType']}',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Delete button
                                IconButton(
                                  onPressed: () => _deleteItem(ad, index),
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red.shade400,
                                  tooltip: 'Delete item',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                ),
                              ],
                            ),
                            if (ad['description'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  ad['description'],
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            // Additional info section for different tabs
                            if (_selectedType == 'Exchange' && (ad['exchangeDetails'] != null || ad['condition'] != null))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (ad['exchangeDetails'] != null)
                                        Text(
                                          'Exchange Details: ${ad['exchangeDetails']}',
                                          style: TextStyle(
                                            color: Colors.orange.shade800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      if (ad['condition'] != null)
                                        Text(
                                          'Condition: ${ad['condition']}',
                                          style: TextStyle(
                                            color: Colors.orange.shade800,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            // Request item additional info
                            if (_selectedType == 'Request item' && (ad['urgency'] != null || ad['budget'] != null))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (ad['urgency'] != null)
                                        Text(
                                          'Urgency: ${ad['urgency']}',
                                          style: TextStyle(
                                            color: Colors.green.shade800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      if (ad['budget'] != null)
                                        Text(
                                          'Budget: Rs. ${ad['budget']}',
                                          style: TextStyle(
                                            color: Colors.green.shade800,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    ad['location'] ?? 'No location',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDate(ad['createdAt']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}