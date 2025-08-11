import 'package:flutter/material.dart';
import 'package:fypnewproject/Screens/Admin/AdminNotificationsScreen.dart';
import 'package:fypnewproject/Screens/Admin/DonationVerificationScreen.dart';
import 'package:fypnewproject/Screens/Admin/ManageItemScreen.dart';
import 'package:fypnewproject/Screens/Admin/StatsScreen.dart';
import 'package:fypnewproject/Screens/Admin/UsersManagementScreen.dart';

import 'ReportsScreen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  // Tile button widget
  Widget buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
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
        title: const Text("Admin Dashboard" , style: TextStyle(
          color: Colors.white
        ),),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [

            // 2️⃣ Manage Orders
            buildTile(
              icon: Icons.shopping_cart,
              title: "Stats Dashboard ",
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatsScreen()),
                );
              },
            ),
            // 1️⃣ Manage Users
            buildTile(
              icon: Icons.people,
              title: "Manage Users",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsersManagementScreen()),
                );
              },
            ),

            // 3️⃣ Manage Donations
            buildTile(
              icon: Icons.volunteer_activism,
              title: "Donations verification",
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DonationVerificationScreen()),
                );
              },
            ),

            // 4️⃣ Manage Categories
            buildTile(
              icon: Icons.category,
              title: "Manage Items",
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageItemsScreen()),
                );
              },
            ),

            // 5️⃣ View Reports
            buildTile(
              icon: Icons.bar_chart,
              title: "View Reports",
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                );
              },
            ),

            // 6️⃣ Settings
            buildTile(
              icon: Icons.settings,
              title: "Admin Notifications",
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder Screens










