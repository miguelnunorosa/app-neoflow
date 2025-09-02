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
              height: 250,
            ),
              const SizedBox(height: 30),


              const SizedBox(height: 50),

              // Formulário de login
              const LoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}
