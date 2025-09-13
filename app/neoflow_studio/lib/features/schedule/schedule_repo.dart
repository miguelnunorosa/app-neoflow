import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class ScheduleRepo {
  final _db = FirebaseFirestore.instance;

  /// Lê todos os templates ativos, ordenados por weekday e startTime.
  Future<List<ClassTemplate>> fetchActiveTemplates() async {
    final q = await _db
        .collection('classTemplates')
        .where('isActive', isEqualTo: true)
        .get();

    final list = q.docs
        .map((d) => ClassTemplate.fromMap(d.id, d.data()))
        .toList();

    list.sort((a, b) {
      final wd = a.weekday.compareTo(b.weekday);
      if (wd != 0) return wd;
      return a.startTime.compareTo(b.startTime);
    });

    return list;
  }
}
