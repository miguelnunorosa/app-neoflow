import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';
import 'date_utils.dart';

class ScheduleRepo {
  final _db = FirebaseFirestore.instance;

  Future<List<ClassTemplate>> _fetchActiveTemplates() async {
    final q = await _db
        .collection('classTemplates')
        .where('active', isEqualTo: true)
        .get();
    return q.docs.map((d) => ClassTemplate.fromMap(d.id, d.data())).toList();
  }

  /// Devolve as sessões (VMs) para a semana que começa em [monday] (inclusive).
  Future<List<SessionVM>> getWeekSessions(DateTime monday) async {
    final templates = await _fetchActiveTemplates();

    // 7 dias: seg..dom
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    final futures = <Future<SessionVM>>[];

    for (final t in templates) {
      final d = days[t.weekday - 1];
      final id = '${t.id}_${yyyymmdd(d)}';
      final ref = _db.collection('sessions').doc(id);

      futures.add(ref.get().then((snap) {
        final data = snap.data();
        final confirmed = data == null ? 0 : (data['confirmedCount'] ?? 0) as int;
        final waitlist = data == null ? 0 : (data['waitlistCount'] ?? 0) as int;

        return SessionVM(
          sessionId: id,
          name: t.name,
          date: d,
          startTime: t.startTime,
          capacity: t.capacity,
          confirmedCount: confirmed,
          waitlistCount: waitlist,
        );
      }));
    }

    final list = await Future.wait(futures);
    list.sort((a, b) {
      final cmpDate = a.date.compareTo(b.date);
      if (cmpDate != 0) return cmpDate;
      return a.startTime.compareTo(b.startTime);
    });
    return list;
  }
}
