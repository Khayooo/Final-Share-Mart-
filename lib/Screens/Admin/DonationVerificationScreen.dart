import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fypnewproject/Screens/Admin/AdminDonarVerificationDetailScreen.dart';

class DonationVerificationScreen extends StatefulWidget {
  const DonationVerificationScreen({super.key});

  @override
  State<DonationVerificationScreen> createState() => _DonationVerificationScreenState();
}

class _DonationVerificationScreenState extends State<DonationVerificationScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("donor_verifications");

  void updateStatus(String id, String newStatus) {
    dbRef.child(id).update({"status": newStatus});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Status updated to $newStatus"),
        backgroundColor: newStatus == "approved"
            ? Colors.green
            : newStatus == "pending"
            ? Colors.orange
            : Colors.red,
      ),
    );
  }

  Widget statusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case "approved":
        color = Colors.green;
        break;
      case "pending":
        color = Colors.orange;
        break;
      case "rejected":
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Now we have three tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Donor Verification",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.deepPurple,
          bottom: TabBar(
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.white.withOpacity(0.2),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.pending_actions, color: Colors.orange), text: "Pending"),
              Tab(icon: Icon(Icons.check_circle, color: Colors.green), text: "Approved"),
              Tab(icon: Icon(Icons.cancel, color: Colors.red), text: "Rejected"),
            ],
          ),
        ),
        body: StreamBuilder(
          stream: dbRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return const Center(child: Text("No donor verifications found"));
            }

            final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
            final entries = data.entries.toList();

            final pendingList = entries.where((e) {
              final donor = Map<String, dynamic>.from(e.value);
              return (donor["status"] ?? "pending").toLowerCase() == "pending";
            }).toList();

            final approvedList = entries.where((e) {
              final donor = Map<String, dynamic>.from(e.value);
              return (donor["status"] ?? "").toLowerCase() == "approved";
            }).toList();

            final rejectedList = entries.where((e) {
              final donor = Map<String, dynamic>.from(e.value);
              return (donor["status"] ?? "").toLowerCase() == "rejected";
            }).toList();

            Widget buildDonorList(List<MapEntry<String, dynamic>> list) {
              if (list.isEmpty) {
                return const Center(child: Text("No donors found"));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final donorId = list[index].key;
                  final donor = Map<String, dynamic>.from(list[index].value);

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.deepPurple.withOpacity(0.1),
                        child: const Icon(Icons.person, color: Colors.deepPurple),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              donor["name"] ?? "Unknown",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          statusBadge(donor["status"] ?? "pending"),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📞 ${donor['phone']}"),
                            Text("🆔 ${donor['cnic']}"),
                            Text("🏠 ${donor['address']}"),
                            const SizedBox(height: 8),
                            if ((donor["status"] ?? "").toLowerCase() == "pending")
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => updateStatus(donorId, "approved"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text("Approve"),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: () => updateStatus(donorId, "rejected"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text("Reject"),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminDonarVerificationDetailScreen(
                              donorId: donorId,
                              donor: donor,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }

            return TabBarView(
              children: [
                buildDonorList(pendingList),
                buildDonorList(approvedList),
                buildDonorList(rejectedList),
              ],
            );
          },
        ),
      ),
    );
  }
}