import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../di/service_locator.dart';
import '../../core/api_exception.dart';
import '../../models/address.dart';
import '../../models/order.dart';
import '../../models/person.dart';
import '../../services/address_service.dart';
import '../../services/order_service.dart';
import '../persons/person_picker_screen.dart';

class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key, this.order, this.fixedPersonId, this.fixedPersonName});

  final Order? order;

  final String? fixedPersonId;
  final String? fixedPersonName;

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = sl<OrderService>();
  final _addressService = sl<AddressService>();
  late final TextEditingController _observation;

  String? _personId;
  String? _personName;
  DateTime? _orderDate;
  bool _saving = false;

  List<Address> _addresses = [];
  String? _addressId;
  bool _loadingAddresses = false;

  String? _orphanedAddressLabel;

  bool get _isEditing => widget.order != null;
  bool get _personFixed => widget.fixedPersonId != null;

  @override
  void initState() {
    super.initState();
    _observation = TextEditingController(text: widget.order?.observation ?? '');
    _orderDate = widget.order?.orderDate;
    _personId = widget.order?.personId ?? widget.fixedPersonId;
    _personName = widget.order?.personName ?? widget.fixedPersonName;
    _addressId = widget.order?.originAddressId;
    if (widget.order != null && widget.order!.originAddressId == null && widget.order!.hasAddressSnapshot) {
      _orphanedAddressLabel = [
        widget.order!.addressStreet,
        widget.order!.addressNumber,
      ].where((s) => s != null && s.isNotEmpty).join(', ');
    }
    if (_personId != null) _loadAddresses(_personId!);
  }

  @override
  void dispose() {
    _observation.dispose();
    super.dispose();
  }

  Future<void> _pickPerson(FormFieldState<String> field) async {
    final selected = await Navigator.push<Person>(
      context,
      MaterialPageRoute(builder: (_) => const PersonPickerScreen()),
    );
    if (selected == null) return;
    setState(() {
      _personId = selected.id;
      _personName = selected.name;
      _addressId = null;
      _orphanedAddressLabel = null;
      _addresses = [];
    });
    field.didChange(selected.id);
    _loadAddresses(selected.id!);
  }

  Future<void> _loadAddresses(String personId) async {
    setState(() => _loadingAddresses = true);
    try {
      final addresses = await _addressService.listByPerson(personId);
      setState(() => _addresses = addresses);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingAddresses = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _orderDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _orderDate = DateTime.utc(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final order = Order(
        personId: _personId!,
        addressId: _addressId,
        observation: _observation.text.trim().isEmpty ? null : _observation.text.trim(),
        orderDate: _orderDate,
      );
      if (_isEditing) {
        await _orderService.update(widget.order!.id!, order);
      } else {
        await _orderService.create(order);
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
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar pedido' : 'Novo pedido')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_personFixed)
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  child: Text(_personName ?? 'Cliente #${widget.fixedPersonId}'),
                )
              else
                FormField<String>(
                  initialValue: _personId,
                  validator: (v) => v == null ? 'Selecione um cliente' : null,
                  builder: (field) {
                    return InkWell(
                      onTap: () => _pickPerson(field),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Cliente',
                          errorText: field.errorText,
                          suffixIcon: const Icon(Icons.search),
                        ),
                        child: Text(_personName ?? 'Toque para buscar um cliente'),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
              if (_personId != null) ...[
                if (_orphanedAddressLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Endereço original ("$_orphanedAddressLabel") foi excluído. '
                      'Selecione outro ou o histórico será removido ao salvar.',
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    ),
                  ),
                _loadingAddresses
                    ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator())
                    : DropdownButtonFormField<String?>(
                        initialValue: _addressId,
                        decoration: const InputDecoration(labelText: 'Endereço de entrega (opcional)'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('—')),
                          ..._addresses.map((a) => DropdownMenuItem<String?>(
                                value: a.id,
                                child: Text('${a.street}, ${a.number}', overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (v) => setState(() {
                          _addressId = v;
                          if (v != null) _orphanedAddressLabel = null;
                        }),
                      ),
                if (!_loadingAddresses && _addresses.isEmpty && _orphanedAddressLabel == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Este cliente não tem endereço cadastrado.', style: TextStyle(fontSize: 12)),
                  ),
                const SizedBox(height: 16),
              ],
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Data do pedido (opcional)', suffixIcon: Icon(Icons.calendar_today_outlined)),
                  child: Text(_orderDate != null ? DateFormat('dd/MM/yyyy').format(_orderDate!) : '—'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observation,
                decoration: const InputDecoration(labelText: 'Observação (opcional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
