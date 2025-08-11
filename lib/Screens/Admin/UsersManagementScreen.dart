import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  List<Map<dynamic, dynamic>> allUsers = [];
  List<Map<dynamic, dynamic>> filteredUsers = [];
  bool loading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void fetchUsers() {
    dbRef.child("users").onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        // Ensure each user record has its Firebase key as userId
        final usersList = data.entries.map((entry) {
          final userMap = Map<dynamic, dynamic>.from(entry.value);
          userMap["userId"] = entry.key; // <-- Always set userId
          return userMap;
        }).toList();

        setState(() {
          allUsers = usersList;
          filteredUsers = usersList;
          loading = false;
        });
      } else {
        setState(() {
          allUsers = [];
          filteredUsers = [];
          loading = false;
        });
      }
    });
  }

  void searchUsers(String query) {
    setState(() {
      searchQuery = query;
      filteredUsers = allUsers.where((user) {
        final name = (user["name"] ?? "").toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  void showUserDetails(Map<dynamic, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (user["profileImage"] != null &&
                    user["profileImage"].toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.memory(
                      const Base64Decoder().convert(user["profileImage"]),
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    child: const Icon(Icons.person, size: 50),
                  ),
                const SizedBox(height: 12),
                Text(
                  user["name"] ?? "No Name",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("Email: ${user["email"] ?? "No Email provided"}",
                    style: const TextStyle(fontSize: 14)),
                Text("Phone: ${user["phone"] ?? "No Number provided"}",
                    style: const TextStyle(fontSize: 14)),
                Text("Address: ${user["address"] ?? "No Address provided"}",
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text("Close",
                          style: TextStyle(color: Colors.white)),
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade500),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text("Delete",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                      onPressed: () {
                        final uid = user["uid"];
                        if (uid != null && uid is String && uid.isNotEmpty) {
                          Navigator.pop(context);
                          deleteUser(uid);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Invalid user ID. Cannot delete."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> deleteUser(String userId) async {
    try {
      await dbRef.child("users").child(userId).remove();
      await _deleteByUserId("items", userId);
      await _deleteByUserId("donations", userId);
      await _deleteByUserId("request product", userId);
      await _deleteByUserId("exchange_products", userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User and related data deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting user: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteByUserId(String table, String userId) async {
    final snapshot = await dbRef.child(table).once();
    if (snapshot.snapshot.exists) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) async {
        if (value["userId"] == userId) {
          await dbRef.child(table).child(key).remove();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Users Management",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4)
                ],
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Search by name...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: searchUsers,
              ),
            ),
          ),
          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(child: Text("No users found"))
                : ListView.builder(
              itemCount: filteredUsers.length,
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12, blurRadius: 6)
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: user["profileImage"] != null &&
                          user["profileImage"]
                              .toString()
                              .isNotEmpty
                          ? MemoryImage(const Base64Decoder()
                          .convert(user["profileImage"]))
                          : null,
                      child: user["profileImage"] == null ||
                          user["profileImage"]
                              .toString()
                              .isEmpty
                          ? const Icon(Icons.person, size: 28)
                          : null,
                    ),
                    title: Text(user["name"] ?? "No Name",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    subtitle:
                    Text(user["email"] ?? "No Email provided"),
                    onTap: () => showUserDetails(user),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
