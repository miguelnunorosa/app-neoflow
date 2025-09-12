import 'package:intl/intl.dart';

DateTime startOfWeek(DateTime now) {
  final local = DateTime(now.year, now.month, now.day);
  final diff = local.weekday - DateTime.monday; // 0..6
  return local.subtract(Duration(days: diff));
}

String yyyymmdd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

String formatCardDate(DateTime d, String time) {
  // Ex.: "Seg, 16/09/2025 | 18:30"
  final weekdayShort = DateFormat.E('pt_PT').format(d); // Seg, Ter, ...
  final dayMonth = DateFormat('dd/MM/yyyy').format(d);
  return '$weekdayShort, $dayMonth | $time';
}
