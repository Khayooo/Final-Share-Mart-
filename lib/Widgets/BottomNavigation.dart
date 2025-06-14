import 'package:flutter/material.dart';
import '../AccountScreen.dart';
import '../Chats/ChatsScreen.dart';
import '../DonationItems.dart';


class BottomNavigator extends StatelessWidget {
  const BottomNavigator({super.key});

  void _showAddItemDialog(BuildContext context) {
    // TODO: Implement your add item dialog here
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Item"),
        content: const Text("Add item form goes here."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey.shade500,
          backgroundColor: Colors.white,
          showUnselectedLabels: true,
          elevation: 10,
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DonationItemsScreen()),
              );
            } else if (index == 2) {
              _showAddItemDialog(context);
            } else if (index == 4) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountScreen()),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatsScreen()),
              );
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: "Home",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism),
              label: "Donations",
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              label: "",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: "Chats",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "Account",
            ),
          ],
        ),
      ),
    );
  }
}
