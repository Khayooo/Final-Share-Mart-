import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'DonorVerificationScreen.dart';
import 'LoginScreen.dart';
import 'ProfileInformationScreen.dart';
import 'SavedItemsScreen.dart';
import 'MyAdds.dart';
import 'HomePage.dart';
import 'DonationItems.dart';
import 'Widgets/ApprovedDonorPage.dart';
import 'Widgets/PendingVerificationPage.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;

  // User data - will be loaded from Firebase
  Map<String, String> userData = {
    'name': 'Loading...',
    'email': 'Loading...',
    'phone': '',
    'address': '',
    'profileImage': '',
  };

  @override
  void initState() {
    super.initState();
    timeDilation = 1.5;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('Loading user data for UID: ${user.uid}'); // Debug log
        final snapshot = await _database.ref('users/${user.uid}').get();

        if (snapshot.exists) {
          print('User data found in database'); // Debug log
          final data = Map<String, dynamic>.from(snapshot.value as Map);

          setState(() {
            userData = {
              'name': data['name']?.toString() ?? 'User',
              'email': data['email']?.toString() ?? user.email ?? 'No email',
              'phone': data['phone']?.toString() ?? '',
              'address': data['address']?.toString() ?? '',
              'profileImage': data['profileImage']?.toString() ?? '',
            };
            _isLoading = false;
          });
        } else {
          print('No user data found, using default values'); // Debug log
          // Use Firebase Auth data as fallback
          setState(() {
            userData = {
              'name': user.displayName ?? 'User',
              'email': user.email ?? 'No email',
              'phone': '',
              'address': '',
              'profileImage': '',
            };
            _isLoading = false;
          });
        }
      } else {
        print('No authenticated user found'); // Debug log
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e'); // Debug log
      setState(() {
        userData = {
          'name': 'Error loading data',
          'email': 'Error loading data',
          'phone': '',
          'address': '',
          'profileImage': '',
        };
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  Widget _buildProfileImage() {
    const double imageSize = 80;

    if (_isLoading) {
      return Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.deepPurple.shade100,
        ),
        child: const CircularProgressIndicator(
          color: Colors.deepPurple,
          strokeWidth: 2,
        ),
      );
    }

    // Check if we have a profile image
    if (userData['profileImage'] != null && userData['profileImage']!.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(userData['profileImage']!);
        return Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: MemoryImage(bytes),
              fit: BoxFit.cover,
            ),
            border: Border.all(
              color: Colors.deepPurple.shade200,
              width: 2,
            ),
          ),
        );
      } catch (e) {
        print('Error decoding profile image: $e');
        // Fall back to default icon if image decoding fails
      }
    }

    // Default profile icon
    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.deepPurple.shade100,
        border: Border.all(
          color: Colors.deepPurple.shade200,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.person,
        size: 40,
        color: Colors.deepPurple,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

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
          "My Account",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadUserData();
            },
          ),
        ],
      ),
      body: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: Column(
              children: [
                // User Profile Card
                _buildProfileCard(size, isSmallScreen),
                const SizedBox(height: 24),

                // Account Options
                _buildAccountOption(
                  icon: Icons.post_add,
                  title: "My Adds",
                  subtitle: "View and manage your donation posts",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyAddsScreen(),
                      ),
                    );
                  },
                ),
                _buildAccountOption(
                  icon: Icons.favorite,
                  title: "Saved Items",
                  subtitle: "View your favorite donations",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavedItemsScreen(),
                      ),
                    );
                  },
                ),
                _buildAccountOption(
                  icon: Icons.person,
                  title: "Profile Information",
                  subtitle: "Update your personal details",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileInformationScreen(
                          userData: userData,
                          onSave: (updatedData) {
                            setState(() {
                              userData = updatedData;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
                _buildAccountOption(
                  icon: Icons.verified_user,
                  title: "Verify Donner",
                  subtitle: "Get verified to receive donations",
                    onTap: () async {
                      final currentUser = FirebaseAuth.instance.currentUser;

                      if (currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please sign in first.")),
                        );
                        return;
                      }

                      final uid = currentUser.uid;
                      final dbRef = FirebaseDatabase.instance.ref("donor_verifications");

                      try {
                        final snapshot = await dbRef.orderByChild("userId").equalTo(uid).once();

                        if (snapshot.snapshot.exists) {
                          final data = snapshot.snapshot.value as Map;

                          final firstEntry = data.entries.first.value as Map<dynamic, dynamic>;
                          final status = firstEntry['status'];

                          if (status == 'pending') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PendingVerificationPage(),
                              ),
                            );
                          } else if (status == 'approved') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ApprovedDonorPage(),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Unexpected status: $status")),
                            );
                          }
                        } else {
                          // No verification record found
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DonorVerificationScreen(),
                            ),
                          );
                        }
                      } catch (e) {
                        print("Error accessing Realtime Database: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Something went wrong.")),
                        );
                      }
                    }

                ),
                _buildAccountOption(
                  icon: Icons.star,
                  title: "Reviews & Ratings",
                  subtitle: "See your donation history",
                  onTap: () {
                    // Navigate to reviews
                  },
                ),
                const SizedBox(height: 24),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Logout",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(Size size, bool isSmallScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Image with loading state
            _buildProfileImage(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name with loading state
                  _isLoading
                      ? Container(
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                      : Text(
                    userData['name']!,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Email with loading state
                  _isLoading
                      ? Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                      : Text(
                    userData['email']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status indicator (you can customize this)
                  if (!_isLoading) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Active User",
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.deepPurple),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple.shade800,
          ),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        trailing: Icon(Icons.chevron_right, color: Colors.deepPurple.shade300),
      ),
    );
  }
}