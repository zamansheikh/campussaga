import 'package:campus_saga/domain/entities/user.dart';
import 'package:campus_saga/presentation/pages/admin/role_mange_page.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  final User user;
  const AdminPage({required this.user, super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        centerTitle: true,
        title: const Text(
          "Campus Saga",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Image.asset(
                  'assets/images/admin.png', // Replace with actual path to logo
                  height: 100,
                ),
              ),
              const SizedBox(height: 24),
              // Custom Buttons
              CustomButton(
                text: "Add University",
                onPressed: () {
                  Navigator.pushNamed(context, '/addUniversity');
                },
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: "Role Management",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoleMangePage(
                        user: widget.user,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: "User Verification",
                onPressed: () {
                  Navigator.pushNamed(context, '/userVerification');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const CustomButton({required this.text, required this.onPressed, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}
