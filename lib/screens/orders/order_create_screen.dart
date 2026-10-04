import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../di/service_locator.dart';
import '../../core/api_exception.dart';
import '../../models/address.dart';
import '../../models/city.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../models/person.dart';
import '../../models/phone.dart';
import '../../services/address_service.dart';
import '../../services/city_service.dart';
import '../../services/order_item_service.dart';
import '../../services/order_service.dart';
import '../../services/phone_service.dart';
import '../../widgets/pending_order_item_dialog.dart';
import '../persons/person_picker_screen.dart';

class OrderCreateScreen extends StatefulWidget {
  const OrderCreateScreen({super.key, this.fixedPersonId, this.fixedPersonName});
  final String? fixedPersonId;
  final String? fixedPersonName;

  @override
  State<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends State<OrderCreateScreen> {
  final _addressService = sl<AddressService>();
  final _phoneService = sl<PhoneService>();
  final _cityService = sl<CityService>();
  final _orderService = sl<OrderService>();
  final _orderItemService = sl<OrderItemService>();
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  int _step = 0;

  Person? _person;

  List<Address> _existingAddresses = [];
  List<Phone> _existingPhones = [];
  List<City> _cities = [];
  bool _loadingPersonData = false;
  String? _selectedAddressId;
  bool _showNewAddressFields = false;
  bool _showNewPhoneField = false;
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  String? _cityId;
  final _phoneController = TextEditingController();
  PhoneType _phoneType = PhoneType.mobile;

  DateTime? _orderDate;
  final _observationController = TextEditingController();

  final List<PendingOrderItem> _pendingItems = [];

  bool _saving = false;

  String? _createdAddressId;
  bool _phoneCreatedDuringSubmit = false;
  String? _createdOrderId;
  final Set<int> _syncedItemIndexes = {};

  bool get _hasClientStep => widget.fixedPersonId == null;

  @override
  void initState() {
    super.initState();
    if (widget.fixedPersonId != null) {
      _person = Person(id: widget.fixedPersonId, name: widget.fixedPersonName ?? '');
      _loadPersonData();
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _numberController.dispose();
    _neighborhoodController.dispose();
    _phoneController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonData() async {
    setState(() => _loadingPersonData = true);
    try {
      final results = await Future.wait([
        _addressService.listByPerson(_person!.id!),
        _phoneService.listByPerson(_person!.id!),
        _cityService.list(),
      ]);
      setState(() {
        _existingAddresses = results[0] as List<Address>;
        _existingPhones = results[1] as List<Phone>;
        _cities = results[2] as List<City>;
        _showNewAddressFields = _existingAddresses.isEmpty;
        _showNewPhoneField = _existingPhones.isEmpty;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPersonData = false);
    }
  }

  Future<void> _pickPerson() async {
    final selected = await Navigator.push<Person>(
      context,
      MaterialPageRoute(builder: (_) => const PersonPickerScreen()),
    );
    if (selected == null) return;
    setState(() {
      _person = selected;
      _existingAddresses = [];
      _existingPhones = [];
      _selectedAddressId = null;
      _showNewAddressFields = false;
      _showNewPhoneField = false;
    });
    await _loadPersonData();
    if (mounted) setState(() => _step = 1);
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

  Future<void> _addPendingItem() async {
    final result = await showPendingOrderItemDialog(context);
    if (result != null) setState(() => _pendingItems.add(result));
  }

  Future<void> _editPendingItem(int index) async {
    final result = await showPendingOrderItemDialog(context, initial: _pendingItems[index]);
    if (result != null) setState(() => _pendingItems[index] = result);
  }

  double get _itemsTotal => _pendingItems.fold(0, (sum, i) => sum + i.subtotal);

  bool _canContinue(int step) {
    if (_hasClientStep && step == 0) return _person != null;
    return true;
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      String? addressId = _selectedAddressId;
      if (_showNewAddressFields && _streetController.text.trim().isNotEmpty) {
        if (_createdAddressId == null) {
          final created = await _addressService.create(Address(
            personId: _person!.id!,
            street: _streetController.text.trim(),
            number: _numberController.text.trim(),
            neighborhood: _neighborhoodController.text.trim().isEmpty ? null : _neighborhoodController.text.trim(),
            cityId: _cityId,
          ));
          _createdAddressId = created.id;
        }
        addressId = _createdAddressId;
      }

      if (_showNewPhoneField && _phoneController.text.trim().isNotEmpty && !_phoneCreatedDuringSubmit) {
        await _phoneService.create(Phone(personId: _person!.id!, number: _phoneController.text.trim(), type: _phoneType));
        _phoneCreatedDuringSubmit = true;
      }

      if (_createdOrderId == null) {
        final order = await _orderService.create(Order(
          personId: _person!.id!,
          addressId: addressId,
          observation: _observationController.text.trim().isEmpty ? null : _observationController.text.trim(),
          orderDate: _orderDate,
        ));
        _createdOrderId = order.id;
      }
      final orderId = _createdOrderId!;

      for (var i = 0; i < _pendingItems.length; i++) {
        if (_syncedItemIndexes.contains(i)) continue;
        final pending = _pendingItems[i];
        await _orderItemService.create(OrderItem(
          orderId: orderId,
          itemId: pending.itemId,
          quantity: pending.quantity,
          unitPrice: pending.unitPrice,
          maintenanceIntervalMonths: pending.maintenanceIntervalMonths,
        ));
        _syncedItemIndexes.add(i);
      }

      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_createdOrderId != null
              ? '${e.message} O pedido já foi criado — tentar novamente só reenvia o que falhou.'
              : e.message),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = <Step>[
      if (_hasClientStep) _buildClientStep(),
      _buildAddressContactStep(),
      _buildDateStep(),
      _buildItemsStep(),
    ];
    final step = _step.clamp(0, steps.length - 1);

    return Scaffold(
      appBar: AppBar(title: const Text('Novo pedido')),
      body: Stepper(
        currentStep: step,
        onStepTapped: (i) => setState(() => _step = i),
        controlsBuilder: (context, details) {
          final isLast = step == steps.length - 1;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                FilledButton(
                  onPressed: _saving
                      ? null
                      : isLast
                          ? _submit
                          : (_canContinue(step) ? () => setState(() => _step = step + 1) : null),
                  child: _saving && isLast
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isLast ? 'Finalizar pedido' : 'Continuar'),
                ),
                const SizedBox(width: 8),
                if (step > 0) TextButton(onPressed: () => setState(() => _step = step - 1), child: const Text('Voltar')),
              ],
            ),
          );
        },
        steps: steps,
      ),
    );
  }

