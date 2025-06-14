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

  List<Map<String, dynamic>> _userAds = [];
  bool _isLoading = true;
  String _filterStatus = 'All'; // All, Active, Completed, Inactive

  @override
  void initState() {
    super.initState();
    _loadUserAds();
  }

  Future<void> _loadUserAds() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Load donations posted by the current user
        final snapshot = await _database
            .ref('donations')
            .orderByChild('donorId')
            .equalTo(user.uid)
            .get();

        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          List<Map<String, dynamic>> ads = [];

          data.forEach((key, value) {
            final ad = Map<String, dynamic>.from(value);
            ad['id'] = key; // Add the key as id
            ads.add(ad);
          });

          // Sort by creation date (most recent first)
          ads.sort((a, b) {
            final aTime = a['createdAt'] ?? 0;
            final bTime = b['createdAt'] ?? 0;
            return bTime.compareTo(aTime);
          });

          setState(() {
            _userAds = ads;
            _isLoading = false;
          });
        } else {
          setState(() {
            _userAds = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user ads: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load your ads: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAds {
    if (_filterStatus == 'All') return _userAds;

    return _userAds.where((ad) {
      final status = ad['status']?.toString().toLowerCase() ?? 'active';
      return status == _filterStatus.toLowerCase();
    }).toList();
  }

  Future<void> _toggleAdStatus(String adId, String currentStatus) async {
    try {
      final newStatus = currentStatus.toLowerCase() == 'active'
          ? 'inactive'
          : 'active';

      await _database.ref('donations/$adId').update({
        'status': newStatus,
        'updatedAt': ServerValue.timestamp,
      });

      // Update local state
      setState(() {
        final index = _userAds.indexWhere((ad) => ad['id'] == adId);
        if (index != -1) {
          _userAds[index]['status'] = newStatus;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ad ${newStatus == 'active'
              ? 'activated'
              : 'deactivated'} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update ad: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAd(String adId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Ad'),
            content: const Text(
                'Are you sure you want to delete this ad? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _database.ref('donations/$adId').remove();

        setState(() {
          _userAds.removeWhere((ad) => ad['id'] == adId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete ad: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey.shade400,
          size: 30,
        ),
      );
    }

    try {
      final Uint8List bytes = base64Decode(imageBase64);
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
    } catch (e) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.broken_image,
          color: Colors.grey.shade400,
          size: 30,
        ),
      );
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is int) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Unknown date';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'inactive':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

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
          "My Adds",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUserAds,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: ['All', 'Active', 'Inactive', 'Completed']
                          .map((status) =>
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(status),
                              selected: _filterStatus == status,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _filterStatus = status;
                                  });
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
              ],
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
                : _filteredAds.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filterStatus == 'All'
                        ? 'No ads posted yet'
                        : 'No ${_filterStatus.toLowerCase()} ads found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by posting your first donation',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadUserAds,
              color: Colors.deepPurple,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredAds.length,
                itemBuilder: (context, index) {
                  final ad = _filteredAds[index];
                  final status = ad['status']?.toString() ?? 'active';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ad['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ad['category'] ?? 'No Category',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status)
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                                12),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              color: _getStatusColor(status),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Colors.grey.shade600,
                                ),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'toggle':
                                      _toggleAdStatus(ad['id'], status);
                                      break;
                                    case 'delete':
                                      _deleteAd(ad['id']);
                                      break;
                                  }
                                },
                                itemBuilder: (context) =>
                                [
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Row(
                                      children: [
                                        Icon(
                                          status.toLowerCase() == 'active'
                                              ? Icons.pause_circle
                                              : Icons.play_circle,
                                          color: Colors.deepPurple,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          status.toLowerCase() == 'active'
                                              ? 'Deactivate'
                                              : 'Activate',
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (ad['description'] != null && ad['description']
                              .toString()
                              .isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              ad['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
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