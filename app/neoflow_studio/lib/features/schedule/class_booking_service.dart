import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';
import 'date_utils.dart';

/// Service para gerir inscrições na coleção "classBooking" (estrutura plana).
/// - Cada documento representa UMA inscrição de um utilizador numa aula (template) numa data.
/// - ID determinístico para evitar duplicados: {templateId}_{YYYY-MM-DD}_{userId}
class ClassBookingService {
  ClassBookingService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Gera um ID único e determinístico por (template + data + utilizador)
  String bookingId({
    required String templateId,
    required DateTime date,
    required String userId,
  }) =>
      '${templateId}_${yyyy_mm_dd(date)}_$userId';

  /// Referência ao documento em `classBooking/{bookingId}`
  DocumentReference<Map<String, dynamic>> _bookingRef({
    required String templateId,
    required DateTime date,
    required String userId,
  }) {
    final id = bookingId(templateId: templateId, date: date, userId: userId);
    return _db.collection('classBooking').doc(id);
  }

  /// Junta date + startTime -> DateTime (local)
  DateTime _sessionDateTime(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.elementAt(0)) ?? 0;
    final m = int.tryParse(parts.elementAt(1)) ?? 0;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  /// Cria (ou reativa) a inscrição do utilizador para o template na data.
  /// - status inicial: "confirmed" (nesta versão simples não há lista de espera)
  /// - grava também `sessionAt` (Timestamp) para regras de cancelamento
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

    final sessionAt = _sessionDateTime(date, template.startTime);

    await ref.set({
      'userId': userId,
      'classTemplateId': template.id,
      'className': template.name,
      'date': yyyy_mm_dd(date),      // "YYYY-MM-DD"
      'time': template.startTime,    // "HH:mm"
      'sessionAt': Timestamp.fromDate(sessionAt), // <--- IMPORTANTE
      'status': 'confirmed',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Cancela a inscrição do utilizador (usando objeto ClassTemplate).
  Future<void> cancelBooking({
    required ClassTemplate template,
    required DateTime date,
    required String userId,
  }) async {
    await cancelBookingByKey(
      templateId: template.id,
      date: date,
      userId: userId,
    );
  }

  /// Cancela a inscrição do utilizador (usando apenas chaves).
  Future<void> cancelBookingByKey({
    required String templateId,
    required DateTime date,
    required String userId,
  }) async {
    final ref = _bookingRef(
      templateId: templateId,
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

  /// Stream do estado do utilizador para este template+data.
  /// devolve: null (sem inscrição/ cancelada) | 'confirmed'
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
      return status; // 'confirmed'
    });
  }

  /// Stream das MINHAS inscrições futuras (date >= hoje), ordenadas por data/hora.
  /// Filtra no cliente por status != 'cancelled' para evitar mostrar canceladas.
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
