// lib/features/schedule/schedule_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class ScheduleRepo {
  final _db = FirebaseFirestore.instance;

  Future<List<ClassTemplate>> fetchActiveTemplates() async {
    // Se todos já têm isActive:
    final qs = await _db
        .collection('classTemplates')
        .where('isActive', isEqualTo: true)
        .get();

    // Se ainda tens alguns com 'ative', usa apenas .get() e filtra em memória:
    // final qs = await _db.collection('classTemplates').get();

    final list = qs.docs.map((d) => ClassTemplate.fromFirestore(d)).toList();

    // se usaste .get() geral:
    // final list = qs.docs
    //     .map((d) => ClassTemplate.fromFirestore(d))
    //     .where((t) => t.isActive)
    //     .toList();

    // opcional: ordenar por weekday + hora
    list.sort((a, b) {
      final c = a.weekday.compareTo(b.weekday);
      if (c != 0) return c;
      return a.startTime.compareTo(b.startTime);
    });

    return list;
  }
}
