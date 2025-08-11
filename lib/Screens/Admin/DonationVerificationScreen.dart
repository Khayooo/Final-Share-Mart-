import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DonationVerificationScreen extends StatelessWidget {
  const DonationVerificationScreen ({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Donar Verification" , style: TextStyle(
          color: Colors.white
      ),),
      backgroundColor: Colors.deepPurple,
    ),
  );
}