import 'package:cloud_firestore/cloud_firestore.dart';

import 'models.dart';

class ScheduleRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Lê as aulas (classTemplates) ativas e devolve ordenadas:
  /// primeiro por dia da semana (1..7), depois por hora ("HH:mm").
  Future<List<ClassTemplate>> fetchActiveTemplates() async {
    // Se TODOS os docs já têm isActive:
    // final qs = await _db
    //     .collection('classTemplates')
    //     .where('isActive', isEqualTo: true)
    //     .get();

    // Se ainda podes ter alguns com campo legado 'ative', lê todos e filtra em memória:
    final qs = await _db.collection('classTemplates').get();

    final list = qs.docs
        .map((d) => ClassTemplate.fromFirestore(d))
        .where((t) => t.isActive) // filtra ativos
        .toList();

    // ordenar por weekday + startTime
    list.sort((a, b) {
      final c = a.weekday.compareTo(b.weekday);
      if (c != 0) return c;
      return a.startTime.compareTo(b.startTime);
    });

    return list;
  }
}
