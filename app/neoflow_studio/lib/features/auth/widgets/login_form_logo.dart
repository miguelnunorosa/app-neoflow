import 'package:flutter/material.dart';





class LoginFormLogo extends StatelessWidget {
  const LoginFormLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
      ],
    );
  }
}
