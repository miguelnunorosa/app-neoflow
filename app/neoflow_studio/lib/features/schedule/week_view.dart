import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'schedule_repo.dart';
import 'models.dart';
import 'date_utils.dart';
import 'class_booking_service.dart';

class WeekScheduleView extends StatefulWidget {
  const WeekScheduleView({super.key});

  @override
  State<WeekScheduleView> createState() => _WeekScheduleViewState();
}

class _WeekScheduleViewState extends State<WeekScheduleView>
    with SingleTickerProviderStateMixin {
  late DateTime _monday;
  late TabController _tab;
  final ScheduleRepo _repo = ScheduleRepo();

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
    setState(() => _future = fut);
  }

  void _prevWeek() {
    setState(() => _monday = _monday.subtract(const Duration(days: 7)));
  }

  void _nextWeek() {
    setState(() => _monday = _monday.add(const Duration(days: 7)));
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

          // agrupa por weekday (1..7)
          final byDay = List.generate(7, (_) => <ClassTemplate>[]);
          for (final t in templates) {
            final idx = (t.weekday.clamp(1, 7)) - 1;
            byDay[idx].add(t);
          }
          // ordena por hora dentro do dia
          for (final list in byDay) {
            list.sort((a, b) => a.startTime.compareTo(b.startTime));
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
                  return TemplateCard(
                    template: t,
                    dateOfThisWeekDay: d,
                  );
                },
              );
            }),
          );
        },
      ),
    );
  }
}

/// Versão stateful com estado local para feedback instantâneo.
class TemplateCard extends StatefulWidget {
  const TemplateCard({
    super.key,
    required this.template,
    required this.dateOfThisWeekDay,
  });

  final ClassTemplate template;
  final DateTime dateOfThisWeekDay;

  @override
  State<TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<TemplateCard> {
  final _svc = ClassBookingService();
  String? _localStatus; // null | 'confirmed'

  @override
  Widget build(BuildContext context) {
    final subtitle = _formatCardDate(widget.dateOfThisWeekDay, widget.template.startTime);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // stream do estado remoto
    final status$ = (uid == null)
        ? const Stream<String?>.empty()
        : _svc.myStatusStream(
      template: widget.template,
      date: widget.dateOfThisWeekDay,
      userId: uid,
    );

    final isPastSession =
    _isSessionInThePast(widget.dateOfThisWeekDay, widget.template.startTime);

    return StreamBuilder<String?>(
      stream: status$,
      builder: (context, s) {
        final remoteStatus = s.data; // null | 'confirmed'
        // se tivermos estado local, dá prioridade (feedback imediato)
        final effectiveStatus = _localStatus ?? remoteStatus;

        // Se o stream trouxe um valor diferente e não temos override local,
        // ainda assim refaz o UI (normalmente o StreamBuilder já o faz).
        // Opcional: se quiseres "limpar" o override quando o remoto chegar:
        if (_localStatus != null && remoteStatus == _localStatus) {
          // limpa o override após confirmação do backend
          _localStatus = null;
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Text(widget.template.startTime, style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 12),

                // Infos à esquerda
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.template.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 6),

                      if (isPastSession)
                        const Text(
                          'Realizada',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                        )
                      else if (effectiveStatus == 'confirmed')
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_box, size: 18, color: Colors.green),
                            SizedBox(width: 6),
                            Text(
                              'Inscrito',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Ações à direita
                if (isPastSession)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: ElevatedButton(
                      onPressed: null,
                      child: Text('Encerrada'),
                    ),
                  )
                else if (uid != null && effectiveStatus == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await _svc.createOrConfirmBooking(
                            template: widget.template,
                            date: widget.dateOfThisWeekDay,
                            userId: uid,
                          );
                          // feedback imediato
                          setState(() {
                            _localStatus = 'confirmed';
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Inscrição criada.')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('$e')));
                          }
                        }
                      },
                      child: const Text('Inscrever'),
                    ),
                  )
                else if (uid != null && effectiveStatus == 'confirmed')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton(
                        onPressed: () async {
                          try {
                            await _svc.cancelBooking(
                              template: widget.template,
                              date: widget.dateOfThisWeekDay,
                              userId: uid,
                            );
                            // feedback imediato
                            setState(() {
                              _localStatus = null;
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Inscrição cancelada.')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text('$e')));
                            }
                          }
                        },
                        child: const Text('Cancelar'),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  // "Seg, 16/09/2025 | 18:30"
  String _formatCardDate(DateTime d, String time) {
    final weekdayShort = DateFormat.E('pt_PT').format(d);
    final dayMonth = DateFormat('dd/MM/yyyy').format(d);
    return '$weekdayShort \n$dayMonth \n$time';
  }

  bool _isSessionInThePast(DateTime day, String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.elementAt(0)) ?? 0;
    final m = int.tryParse(parts.elementAt(1)) ?? 0;
    final sessionDateTime = DateTime(day.year, day.month, day.day, h, m);
    return sessionDateTime.isBefore(DateTime.now());
  }
}
