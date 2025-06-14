import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),

    );
  }
}
