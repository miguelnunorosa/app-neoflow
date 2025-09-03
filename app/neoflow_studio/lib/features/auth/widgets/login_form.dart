import 'package:flutter/material.dart';
import '../../../shared/components/custom_button.dart';
import '../../../shared/components/custom_text_field.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          controller: emailController,
          label: "Email",
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: passwordController,
          label: "Password",
          icon: Icons.lock_outline,
          obscureText: true,
        ),
        const SizedBox(height: 50),
        CustomButton(
          text: "Entrar",
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Login clicado")),
            );
          },
        ),
        // Memorizar login
        Row(
          children: [
            Checkbox(
              value: rememberMe,
              activeColor: const Color(0xFF3A3735),
              onChanged: (value) {
                setState(() {
                  rememberMe = value ?? false;
                });
              },
            ),
            const Text("Memorizar login"),
          ],
        ),
      ],
    );
  }
}
