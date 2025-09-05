import 'package:flutter/material.dart';
import 'package:neoflow_studio/features/auth/widgets/login_form_logo.dart';
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
              const LoginFormLogo(),

              const SizedBox(height: 150),

              const LoginForm(), // Formulário de login
            ],
          ),
        ),
      ),
    );
  }
}
