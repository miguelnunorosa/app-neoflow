import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';
import 'date_utils.dart';

class BookingService {
  final _db = FirebaseFirestore.instance;

  /// ID único da sessão a partir do template + data (yyyyMMdd)
  String sessionIdFor(ClassTemplate t, DateTime day) => '${t.id}_${yyyymmdd(day)}';

  DocumentReference<Map<String, dynamic>> sessionRefFor(ClassTemplate t, DateTime day) {
    final id = sessionIdFor(t, day);
    return _db.collection('sessions').doc(id);
  }

  DocumentReference<Map<String, dynamic>> bookingRefFor(ClassTemplate t, DateTime day, String uid) {
    return sessionRefFor(t, day).collection('bookings').doc(uid);
  }

  /// Reserva: se houver vaga entra como confirmed; senão entra em lista de espera.
  /// Cria a sessão "on-demand" na primeira reserva.
  Future<String> bookSession({required ClassTemplate template, required DateTime day, required String uid}) async {
    final sRef = sessionRefFor(template, day);
    final bRef = bookingRefFor(template, day, uid);

    await _db.runTransaction((tx) async {
      final sSnap = await tx.get(sRef);
      int capacity = template.capacity;
      int confirmed = 0;
      int wait = 0;

      if (!sSnap.exists) {
        tx.set(sRef, {
          'templateRef': _db.collection('classTemplates').doc(template.id),
          'date': yyyy_mm_dd(day),              // "YYYY-MM-DD"
          'weekday': template.weekday,          // 1..7
          'startTime': template.startTime,      // "HH:mm"
          'durationMin': template.durationMin,
          'capacity': capacity,
          'confirmedCount': 0,
          'waitlistCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        final data = sSnap.data()!;
        capacity = (data['capacity'] ?? capacity) as int;
        confirmed = (data['confirmedCount'] ?? 0) as int;
        wait = (data['waitlistCount'] ?? 0) as int;
      }

      final bSnap = await tx.get(bRef);
      if (bSnap.exists) {
        final status = bSnap.data()?['status'];
        if (status == 'confirmed') {
          throw Exception('Já tens reserva confirmada nesta sessão.');
        }
        if (status == 'waitlist') {
          throw Exception('Já estás em lista de espera nesta sessão.');
        }
        // se estava "cancelled", segue para reservar de novo
      }

      if (confirmed < capacity) {
        // entra confirmado
        tx.set(bRef, {
          'userRef': _db.collection('usersAccounts').doc(uid),
          'status': 'confirmed',
          'position': null,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        tx.update(sRef, {'confirmedCount': confirmed + 1});
      } else {
        // entra em lista de espera
        final newPos = wait + 1;
        tx.set(bRef, {
          'userRef': _db.collection('usersAccounts').doc(uid),
          'status': 'waitlist',
          'position': newPos,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        tx.update(sRef, {'waitlistCount': newPos});
      }
    });

    // devolve uma mensagem simples para UI
    final doc = await bookingRefFor(template, day, uid).get();
    final status = (doc.data()?['status'] ?? 'unknown') as String;
    return status == 'confirmed' ? 'Reserva confirmada.' : 'Entraste em lista de espera.';
  }

  /// Cancelar reserva. Se estava confirmado, tenta promover o 1º da lista de espera.
  Future<String> cancelBooking({required ClassTemplate template, required DateTime day, required String uid}) async {
    final sRef = sessionRefFor(template, day);
    final bRef = bookingRefFor(template, day, uid);

    await _db.runTransaction((tx) async {
      final bSnap = await tx.get(bRef);
      if (!bSnap.exists) throw Exception('Não tinhas reserva nesta sessão.');

      final status = bSnap.data()?['status'] as String?;
      if (status == 'cancelled') throw Exception('Reserva já se encontra cancelada.');

      // marca a reserva do user como cancelada
      tx.update(bRef, {'status': 'cancelled', 'position': null});

      final sSnap = await tx.get(sRef);
      if (!sSnap.exists) return; // nada a fazer

      int confirmed = (sSnap.data()?['confirmedCount'] ?? 0) as int;
      int wait = (sSnap.data()?['waitlistCount'] ?? 0) as int;

      if (status == 'confirmed') {
        // promover o 1º da lista de espera (se existir)
        final q = await sRef.collection('bookings')
            .where('status', isEqualTo: 'waitlist')
            .orderBy('position')
            .limit(1)
            .get();

        if (q.docs.isNotEmpty) {
          final firstWaitRef = q.docs.first.reference;
          tx.update(firstWaitRef, {'status': 'confirmed', 'position': null});
          tx.update(sRef, {
            'waitlistCount': (wait - 1).clamp(0, wait),
            // confirmedCount mantém-se (saiu 1, entrou 1)
          });
        } else {
          // ninguém para promover → diminui confirmados
          tx.update(sRef, {'confirmedCount': (confirmed - 1).clamp(0, confirmed)});
        }
      } else if (status == 'waitlist') {
        // saiu da espera → baixa o contador de waitlist
        tx.update(sRef, {'waitlistCount': (wait - 1).clamp(0, wait)});
      }
    });

    return 'Reserva cancelada.';
  }

  /// Stream do estado do utilizador na sessão (null = sem reserva / cancelled)
  Stream<String?> bookingStatusStream({required ClassTemplate template, required DateTime day, required String uid}) {
    return bookingRefFor(template, day, uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final st = snap.data()?['status'] as String?;
      if (st == 'cancelled') return null;
      return st; // 'confirmed' | 'waitlist'
    });
  }

  /// Stream dos contadores da sessão (para mostrar vagas em tempo real)
  Stream<(int confirmed, int wait, int capacity)> sessionCountersStream(ClassTemplate t, DateTime day) {
    return sessionRefFor(t, day).snapshots().map((snap) {
      final data = snap.data();
      final confirmed = data == null ? 0 : (data['confirmedCount'] ?? 0) as int;
      final wait = data == null ? 0 : (data['waitlistCount'] ?? 0) as int;
      final capacity = data == null ? t.capacity : (data['capacity'] ?? t.capacity) as int;
      return (confirmed, wait, capacity);
    });
  }
}
