import 'dart:async';

import 'package:flutter/material.dart';

import '../../di/service_locator.dart';
import '../../core/api_exception.dart';
import '../../models/person.dart';
import '../../services/person_service.dart';
import 'person_form_screen.dart';

class PersonPickerScreen extends StatefulWidget {
  const PersonPickerScreen({super.key});

  @override
  State<PersonPickerScreen> createState() => _PersonPickerScreenState();
}

class _PersonPickerScreenState extends State<PersonPickerScreen> {
  final _personService = sl<PersonService>();
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Person> _persons = [];
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _personService.page(size: 20, name: _query);
      setState(() => _persons = page.content);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {}); // refresh the clear button visibility immediately
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _query = value.trim();
      _search();
    });
  }

  Future<void> _createPerson() async {
    final created = await Navigator.push<Person>(
      context,
      MaterialPageRoute(builder: (_) => PersonFormScreen(initialName: _query)),
    );
    if (created != null && mounted) Navigator.pop(context, created);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar cliente'),
        actions: [
          IconButton(
            tooltip: 'Novo cliente',
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: _createPerson,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar cliente por nome',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _search, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }
    if (_persons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _query.isEmpty
                    ? 'Nenhum cliente cadastrado ainda.'
                    : 'Nenhum cliente encontrado para "$_query".',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _createPerson,
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(_query.isEmpty ? 'Criar cliente' : 'Criar cliente "$_query"'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _persons.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final person = _persons[index];
        return ListTile(
          leading: CircleAvatar(child: Text(person.name.isNotEmpty ? person.name[0].toUpperCase() : '?')),
          title: Text(person.name),
          onTap: () => Navigator.pop(context, person),
        );
      },
    );
  }
}
