import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'schedule_repo.dart';
import 'models.dart';
import 'date_utils.dart';

class WeekScheduleView extends StatefulWidget {
  const WeekScheduleView({super.key});

  @override
  State<WeekScheduleView> createState() => _WeekScheduleViewState();
}

class _WeekScheduleViewState extends State<WeekScheduleView>
    with SingleTickerProviderStateMixin {
  late DateTime _monday;
  late TabController _tab;
  final _repo = ScheduleRepo();

  Future<List<ClassTemplate>>? _future;

  @override
  void initState() {
    super.initState();
    _monday = startOfWeek(DateTime.now());
    _tab = TabController(
      length: 7,
      vsync: this,
      initialIndex: DateTime.now().weekday - 1,
    );
    _load();
  }

  void _load() {
    final fut = _repo.fetchActiveTemplates();
    if (!mounted) return;
    setState(() {
      _future = fut;
    });
  }

  void _prevWeek() {
    _monday = _monday.subtract(const Duration(days: 7));
    setState(() {}); // só para refazer as datas mostradas
  }

  void _nextWeek() {
    _monday = _monday.add(const Duration(days: 7));
    setState(() {});
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => _monday.add(Duration(days: i)));
    final fmt = DateFormat('dd/MM');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda semanal'),
        actions: [
          IconButton(onPressed: _prevWeek, icon: const Icon(Icons.chevron_left)),
          IconButton(onPressed: _nextWeek, icon: const Icon(Icons.chevron_right)),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: List.generate(7, (i) {
            final d = days[i];
            final w = DateFormat.E('pt_PT').format(d); // Seg, Ter, ...
            return Tab(text: '$w\n${fmt.format(d)}');
          }),
        ),
      ),
      body: FutureBuilder<List<ClassTemplate>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }
          final templates = snap.data ?? [];

          // separa por weekday (1..7)
          final byDay = List.generate(7, (i) => <ClassTemplate>[]);
          for (final t in templates) {
            final idx = (t.weekday.clamp(1, 7)) - 1;
            byDay[idx].add(t);
          }

          return TabBarView(
            controller: _tab,
            children: List.generate(7, (i) {
              final d = days[i];
              final list = byDay[i];
              if (list.isEmpty) {
                return const Center(child: Text('Sem aulas neste dia'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final t = list[idx];
                  return _TemplateCard(template: t, dateOfThisWeekDay: d);
                },
              );
            }),
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.dateOfThisWeekDay,
  });

  final ClassTemplate template;
  final DateTime dateOfThisWeekDay;

  @override
  Widget build(BuildContext context) {
    final subtitle = _formatCardDate(dateOfThisWeekDay, template.startTime);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              child: Text(template.startTime, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  // podes mostrar capacidade se tiveres no template:
                  if (template.capacity case final cap?)
                    Text('Capacidade: $cap'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // por agora só mostramos; quando ligares reservas, mete os botões aqui
            Icon(Icons.event_available, color: Colors.green[700]),
          ],
        ),
      ),
    );
  }

  String _formatCardDate(DateTime d, String time) {
    final weekdayShort = DateFormat.E('pt_PT').format(d); // Seg, Ter, ...
    final dayMonth = DateFormat('dd/MM/yyyy').format(d);
    return '$weekdayShort, $dayMonth | $time';
    // se preferires sem data (só hora fixa), troca por: 'Todas as $time'
  }
}
