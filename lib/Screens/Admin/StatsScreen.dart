import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final db = FirebaseDatabase.instance.ref();

  Map<String, int> counts = {
    "users": 0,
    "items": 0,
    "donations": 0,
    "exchange_products": 0,
    "requests": 0,
    "donor_verification": 0,
    "verified_donations": 0,
    "unverified_donations": 0,
  };

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    try {
      final results = await Future.wait([
        _countTable("users"),
        _countTable("items"),
        _countTable("donations"),
        _countTable("exchange_products"),
        _countTable("request product"),
        _countTable("donor_verifications"),
        _countDonationsByStatus("approved"),
        _countDonationsByStatus("pending"),
      ]);

      setState(() {
        counts["users"] = results[0];
        counts["items"] = results[1];
        counts["donations"] = results[2];
        counts["exchange_products"] = results[3];
        counts["requests"] = results[4];
        counts["donor_verification"] = results[5];
        counts["verified_donations"] = results[6];
        counts["unverified_donations"] = results[7];
        _loading = false;
      });
    } catch (e) {
      print("Error fetching counts: $e");
      setState(() => _loading = false);
    }
  }

  Future<int> _countTable(String tableName) async {
    final snapshot = await db.child(tableName).once();
    if (snapshot.snapshot.exists) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      return data.length;
    }
    return 0;
  }

  Future<int> _countDonationsByStatus(String status) async {
    final snapshot = await db.child("donor_verifications").once();
    if (snapshot.snapshot.exists) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      print(data.values
          .where((item) =>
      (item["status"] ?? "").toString().toLowerCase() ==
          status.toLowerCase())
          .length);
      return data.values
          .where((item) =>
      (item["status"] ?? "").toString().toLowerCase() ==
          status.toLowerCase())
          .length;
    }
    return 0;
  }

  Widget buildStatCard(String title, int count, IconData icon, List<Color> gradientColors) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: gradientColors.last.withOpacity(0.4), blurRadius: 8, offset: const Offset(2, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Text(
        "📊 Stats Dashboard",
        style: TextStyle(color: Colors.white),
    ),
    centerTitle: true,
    backgroundColor: Colors.deepPurple,
    iconTheme: const IconThemeData(color: Colors.white),
    ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          children: [
            buildStatCard("Total Users", counts["users"]!, Icons.people, [Colors.blue, Colors.blueAccent]),
            buildStatCard("Sell Items", counts["items"]!, Icons.shopping_cart, [Colors.orange, Colors.deepOrange]),
            buildStatCard("Donate Items", counts["donations"]!, Icons.volunteer_activism, [Colors.green, Colors.teal]),
            buildStatCard("Exchange Items", counts["exchange_products"]!, Icons.swap_horiz, [Colors.purple, Colors.deepPurple]),
            buildStatCard("Requests", counts["requests"]!, Icons.request_page, [Colors.teal, Colors.cyan]),
            buildStatCard("Donor Verification", counts["donor_verification"]!, Icons.verified_user, [Colors.red, Colors.deepOrange]),
            buildStatCard("Verified Donations", counts["verified_donations"]!, Icons.check_circle, [Colors.indigo, Colors.blue]),
            buildStatCard("Unverified Requests Donors", counts["unverified_donations"]!, Icons.cancel, [Colors.grey, Colors.blueGrey]),
          ],
        ),
      ),
    );
  }
}
