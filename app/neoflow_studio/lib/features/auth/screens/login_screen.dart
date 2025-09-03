import 'package:flutter/material.dart';
import '../widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/images/logo.png',
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    "NeoFlow",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A3735),
                    ),
                  );
                },
              ),

              const SizedBox(height: 150),

              const LoginForm(), // Formulário de login
            ],
          ),
        ),
      ),
    );
  }
}
