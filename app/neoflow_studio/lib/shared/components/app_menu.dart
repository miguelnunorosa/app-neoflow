import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:neoflow_studio/core/constants.dart';

import '../../data/user_repo.dart';
import '../../models/user_account.dart';
import '../../features/schedule/week_view.dart';

class AppMenu extends StatelessWidget {
  const AppMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header com dados do Firestore
          StreamBuilder<UserAccount?>(
            stream: UserRepo().currentUserStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final ua = snap.data;
              final name = (ua == null || ua.displayName.isEmpty)
                  ? 'Utilizador'
                  : ua.displayName;
              final email = ua?.email ?? 'email não disponível';
              final photoUrl = ua?.photoUrl;

              final imgProvider = (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl) as ImageProvider
                  : const AssetImage('assets/images/profile.png');

              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: APP_PRIMARY_COLOR),
                accountName: Text(
                  name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(email),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: imgProvider,
                  backgroundColor: Colors.white,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Text(_initials(name),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ))
                      : null,
                ),
                otherAccountsPictures: [
                  if (ua != null && ua.isActive == false)
                    const Tooltip(
                      message: 'Conta inativa',
                      child: Icon(Icons.lock_outline, color: Colors.white),
                    ),
                ],
              );
            },
          ),

          // Opções
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 20),
              children: [
                ListTile(
                  leading: const Icon(Icons.account_circle, color: APP_PRIMARY_COLOR),
                  title: const Text('Dados Pessoais'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: navegar para página de perfil/edição
                  },
                ),

                // Agendamento (bloqueado se a conta estiver inativa)
                StreamBuilder<UserAccount?>(
                  stream: UserRepo().currentUserStream(),
                  builder: (context, snap) {
                    final isActive = snap.data?.isActive ?? false;
                    return ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Agendamento'),
                      subtitle: isActive ? null : const Text(
                        'Conta inativa',
                        style: TextStyle(color: Colors.red),
                      ),
                      enabled: isActive,
                      onTap: isActive
                          ? () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const WeekScheduleView()),
                        );
                      }
                          : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('A tua conta está inativa. Contacta o estúdio.'),
                          ),
                        );
                      },
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Aulas anteriores'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: navegar para histórico
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.contacts),
                  title: const Text('Contactos'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: navegar para contactos
                  },
                ),
              ],
            ),
          ),

          // Sair
          ListTile(
            leading: const Icon(Icons.logout, color: APP_PRIMARY_COLOR),
            title: const Text('Sair'),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }

  String _initials(String nameOrEmail) {
    final s = nameOrEmail.trim();
    if (s.isEmpty) return '?';
    final parts = s.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
