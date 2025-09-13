import 'package:cloud_firestore/cloud_firestore.dart';

import 'models.dart';
import 'date_utils.dart';

class ClassBookingService {
  final _db = FirebaseFirestore.instance;

  /// ID do documento em classBooking (plano)
  String bookingDocId(ClassTemplate t, DateTime day, String uid) {
    return '${t.id}_${yyyy_mm_dd(day)}_$uid';
    // ex.: abc123_2025-09-13_uid
  }

  /// Mesmo padrão, mas sem precisar do objeto template
  String bookingDocIdFromParts({
    required String templateId,
    required String dateStr, // "YYYY-MM-DD"
    required String uid,
  }) {
    return '${templateId}_${dateStr}_$uid';
  }

  DocumentReference<Map<String, dynamic>> bookingRef(
      ClassTemplate t,
      DateTime day,
      String uid,
      ) {
    return _db.collection('classBooking').doc(bookingDocId(t, day, uid));
  }

  /// Cria (ou confirma) inscrição do utilizador para a sessão.
  /// Regras exigem: userId == auth.uid e sessionAt (timestamp) no CREATE.
  /// Se o doc já existir (ex: foi cancelado antes), faz UPDATE só de status/cancelledAt,
  /// que é o que as regras permitem.
  Future<void> createOrConfirmBooking({
    required ClassTemplate template,
    required DateTime date,
    required String userId,
  }) async {
    final ref = bookingRef(template, date, userId);
    final snap = await ref.get();

    if (!snap.exists) {
      // --- CREATE (doc novo) ---
      final parts = template.startTime.split(':');
      final h = int.tryParse(parts.elementAt(0)) ?? 0;
      final m = int.tryParse(parts.elementAt(1)) ?? 0;
      final sessionAt = DateTime(date.year, date.month, date.day, h, m);

      await ref.set({
        'userId': userId,
        'classTemplateId': template.id,
        'className': template.name,
        'date': yyyy_mm_dd(date),     // "YYYY-MM-DD"
        'time': template.startTime,   // "HH:mm"
        'sessionAt': Timestamp.fromDate(sessionAt),
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
        // extras úteis
        'weekday': template.weekday,
        'capacity': template.capacity,
        'durationMin': template.durationMin,
      }, SetOptions(merge: true));
    } else {
      // --- UPDATE (reinscrição) ---
      // Só altera o que as regras permitem: status/cancelledAt
      await ref.update({
        'status': 'confirmed',
        'cancelledAt': FieldValue.delete(),
      });
    }
  }

  /// Cancela a inscrição do utilizador para a sessão (via objeto).
  /// (Regras só permitem atualizar 'status' e 'cancelledAt')
  Future<void> cancelBooking({
    required ClassTemplate template,
    required DateTime date,
    required String userId,
  }) async {
    final ref = bookingRef(template, date, userId);
    await ref.update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cancela usando a chave {templateId}_{YYYY-MM-DD}_{uid}.
  /// Aceita 'date' (DateTime) OU 'dateStr' ("YYYY-MM-DD") e
  /// aceita 'uid' OU 'userId' (alias para compatibilidade com a UI).
  Future<void> cancelBookingByKey({
    required String templateId,
    DateTime? date,
    String? dateStr,
    String? uid,
    String? userId,
  }) async {
    assert(date != null || dateStr != null,
    'Fornece "date" (DateTime) ou "dateStr" (YYYY-MM-DD)');
    final effectiveUid = uid ?? userId;
    assert(effectiveUid != null, 'Fornece "uid" ou "userId".');

    final ds = dateStr ?? yyyy_mm_dd(date!);
    final id = bookingDocIdFromParts(
      templateId: templateId,
      dateStr: ds,
      uid: effectiveUid!,
    );
    final ref = _db.collection('classBooking').doc(id);
    await ref.update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream do estado do utilizador na sessão: null | 'confirmed'
  Stream<String?> myStatusStream({
    required ClassTemplate template,
    required DateTime date,
    required String userId,
  }) {
    return bookingRef(template, date, userId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final st = snap.data()?['status'] as String?;
      if (st == null || st == 'cancelled') return null;
      return st; // 'confirmed'
    });
  }

  /// Stream das TUAS inscrições como lista de maps (o ecrã espera este tipo).
  Stream<List<Map<String, dynamic>>> myUpcomingBookingsStream(String uid) {
    return _db
        .collection('classBooking')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((qs) {
      return qs.docs
          .map((d) => {
        'id': d.id,
        ...d.data(),
      })
          .toList();
    });
  }
}
