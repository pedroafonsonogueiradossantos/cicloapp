import 'package:flutter/material.dart';

import '../../di/service_locator.dart';
import '../../core/api_exception.dart';
import '../../models/item.dart';
import '../../services/item_service.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'item_form_screen.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key, this.actions});

  final List<Widget>? actions;

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final _itemService = sl<ItemService>();
  List<Item> _items = [];
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
      final items = await _itemService.list();
      setState(() => _items = items);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openForm({Item? item}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(Item item) async {
    final confirmed = await confirmDelete(context, title: 'Excluir item', message: 'Deseja excluir "${item.name}"?');
    if (!confirmed) return;
    try {
      await _itemService.delete(item.id!);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Itens'), actions: widget.actions),
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
                : _items.isEmpty
                    ? ListView(children: const [
                        Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('Nenhum item cadastrado ainda.')),
                        ),
                      ])
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return ListTile(
                            leading: const Icon(Icons.inventory_2_outlined),
                            title: Text(item.name),
                            subtitle: item.description != null ? Text(item.description!) : null,
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') _openForm(item: item);
                                if (v == 'delete') _delete(item);
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
        heroTag: 'fab_items',
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
