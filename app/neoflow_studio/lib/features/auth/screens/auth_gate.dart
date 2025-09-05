import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../home/screens/home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Carregando...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Utilizador autenticado → vai para Home
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Não autenticado → Login
        return const LoginScreen();
      },
    );
  }
}
