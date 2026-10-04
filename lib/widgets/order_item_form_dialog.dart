import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../models/item.dart';
import '../models/order_item.dart';
import '../services/item_service.dart';
import '../services/order_item_service.dart';

Future<bool> showOrderItemFormDialog(BuildContext context, {required String orderId, OrderItem? orderItem}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _OrderItemFormDialog(orderId: orderId, orderItem: orderItem),
  ).then((v) => v ?? false);
}

class _OrderItemFormDialog extends StatefulWidget {
  const _OrderItemFormDialog({required this.orderId, this.orderItem});

  final String orderId;
  final OrderItem? orderItem;

  @override
  State<_OrderItemFormDialog> createState() => _OrderItemFormDialogState();
}

class _OrderItemFormDialogState extends State<_OrderItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _itemService = ItemService();
  final _orderItemService = OrderItemService();

  List<Item> _items = [];
  String? _itemId;
  late final TextEditingController _quantity;
  late final TextEditingController _unitPrice;
  late final TextEditingController _maintenanceMonths;
  bool _loadingItems = true;
  bool _saving = false;

  bool get _isEditing => widget.orderItem != null;

  @override
  void initState() {
    super.initState();
    _itemId = widget.orderItem?.itemId;
    _quantity = TextEditingController(text: widget.orderItem?.quantity.toString() ?? '1');
    _unitPrice = TextEditingController(text: widget.orderItem?.unitPrice?.toString() ?? '');
    _maintenanceMonths = TextEditingController(
      text: widget.orderItem?.maintenanceIntervalMonths?.toString() ?? (_isEditing ? '' : '12'),
    );
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _itemService.list();
      setState(() {
        _items = items;
        _loadingItems = false;
      });
    } catch (_) {
      setState(() => _loadingItems = false);
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    _unitPrice.dispose();
    _maintenanceMonths.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final orderItem = OrderItem(
        orderId: widget.orderId,
        itemId: _itemId!,
        quantity: int.parse(_quantity.text.trim()),
        unitPrice: _unitPrice.text.trim().isEmpty ? null : double.parse(_unitPrice.text.trim().replaceAll(',', '.')),
        maintenanceIntervalMonths: _maintenanceMonths.text.trim().isEmpty ? null : int.parse(_maintenanceMonths.text.trim()),
      );
      if (_isEditing) {
        await _orderItemService.update(widget.orderItem!.id!, orderItem);
      } else {
        await _orderItemService.create(orderItem);
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
      title: Text(_isEditing ? 'Editar item do pedido' : 'Adicionar item ao pedido'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _loadingItems
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    )
                  : DropdownButtonFormField<String>(
                      initialValue: _itemId,
                      decoration: const InputDecoration(labelText: 'Item'),
                      items: _items.map((i) => DropdownMenuItem(value: i.id, child: Text(i.name))).toList(),
                      onChanged: (v) => setState(() => _itemId = v),
                      validator: (v) => v == null ? 'Selecione um item' : null,
                    ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantity,
                decoration: const InputDecoration(labelText: 'Quantidade'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n <= 0) return 'Informe uma quantidade válida';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitPrice,
                decoration: const InputDecoration(labelText: 'Preço unitário (opcional)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v.trim().replaceAll(',', '.'));
                  if (n == null || n < 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maintenanceMonths,
                decoration: const InputDecoration(
                  labelText: 'Manutenção a cada quantos meses (opcional)',
                  helperText: 'Deixe em branco se este item não precisa de acompanhamento',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Valor inválido';
                  return null;
                },
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
