import 'package:campus_saga/presentation/pages/profile/profile_page.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        centerTitle: true,
        title: Text(
          "Campus Saga",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomButton(
                  text: "Add University",
                  onPressed: () {
                    //pushnamed
                    Navigator.pushNamed(context, '/addUniversity');
                  },
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: "Add Authority",
                  onPressed: () {},
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: "Add Admin",
                  onPressed: () {},
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: "User Verification",
                  onPressed: () {
                    Navigator.pushNamed(context, '/userVerification');
                  },
                ),
              ],
            )),
      ),
    );
  }
}
