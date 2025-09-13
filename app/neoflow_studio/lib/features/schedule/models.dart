import 'package:cloud_firestore/cloud_firestore.dart';

class ClassTemplate {
  final String id;
  final String name;
  final int weekday;        // 1..7 (1=Seg, 7=Dom)
  final String startTime;   // "HH:mm"
  final int durationMin;    // duração em minutos
  final int capacity;       // capacidade da aula
  final bool isActive;

  ClassTemplate({
    required this.id,
    required this.name,
    required this.weekday,
    required this.startTime,
    required this.durationMin,
    required this.capacity,
    required this.isActive,
  });

  factory ClassTemplate.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final wdRaw = data['weekday'];
    if (wdRaw is! int) {
      throw StateError(
        "classTemplates/${doc.id} sem 'weekday' (int). Define 1..7 (1=Seg .. 7=Dom).",
      );
    }
    final wd = wdRaw.clamp(1, 7);

    return ClassTemplate(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      weekday: wd,
      startTime: (data['startTime'] ?? '00:00') as String,
      durationMin: (data['durationMin'] is int) ? data['durationMin'] as int : 60,
      capacity: (data['capacity'] is int) ? data['capacity'] as int : 10,
      // aceita 'isActive' ou (legado) 'ative'
      isActive: (data['isActive'] is bool)
          ? data['isActive'] as bool
          : (data['ative'] is bool ? data['ative'] as bool : true),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'weekday': weekday,
    'startTime': startTime,
    'durationMin': durationMin,
    'capacity': capacity,
    'isActive': isActive,
  };
}
