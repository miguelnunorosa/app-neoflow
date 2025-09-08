import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:neoflow_studio/core/constants.dart';

class AppMenu extends StatelessWidget {
  const AppMenu({super.key});


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Topo - Foto e Nome
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: APP_PRIMARY_COLOR, // cor de fundo
            ),

            accountName: Text(
              user?.displayName ?? "Utilizador",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            accountEmail: Text(user?.email ?? "email não disponível"),

            currentAccountPicture: CircleAvatar(
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : const AssetImage("assets/images/profile.png")
              as ImageProvider,
              backgroundColor: Colors.white,
            ),

          ),

          // Centro - opções
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 20), // sobe os itens
              children: [

                ListTile(
                  leading: const Icon(Icons.account_circle, color: APP_PRIMARY_COLOR),
                  title: const Text("Dados Pessoais"),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: implementar
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text("Agendamento"),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: navegar para página de agendamento
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text("Aulas anteriores"),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: navegar para página de aulas anteriores
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.contacts),
                  title: const Text("Contactos"),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: navegar para página de contactos
                  },
                ),

              ],
            ),
          ),

          // Baixo - sair
          ListTile(
            leading: const Icon(Icons.logout, color: APP_PRIMARY_COLOR),
            title: const Text("Sair"),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}