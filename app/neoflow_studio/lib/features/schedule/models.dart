// lib/features/schedule/models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassTemplate {
  final String id;
  final String name;
  final int weekday;      // 1..7 (1=Seg, 7=Dom)
  final String startTime; // "HH:mm"
  final int capacity;     // default 10 se não existir
  final bool isActive;

  ClassTemplate({
    required this.id,
    required this.name,
    required this.weekday,
    required this.startTime,
    required this.capacity,
    required this.isActive,
  });

  factory ClassTemplate.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};

    // LER APENAS 'weekday' (obrigatório e numérico)
    final wdRaw = data['weekday'];
    if (wdRaw is! int) {
      throw StateError(
        "classTemplates/${doc.id} sem 'weekday' (int)."
            " Define 1..7 (1=Seg .. 7=Dom).",
      );
    }
    final wd = wdRaw.clamp(1, 7);

    return ClassTemplate(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      weekday: wd,
      startTime: (data['startTime'] ?? '00:00') as String,
      capacity: (data['capacity'] is int) ? data['capacity'] as int : 10,
      // aceita 'isActive' ou (caso antigo) 'ative'
      isActive: (data['isActive'] is bool)
          ? data['isActive'] as bool
          : (data['ative'] is bool ? data['ative'] as bool : true),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'weekday': weekday,      // grava sempre 'weekday'
    'startTime': startTime,
    'capacity': capacity,
    'isActive': isActive,
  };
}
