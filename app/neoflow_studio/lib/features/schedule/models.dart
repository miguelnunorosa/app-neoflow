
class ClassTemplate {
  final String id;
  final String name;
  final int weekday;       // 1=Seg ... 7=Dom
  final String startTime;  // "HH:mm"
  final int durationMin;
  final int capacity;

  ClassTemplate({
    required this.id,
    required this.name,
    required this.weekday,
    required this.startTime,
    required this.durationMin,
    required this.capacity,
  });

  factory ClassTemplate.fromMap(String id, Map<String, dynamic> m) {
    return ClassTemplate(
      id: id,
      name: (m['name'] ?? '') as String,
      weekday: (m['weekday'] ?? 1) as int,
      startTime: (m['startTime'] ?? '18:30') as String,
      durationMin: (m['durationMin'] ?? 45) as int,
      capacity: (m['capacity'] ?? 10) as int,
    );
  }
}

class SessionVM {
  final String sessionId;
  final String name;
  final DateTime date;         // dia desta sessão (data concreta)
  final String startTime;      // "HH:mm"
  final int capacity;
  final int confirmedCount;
  final int waitlistCount;

  int get remaining => (capacity - confirmedCount).clamp(0, capacity);

  SessionVM({
    required this.sessionId,
    required this.name,
    required this.date,
    required this.startTime,
    required this.capacity,
    required this.confirmedCount,
    required this.waitlistCount,
  });
}
