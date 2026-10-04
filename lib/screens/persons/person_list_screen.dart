import 'dart:async';

import 'package:flutter/material.dart';

import '../../di/service_locator.dart';
import '../../core/api_exception.dart';
import '../../models/person.dart';
import '../../services/person_service.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'person_detail_screen.dart';
import 'person_form_screen.dart';

class PersonListScreen extends StatefulWidget {
  const PersonListScreen({super.key, this.actions});

  final List<Widget>? actions;

  @override
  State<PersonListScreen> createState() => _PersonListScreenState();
}

class _PersonListScreenState extends State<PersonListScreen> {
  final _personService = sl<PersonService>();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  final List<Person> _persons = [];
  int _page = 0;
  bool _isLastPage = false;
  String _nameFilter = '';
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {}); // refresh the clear button visibility immediately
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _nameFilter = value;
      _load();
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    _nameFilter = '';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _isLastPage = false;
      _persons.clear();
    });
    try {
      final result = await _personService.page(page: 0, name: _nameFilter);
      setState(() {
        _persons.addAll(result.content);
        _isLastPage = result.last;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _isLastPage || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final result = await _personService.page(page: nextPage, name: _nameFilter);
      setState(() {
        _page = nextPage;
        _persons.addAll(result.content);
        _isLastPage = result.last;
      });
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _delete(Person person) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Excluir cliente',
      message: 'Deseja excluir "${person.name}"? Endereços e telefones vinculados também serão afetados.',
    );
    if (!confirmed) return;
    try {
      await _personService.delete(person.id!);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openForm({Person? person}) async {
    final saved = await Navigator.push<Person>(
      context,
      MaterialPageRoute(builder: (_) => PersonFormScreen(person: person)),
    );
    if (saved != null) _load();
  }

  Future<void> _openDetail(Person person) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: person.id!)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes'), actions: widget.actions),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_persons',
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Tentar novamente')),
              ],
            ),
          ),
        ],
      );
    }
    if (_persons.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(_nameFilter.isEmpty
                  ? 'Nenhum cliente cadastrado ainda.'
                  : 'Nenhum cliente encontrado para "$_nameFilter".'),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      controller: _scrollController,
      itemCount: _persons.length + 1,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == _persons.length) {
          if (_isLastPage) return const SizedBox.shrink();
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final person = _persons[index];
        return ListTile(
          leading: CircleAvatar(child: Text(person.name.isNotEmpty ? person.name[0].toUpperCase() : '?')),
          title: Text(person.name),
          onTap: () => _openDetail(person),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _openForm(person: person);
              if (value == 'delete') _delete(person);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        );
      },
    );
  }
}
