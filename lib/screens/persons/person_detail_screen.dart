import 'package:flutter/material.dart';

import '../../di/service_locator.dart';
import '../../core/api_exception.dart';
import '../../core/dialer.dart';
import '../../models/address.dart';
import '../../models/person.dart';
import '../../models/phone.dart';
import '../../services/address_service.dart';
import '../../services/person_service.dart';
import '../../services/phone_service.dart';
import '../../widgets/address_form_dialog.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/phone_form_dialog.dart';
import '../orders/order_list_screen.dart';

class PersonDetailScreen extends StatefulWidget {
  const PersonDetailScreen({super.key, required this.personId});

  final String personId;

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  final _personService = sl<PersonService>();
  final _addressService = sl<AddressService>();
  final _phoneService = sl<PhoneService>();

  Person? _person;
  List<Address> _addresses = [];
  List<Phone> _phones = [];
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
      final results = await Future.wait([
        _personService.getById(widget.personId),
        _addressService.listByPerson(widget.personId),
        _phoneService.listByPerson(widget.personId),
      ]);
      setState(() {
        _person = results[0] as Person;
        _addresses = results[1] as List<Address>;
        _phones = results[2] as List<Phone>;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addOrEditAddress({Address? address}) async {
    final changed = await showAddressFormDialog(context, personId: widget.personId, address: address);
    if (changed) _load();
  }

  Future<void> _deleteAddress(Address address) async {
    final confirmed = await confirmDelete(context, title: 'Excluir endereço', message: 'Deseja excluir este endereço?');
    if (!confirmed) return;
    try {
      await _addressService.delete(address.id!);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _addOrEditPhone({Phone? phone}) async {
    final changed = await showPhoneFormDialog(context, personId: widget.personId, phone: phone);
    if (changed) _load();
  }

  Future<void> _deletePhone(Phone phone) async {
    final confirmed = await confirmDelete(context, title: 'Excluir telefone', message: 'Deseja excluir este telefone?');
    if (!confirmed) return;
    try {
      await _phoneService.delete(phone.id!);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_person?.name ?? 'Cliente')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long_outlined),
                          title: const Text('Pedidos'),
                          subtitle: const Text('Ver pedidos deste cliente'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderListScreen(personId: widget.personId, personName: _person?.name),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionHeader(title: 'Endereços', onAdd: () => _addOrEditAddress()),
                      if (_addresses.isEmpty) const _EmptyHint(text: 'Nenhum endereço cadastrado.'),
                      ..._addresses.map((a) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.location_on_outlined),
                              title: Text('${a.street}, ${a.number}'),
                              subtitle: Text([
                                if (a.neighborhood != null && a.neighborhood!.isNotEmpty) a.neighborhood!,
                                if (a.cityName != null) a.cityName!,
                              ].join(' - ')),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _addOrEditAddress(address: a);
                                  if (v == 'delete') _deleteAddress(a);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                                ],
                              ),
                            ),
                          )),
                      const SizedBox(height: 16),
                      _SectionHeader(title: 'Telefones', onAdd: () => _addOrEditPhone()),
                      if (_phones.isEmpty) const _EmptyHint(text: 'Nenhum telefone cadastrado.'),
                      ..._phones.map((p) => Card(
                            child: ListTile(
                              leading: IconButton(
                                icon: const Icon(Icons.call, color: Colors.green),
                                tooltip: 'Ligar',
                                onPressed: () => callNumber(context, p.number),
                              ),
                              title: Text(p.number),
                              subtitle: Text(p.type.label),
                              onTap: () => callNumber(context, p.number),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _addOrEditPhone(phone: p);
                                  if (v == 'delete') _deletePhone(p);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onAdd});

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        IconButton(onPressed: onAdd, icon: const Icon(Icons.add_circle_outline)),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
