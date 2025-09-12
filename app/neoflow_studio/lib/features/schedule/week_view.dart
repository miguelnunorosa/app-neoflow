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

class _WeekScheduleViewState extends State<WeekScheduleView> with SingleTickerProviderStateMixin {
  late DateTime _monday;
  late TabController _tab;
  final _repo = ScheduleRepo();
  Future<List<SessionVM>>? _future;

  @override
  void initState() {
    super.initState();
    _monday = startOfWeek(DateTime.now());
    _tab = TabController(length: 7, vsync: this, initialIndex: DateTime.now().weekday - 1);
    _load();
  }

  void _load() {
    setState(() => _future = _repo.getWeekSessions(_monday));
  }

  void _prevWeek() {
    setState(() {
      _monday = _monday.subtract(const Duration(days: 7));
      _load();
    });
  }

  void _nextWeek() {
    setState(() {
      _monday = _monday.add(const Duration(days: 7));
      _load();
    });
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
      body: FutureBuilder<List<SessionVM>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }
          final all = snap.data ?? [];

          // separa por dia
          final perDay = List.generate(7, (i) => <SessionVM>[]);
          for (final s in all) {
            final idx = s.date.weekday - 1; // 0..6
            perDay[idx].add(s);
          }

          return TabBarView(
            controller: _tab,
            children: List.generate(7, (i) {
              final list = perDay[i];
              if (list.isEmpty) {
                return const Center(child: Text('Sem aulas neste dia'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final s = list[idx];
                  return _SessionCard(
                    session: s,
                    onBook: () => _onBook(s),
                    onCancel: () => _onCancel(s),
                  );
                },
              );
            }),
          );
        },
      ),
    );
  }

  Future<void> _onBook(SessionVM s) async {
    // TODO: chamar a tua função bookSession(sessionId, uid)
    // await bookSession(s.sessionId, FirebaseAuth.instance.currentUser!.uid);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reserva enviada para ${s.name} ${formatCardDate(s.date, s.startTime)}')),
    );
    _load(); // refresh
  }

  Future<void> _onCancel(SessionVM s) async {
    // TODO: chamar a tua função cancelBooking(sessionId, uid)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cancelamento enviado para ${s.name}')),
    );
    _load();
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.onBook,
    required this.onCancel,
  });

  final SessionVM session;
  final VoidCallback onBook;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final subtitle = formatCardDate(session.date, session.startTime);
    final remaining = session.remaining; // vagas restantes
    final wait = session.waitlistCount;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // “avatar” do horário
            CircleAvatar(
              radius: 24,
              child: Text(session.startTime, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 12),
            // texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  Text(
                    '$remaining vagas restantes (${wait} em espera)',
                    style: TextStyle(
                      color: remaining > 0 ? Colors.green[700] : Colors.orange[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ações (exemplo simples)
            Column(
              children: [
                ElevatedButton(
                  onPressed: remaining > 0 ? onBook : onBook, // mesma ação (entra em espera se cheio)
                  child: Text(remaining > 0 ? 'Reservar' : 'Esperar'),
                ),
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
