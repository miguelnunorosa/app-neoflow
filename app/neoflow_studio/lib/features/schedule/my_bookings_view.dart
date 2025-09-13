import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'class_booking_service.dart';

class MyBookingsView extends StatelessWidget {
  const MyBookingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Tens de iniciar sessão.')),
      );
    }

    final svc = ClassBookingService();

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas inscrições')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: svc.myUpcomingBookingsStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Ainda não tens inscrições futuras.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final b = items[i];

              final className  = (b['className'] ?? '') as String;
              final dateStr    = (b['date'] ?? '') as String;     // "YYYY-MM-DD"
              final timeStr    = (b['time'] ?? '') as String;     // "HH:mm"
              final templateId = (b['classTemplateId'] ?? '') as String;

              final sessionDT  = _parseDateTime(dateStr, timeStr);
              final subtitle   = _formatCardDate(sessionDT, timeStr);

              final now               = DateTime.now();
              final isPast            = sessionDT.isBefore(now);
              final cancelDeadline    = sessionDT.subtract(const Duration(minutes: 30));
              final canCancel         = now.isBefore(cancelDeadline); // só até 30min antes

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        child: Text(timeStr, style: const TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              className,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(subtitle, style: TextStyle(color: Colors.grey[700])),
                            const SizedBox(height: 6),
                            Text(
                              isPast ? 'Realizada' : '✅ Inscrito',
                              style: TextStyle(
                                color: isPast ? Colors.redAccent : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!isPast && !canCancel) ...[
                              const SizedBox(height: 4),
                              const Text(
                                'Cancelamento bloqueado (≤ 30 min)',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botão de cancelar:
                      // - não aparece se a aula já passou
                      // - aparece DESATIVADO se já estamos a ≤30min do início
                      // - aparece ATIVO se estamos a mais de 30min
                      if (!isPast)
                        TextButton(
                          onPressed: canCancel
                              ? () async {
                            try {
                              await svc.cancelBookingByKey(
                                templateId: templateId,
                                date: sessionDT,
                                userId: uid,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Inscrição cancelada.')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text('$e')));
                              }
                            }
                          }
                              : null, // desativado se dentro da janela de 30 min
                          child: Text(canCancel ? 'Cancelar' : 'Cancelar'),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  DateTime _parseDateTime(String yyyyMmDd, String hhmm) {
    // yyyyMmDd = "YYYY-MM-DD", hhmm = "HH:mm"
    final dParts = yyyyMmDd.split('-');
    final tParts = hhmm.split(':');
    final y = int.tryParse(dParts.elementAt(0)) ?? 1970;
    final m = int.tryParse(dParts.elementAt(1)) ?? 1;
    final d = int.tryParse(dParts.elementAt(2)) ?? 1;
    final h = int.tryParse(tParts.elementAt(0)) ?? 0;
    final min = int.tryParse(tParts.elementAt(1)) ?? 0;
    return DateTime(y, m, d, h, min);
  }

  String _formatCardDate(DateTime d, String time) {
    final weekdayShort = DateFormat.E('pt_PT').format(d);
    final dayMonth = DateFormat('dd/MM/yyyy').format(d);
    return '$weekdayShort, $dayMonth | $time';
  }
}
