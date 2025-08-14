import 'package:flutter/material.dart';

class ApprovedDonorPage extends StatelessWidget {
  const ApprovedDonorPage({super.key});
//this is page for approved donor
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Approved Donor"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              "Congratulations!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "You are now an approved donor.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
