import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../models/address.dart';
import '../models/city.dart';
import '../services/address_service.dart';
import '../services/city_service.dart';

Future<bool> showAddressFormDialog(BuildContext context, {required String personId, Address? address}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _AddressFormDialog(personId: personId, address: address),
  ).then((v) => v ?? false);
}

class _AddressFormDialog extends StatefulWidget {
  const _AddressFormDialog({required this.personId, this.address});

  final String personId;
  final Address? address;

  @override
  State<_AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<_AddressFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _street;
  late final TextEditingController _number;
  late final TextEditingController _neighborhood;
  final _addressService = AddressService();
  final _cityService = CityService();
  List<City> _cities = [];
  String? _cityId;
  bool _saving = false;
  bool _loadingCities = true;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    _street = TextEditingController(text: widget.address?.street ?? '');
    _number = TextEditingController(text: widget.address?.number ?? '');
    _neighborhood = TextEditingController(text: widget.address?.neighborhood ?? '');
    _cityId = widget.address?.cityId;
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await _cityService.list();
      setState(() {
        _cities = cities;
        _loadingCities = false;
      });
    } catch (_) {
      setState(() => _loadingCities = false);
    }
  }

  @override
  void dispose() {
    _street.dispose();
    _number.dispose();
    _neighborhood.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final address = Address(
        personId: widget.personId,
        street: _street.text.trim(),
        number: _number.text.trim(),
        neighborhood: _neighborhood.text.trim().isEmpty ? null : _neighborhood.text.trim(),
        cityId: _cityId,
      );
      if (_isEditing) {
        await _addressService.update(widget.address!.id!, address);
      } else {
        await _addressService.create(address);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar endereço' : 'Novo endereço'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _street,
                decoration: const InputDecoration(labelText: 'Rua'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a rua' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _number,
                decoration: const InputDecoration(labelText: 'Número'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o número' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _neighborhood,
                decoration: const InputDecoration(labelText: 'Bairro (opcional)'),
              ),
              const SizedBox(height: 12),
              _loadingCities
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    )
                  : DropdownButtonFormField<String?>(
                      initialValue: _cityId,
                      decoration: const InputDecoration(labelText: 'Cidade (opcional)'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('—')),
                        ..._cities.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (v) => setState(() => _cityId = v),
                    ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