  Step _buildClientStep() {
    return Step(
      title: const Text('Cliente'),
      isActive: true,
      state: _person != null ? StepState.complete : StepState.indexed,
      content: Align(
        alignment: Alignment.centerLeft,
        child: _person == null
            ? OutlinedButton.icon(
                onPressed: _pickPerson,
                icon: const Icon(Icons.search),
                label: const Text('Buscar cliente'),
              )
            : ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(_person!.name),
                trailing: TextButton(onPressed: _pickPerson, child: const Text('Trocar')),
              ),
      ),
    );
  }

  Step _buildAddressContactStep() {
    return Step(
      title: const Text('Endereço e contato'),
      isActive: _person != null,
      content: _person == null
          ? const Text('Selecione um cliente primeiro.')
          : _loadingPersonData
              ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Endereço de entrega (opcional)', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    if (_existingAddresses.isNotEmpty && !_showNewAddressFields) ...[
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedAddressId,
                        decoration: const InputDecoration(labelText: 'Selecionar endereço'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('—')),
                          ..._existingAddresses.map((a) => DropdownMenuItem<String?>(
                                value: a.id,
                                child: Text('${a.street}, ${a.number}', overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (v) => setState(() => _selectedAddressId = v),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _showNewAddressFields = true),
                        icon: const Icon(Icons.add),
                        label: const Text('Novo endereço'),
                      ),
                    ] else ...[
                      if (_existingAddresses.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => setState(() => _showNewAddressFields = false),
                          icon: const Icon(Icons.list),
                          label: const Text('Selecionar endereço existente'),
                        ),
                      TextFormField(controller: _streetController, decoration: const InputDecoration(labelText: 'Rua')),
                      const SizedBox(height: 8),
                      TextFormField(controller: _numberController, decoration: const InputDecoration(labelText: 'Número')),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _neighborhoodController,
                        decoration: const InputDecoration(labelText: 'Bairro (opcional)'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        initialValue: _cityId,
                        decoration: const InputDecoration(labelText: 'Cidade (opcional)'),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('—')),
                          ..._cities.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (v) => setState(() => _cityId = v),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text('Contato', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    if (_existingPhones.isNotEmpty && !_showNewPhoneField) ...[
                      ..._existingPhones.map((p) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.phone_outlined),
                            title: Text(p.number),
                            subtitle: Text(p.type.label),
                          )),
                      TextButton.icon(
                        onPressed: () => setState(() => _showNewPhoneField = true),
                        icon: const Icon(Icons.add),
                        label: const Text('Novo telefone'),
                      ),
                    ] else ...[
                      if (_existingPhones.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => setState(() => _showNewPhoneField = false),
                          icon: const Icon(Icons.list),
                          label: const Text('Usar telefone existente'),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(labelText: 'Telefone (opcional)'),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<PhoneType>(
                            value: _phoneType,
                            items: PhoneType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                            onChanged: (v) => setState(() => _phoneType = v ?? PhoneType.mobile),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
    );
  }

  Step _buildDateStep() {
    return Step(
      title: const Text('Data e observação'),
      isActive: _person != null,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Data do pedido (opcional)', suffixIcon: Icon(Icons.calendar_today_outlined)),
              child: Text(_orderDate != null ? _dateFormat.format(_orderDate!) : '—'),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _observationController,
            decoration: const InputDecoration(labelText: 'Observação (opcional)'),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Step _buildItemsStep() {
    return Step(
      title: const Text('Itens'),
      isActive: _person != null,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_pendingItems.isEmpty) const Text('Nenhum item adicionado ainda (opcional).'),
          ..._pendingItems.asMap().entries.map((e) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(e.value.itemName),
                subtitle: Text('Qtd: ${e.value.quantity}'
                    '${e.value.unitPrice != null ? ' · ${_currency.format(e.value.unitPrice)} · Subtotal: ${_currency.format(e.value.subtotal)}' : ''}'
                    '${e.value.maintenanceIntervalMonths != null ? ' · Manutenção a cada ${e.value.maintenanceIntervalMonths}m' : ''}'),
                onTap: () => _editPendingItem(e.key),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _pendingItems.removeAt(e.key)),
                ),
              )),
          TextButton.icon(onPressed: _addPendingItem, icon: const Icon(Icons.add), label: const Text('Adicionar item')),
          if (_pendingItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Total: ${_currency.format(_itemsTotal)}', style: Theme.of(context).textTheme.titleMedium),
            ),
        ],
      ),
    );
  }
}
