import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/components/app_menu.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("NeoFlow - Home"),
        actions: [
          /*IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),*/
        ],
      ),
      drawer: const AppMenu(),
      body: Center(
        child: Text("Bem-vindo, ${user?.email ?? 'Utilizador'}!"),
      ),
    );
  }
}
