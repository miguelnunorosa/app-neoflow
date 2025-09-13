import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models.dart';
import 'date_utils.dart';

/// Coleção flat para inscrições de aulas.
/// Cada doc representa UMA inscrição do utilizador numa aula (template) numa data concreta.
class ClassBookingService {
  ClassBookingService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// ID determinístico para evitar duplicados por (template + data + user)
  /// Ex.: seg_aula01_2025-09-16_tfb8wfe...
  String bookingId({
    required String templateId,
    required DateTime date,
    required String userId,
  }) =>
      '${templateId}_${yyyy_mm_dd(date)}_$userId';

  /// Referência ao doc em `classBooking/{bookingId}`
  DocumentReference<Map<String, dynamic>> _bookingRef({
    required String templateId,
    required DateTime date,
    required String userId,
  }) {
    final id = bookingId(templateId: templateId, date: date, userId: userId);
    return _db.collection('classBooking').doc(id);
  }

  /// Cria (ou reativa) a inscrição do utilizador para o template na data.
  /// - status inicial: "confirmed" (sem gestão de lotação nesta versão)
  /// - se já existia e estava 'cancelled', volta a 'confirmed'
  Future<void> createOrConfirmBooking({
    required ClassTemplate template,
    required DateTime date,
    required String userId,
  }) async {
    final ref = _bookingRef(
      templateId: template.id,
      date: date,
      userId: userId,
    );

    await ref.set({
      'userId': userId,
      'classTemplateId': template.id,
      'className': template.name,
      'date': yyyy_mm_dd(date), // "YYYY-MM-DD"
      'time': template.startTime, // "HH:mm"
      'status': 'confirmed', // nesta fase simples não há lista de espera
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Cancela a inscrição do utilizador.
  Future<void> cancelBooking({
    required ClassTemplate template,
    required DateTime date,
    required String userId,
  }) async {
    final ref = _bookingRef(
      templateId: template.id,
      date: date,
      userId: userId,
    );

    final snap = await ref.get();
    if (!snap.exists) return; // nada a cancelar

    await ref.update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  /// Lê o estado do utilizador para este template+data.
  /// devolve: null (sem inscrição ou cancelada) | 'confirmed'
  Stream<String?> myStatusStream({
    required ClassTemplate template,
    required DateTime date,
    required String userId,
  }) {
    final ref = _bookingRef(
      templateId: template.id,
      date: date,
      userId: userId,
    );

    return ref.snapshots().map((snap) {
      if (!snap.exists) return null;
      final status = snap.data()?['status'] as String?;
      if (status == null || status == 'cancelled') return null;
      return status; // 'confirmed' (versão simples)
    });
  }

  /// Lista as MINHAS inscrições (por data >= hoje), ordenadas por data/hora.
  Stream<List<Map<String, dynamic>>> myUpcomingBookingsStream(String userId) {
    final today = yyyy_mm_dd(DateTime.now());
    return _db
        .collection('classBooking')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: today)
        .snapshots()
        .map((qs) {
      final items = qs.docs
          .map((d) => d.data())
          .where((m) => (m['status'] ?? '') != 'cancelled')
          .toList();

      items.sort((a, b) {
        final da = (a['date'] as String?) ?? '';
        final db = (b['date'] as String?) ?? '';
        final ta = (a['time'] as String?) ?? '';
        final tb = (b['time'] as String?) ?? '';
        final cmp = da.compareTo(db);
        return cmp != 0 ? cmp : ta.compareTo(tb);
      });
      return items;
    });
  }
}
