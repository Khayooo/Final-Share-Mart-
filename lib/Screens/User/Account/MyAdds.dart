import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:typed_data';

class MyAddsScreen extends StatefulWidget {
  const MyAddsScreen({super.key});

  @override
  State<MyAddsScreen> createState() => _MyAddsScreenState();
}

class _MyAddsScreenState extends State<MyAddsScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, List<Map<String, dynamic>>> _userAdsByType = {
    'Sell': [],
    'Donate': [],
    'Exchange': [],
    'Request item': [],
  };

  String _selectedType = 'Sell';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllUserAds();
  }

  Future<void> _loadAllUserAds() async {
    setState(() => _isLoading = true);

    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;

    // Map node names to types
    final paths = {
      'Sell': 'sell',
      'Donate': 'donations',
      'Exchange': 'exchange',
      'Request item': 'requests',
    };

    Map<String, List<Map<String, dynamic>>> fetchedAds = {
      'Sell': [],
      'Donate': [],
      'Exchange': [],
      'Request item': [],
    };

    try {
      for (var entry in paths.entries) {
        final type = entry.key;
        final path = entry.value;

        final snapshot = await _database
            .ref(path)
            .orderByChild('userId')
            .equalTo(uid)
            .get();

        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          final ads = data.entries.map((e) {
            final ad = Map<String, dynamic>.from(e.value);
            ad['id'] = e.key;
            ad['type'] = type;
            return ad;
          }).toList();

          fetchedAds[type] = ads;
        }
      }

      setState(() {
        _userAdsByType = fetchedAds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading ads: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildImageWidget(String? imageBase64) {
    if (imageBase64 == null || imageBase64.isEmpty) {
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
      final bytes = base64Decode(imageBase64);
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
    if (timestamp is int) {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final ads = _userAdsByType[_selectedType] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text('My Ads'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllUserAds,
          )
        ],
      ),
      body: Column(
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
                ? const Center(child: CircularProgressIndicator())
                : ads.isEmpty
                ? Center(
              child: Text(
                'No $_selectedType items posted yet.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadAllUserAds,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ads.length,
                itemBuilder: (context, index) {
                  final ad = ads[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildImageWidget(ad['image']),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ad['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ad['category'] ??
                                          _selectedType,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (ad['description'] != null)
                            Padding(
                              padding:
                              const EdgeInsets.only(top: 12),
                              child: Text(
                                ad['description'],
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 16,
                                  color: Colors.grey.shade500),
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
                              )
                            ],
                          ),
                        ],
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
