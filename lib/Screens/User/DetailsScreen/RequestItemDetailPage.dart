import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Chat/ChatWithUserScreen.dart';

class RequestedItemDetailPage extends StatefulWidget {
  final Map<dynamic, dynamic> item;

  const RequestedItemDetailPage({super.key, required this.item});

  @override
  State<RequestedItemDetailPage> createState() => _RequestedItemDetailPageState();
}

class _RequestedItemDetailPageState extends State<RequestedItemDetailPage> {
  Map<String, dynamic>? _requesterData;
  bool _isLoadingRequester = true;

  @override
  void initState() {
    super.initState();
    _fetchRequesterInfo(widget.item['userId']);
  }

  Future<void> _fetchRequesterInfo(String userId) async {
    try {
      final ref = FirebaseDatabase.instance.ref().child('users').child(userId);
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value is Map) {
        setState(() {
          _requesterData = Map<String, dynamic>.from(snapshot.value as Map);
          _isLoadingRequester = false;
        });
      } else {
        setState(() {
          _requesterData = null;
          _isLoadingRequester = false;
        });
      }
    } catch (e) {
      print("Error fetching requester info: $e");
      setState(() {
        _requesterData = null;
        _isLoadingRequester = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(
      int.tryParse(widget.item['timestamp'].toString()) ?? 0,
    );
    final String formattedDate = DateFormat.yMMMd().add_jm().format(date);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Requested Item Detail"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item details...
            Text(
              widget.item['name'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              widget.item['description'] ?? '',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text("Type: ${widget.item['type'] ?? 'N/A'}"),
            const SizedBox(height: 8),
            Text("Posted on: $formattedDate"),
            const SizedBox(height: 24),

            // Requester Information Section
            const Text(
              "Requester Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),

            _isLoadingRequester
                ? const Center(child: CircularProgressIndicator())
                : (_requesterData == null
                ? const Text("Requester information not available.")
                : _buildInfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow("Name", _requesterData!['name'] ?? "N/A"),
                  const SizedBox(height: 10),
                  _buildInfoRow("Email", _requesterData!['email'] ?? "N/A"),
                  const SizedBox(height: 10),
                  _buildInfoRow("Address", _requesterData!['address'] ?? "N/A"),
                  const SizedBox(height: 10),
                  _buildInfoRow("Phone", _requesterData!['phone'] ?? "N/A"),
                ],
              ),
            )),

            const SizedBox(height: 32),

            // Action buttons...
            if (widget.item['userId'] != currentUserId)
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.chat,
                      label: "Chat",
                      color: Colors.deepPurple,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatWithUserScreen(
                              currentUserId: currentUserId,
                              receiverId: widget.item['userId'],
                              itemType: widget.item['itemType'] ?? 'Unknown',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.sms,
                      label: "SMS",
                      color: Colors.blue,
                      onPressed: () {
                        // TODO: Implement SMS functionality
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.call,
                      label: "Call",
                      color: Colors.green,
                      onPressed: () {
                        // TODO: Implement call functionality
                      },
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
