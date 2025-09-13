import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:neoflow_studio/core/constants.dart';

import '../../data/user_repo.dart';
import '../../models/user_account.dart';

// Screens
import '../../features/schedule/week_view.dart';
import '../../features/schedule/my_bookings_view.dart';

class AppMenu extends StatelessWidget {
  const AppMenu({super.key});

  String _initials(String nameOrEmail) {
    final s = nameOrEmail.trim();
    if (s.isEmpty) return '?';
    final parts = s.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final repo = UserRepo();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header com dados do Firestore
          StreamBuilder<UserAccount?>(
            stream: repo.currentUserStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final ua = snap.data;

              // Nome preferencial: firstName + lastName; fallback -> displayName; fallback final -> "Utilizador"
              final fullName = () {
                if (ua == null) return 'Utilizador';
                final fn = (ua.firstName ?? '').trim();
                final ln = (ua.lastName ?? '').trim();
                final joined = [fn, ln].where((p) => p.isNotEmpty).join(' ');
                if (joined.isNotEmpty) return joined;
                if (ua.displayName.isNotEmpty) return ua.displayName;
                return 'Utilizador';
              }();

              final email = ua?.email ?? 'email não disponível';
              final photoUrl = ua?.photoUrl;

              final imgProvider = (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl) as ImageProvider
                  : const AssetImage('assets/images/defaultUserPhoto.png');

              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: APP_PRIMARY_COLOR),
                accountName: Text(
                  fullName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(email),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: imgProvider,
                  backgroundColor: Colors.white,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Text('',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  )
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
                  stream: repo.currentUserStream(),
                  builder: (context, snap) {
                    final ua = snap.data;
                    final isActive = ua?.isActive ?? false;
                    return ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Agendamento'),
                      subtitle: isActive
                          ? null
                          : const Text(
                        'Conta inativa',
                        style: TextStyle(color: Colors.red),
                      ),
                      enabled: isActive,
                      onTap: isActive
                          ? () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WeekScheduleView(),
                          ),
                        );
                      }
                          : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'A tua conta está inativa. Contacta o estúdio.',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.event_note),
                  // Dica: podes renomear para 'Minhas inscrições'
                  title: const Text('Aulas Anteriores'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyBookingsView()),
                    );
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

                const Divider(),

                // ===== Secção ADMIN via UserRepo().isAdmin(uid) =====
                if (uid != null)
                  FutureBuilder<bool>(
                    future: repo.isAdmin(uid),
                    builder: (context, snap) {
                      final isAdmin = snap.data == true;
                      if (!isAdmin) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'Admin',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.edit_calendar, color: APP_PRIMARY_COLOR),
                            title: const Text('Gerir aulas'),
                            onTap: () {
                              Navigator.pop(context);
                              // TODO: abrir ecrã de gestão de classTemplates
                            },
                          ),
                        ],
                      );
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
}
