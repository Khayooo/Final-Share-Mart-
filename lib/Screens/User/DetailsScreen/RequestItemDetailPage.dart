import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _sendSMS(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch SMS app")),
      );
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch Phone Dialer")),
      );
    }
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
        title: const Text(
          "Requested Item Detail",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow("Posted on:", formattedDate),
            const Divider(height: 30),

            _infoRow("Item Name:", widget.item['name'] ?? 'N/A'),
            _infoRow("Description:", widget.item['description'] ?? 'N/A'),
            _infoRow("Type:", widget.item['type'] ?? 'Request'),
            const Divider(height: 30),

            const SizedBox(height: 8),
            Text(
              "Requester Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade800,
              ),
            ),
            const SizedBox(height: 12),

            _isLoadingRequester
                ? const Center(child: CircularProgressIndicator())
                : (_requesterData == null
                ? const Text("Requester information not available.")
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow("Name:", _requesterData!['name'] ?? "N/A"),
                _infoRow("Email:", _requesterData!['email'] ?? "N/A"),
                _infoRow("Address:", _requesterData!['address'] ?? "N/A"),
                _infoRow("Phone:", _requesterData!['phone'] ?? "N/A"),
              ],
            )),

            const SizedBox(height: 32),

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
                        if (_requesterData != null && _requesterData!['phone'] != null) {
                          _sendSMS(_requesterData!['phone']);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Phone number not available")),
                          );
                        }
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
                        if (_requesterData != null && _requesterData!['phone'] != null) {
                          _makeCall(_requesterData!['phone']);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Phone number not available")),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
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
