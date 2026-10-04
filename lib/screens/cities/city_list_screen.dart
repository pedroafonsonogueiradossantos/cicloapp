import 'package:flutter/material.dart';

import '../../di/service_locator.dart';
import '../../core/api_exception.dart';
import '../../models/city.dart';
import '../../services/city_service.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'city_form_screen.dart';

class CityListScreen extends StatefulWidget {
  const CityListScreen({super.key, this.actions});

  final List<Widget>? actions;

  @override
  State<CityListScreen> createState() => _CityListScreenState();
}

class _CityListScreenState extends State<CityListScreen> {
  final _cityService = sl<CityService>();
  List<City> _cities = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cities = await _cityService.list();
      setState(() => _cities = cities);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openForm({City? city}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CityFormScreen(city: city)),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(City city) async {
    final confirmed = await confirmDelete(context, title: 'Excluir cidade', message: 'Deseja excluir "${city.name}"?');
    if (!confirmed) return;
    try {
      await _cityService.delete(city.id!);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cidades'), actions: widget.actions),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Tentar novamente')),
                      ]),
                    ),
                  ])
                : _cities.isEmpty
                    ? ListView(children: const [
                        Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('Nenhuma cidade cadastrada ainda.')),
                        ),
                      ])
                    : ListView.separated(
                        itemCount: _cities.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final city = _cities[index];
                          return ListTile(
                            leading: const Icon(Icons.location_city_outlined),
                            title: Text(city.name),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') _openForm(city: city);
                                if (v == 'delete') _delete(city);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('Editar')),
                                PopupMenuItem(value: 'delete', child: Text('Excluir')),
                              ],
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_cities',
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
