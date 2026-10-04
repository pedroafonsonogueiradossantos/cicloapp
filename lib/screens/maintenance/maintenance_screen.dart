import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../di/service_locator.dart';
import '../../core/api_exception.dart';
import '../../core/dialer.dart';
import '../../models/maintenance_due.dart';
import '../../services/maintenance_service.dart';
import '../persons/person_detail_screen.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key, this.actions});

  final List<Widget>? actions;

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final _maintenanceService = sl<MaintenanceService>();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  late DateTime _from;
  late DateTime _to;
  List<MaintenanceDue> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _from = DateTime.utc(today.year, today.month, today.day);
    _to = _from.add(const Duration(days: 30));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _maintenanceService.due(from: _from, to: _to);
      setState(() => _items = items);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _from = DateTime.utc(picked.year, picked.month, picked.day));
    _load();
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _to = DateTime.utc(picked.year, picked.month, picked.day, 23, 59, 59));
    _load();
  }

  Color? _dueColor(DateTime dueDate) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    if (dueDate.isBefore(startOfToday)) return Colors.red;
    if (dueDate.isBefore(startOfToday.add(const Duration(days: 7)))) return Colors.orange;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manutenção'), actions: widget.actions),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFrom,
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text('De: ${_dateFormat.format(_from)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTo,
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text('Até: ${_dateFormat.format(_to)}'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: RefreshIndicator(onRefresh: _load, child: _buildBody())),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Tentar novamente')),
          ]),
        ),
      ]);
    }
    if (_items.isEmpty) {
      return ListView(children: const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Nenhuma manutenção prevista para o período selecionado.')),
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final due = _items[index];
        final color = _dueColor(due.dueDate);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color?.withValues(alpha: 0.15),
            child: Icon(Icons.build_outlined, color: color),
          ),
          title: Text(due.personName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${due.itemName} · vence em ${_dateFormat.format(due.dueDate)}',
                  style: TextStyle(color: color, fontWeight: color != null ? FontWeight.bold : null)),
              if (due.phoneNumbers.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: due.phoneNumbers
                      .map((number) => ActionChip(
                            avatar: const Icon(Icons.call, size: 16, color: Colors.green),
                            label: Text(number),
                            onPressed: () => callNumber(context, number),
                          ))
                      .toList(),
                ),
            ],
          ),
          isThreeLine: due.phoneNumbers.isNotEmpty,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: due.personId)),
          ),
        );
      },
    );
  }
}
