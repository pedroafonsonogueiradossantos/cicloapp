import 'package:flutter/material.dart';

import '../models/item.dart';
import '../services/item_service.dart';

class PendingOrderItem {
  PendingOrderItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    this.unitPrice,
    this.maintenanceIntervalMonths,
  });

  final String itemId;
  final String itemName;
  final int quantity;
  final double? unitPrice;
  final int? maintenanceIntervalMonths;

  double get subtotal => (unitPrice ?? 0) * quantity;
}

Future<PendingOrderItem?> showPendingOrderItemDialog(BuildContext context, {PendingOrderItem? initial}) {
  return showDialog<PendingOrderItem>(
    context: context,
    builder: (_) => _PendingOrderItemDialog(initial: initial),
  );
}

class _PendingOrderItemDialog extends StatefulWidget {
  const _PendingOrderItemDialog({this.initial});

  final PendingOrderItem? initial;

  @override
  State<_PendingOrderItemDialog> createState() => _PendingOrderItemDialogState();
}

class _PendingOrderItemDialogState extends State<_PendingOrderItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _itemService = ItemService();
  late final TextEditingController _quantity;
  late final TextEditingController _unitPrice;
  late final TextEditingController _maintenanceMonths;

  List<Item> _items = [];
  Item? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(text: widget.initial?.quantity.toString() ?? '1');
    _unitPrice = TextEditingController(text: widget.initial?.unitPrice?.toString() ?? '');
    _maintenanceMonths = TextEditingController(
      text: widget.initial?.maintenanceIntervalMonths?.toString() ?? (widget.initial == null ? '12' : ''),
    );
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _itemService.list();
      Item? match;
      if (widget.initial != null) {
        for (final i in items) {
          if (i.id == widget.initial!.itemId) {
            match = i;
            break;
          }
        }
      }
      setState(() {
        _items = items;
        _selected = match;
      });
    } catch (_) {

    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    _unitPrice.dispose();
    _maintenanceMonths.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate() || _selected == null) return;
    Navigator.pop(
      context,
      PendingOrderItem(
        itemId: _selected!.id!,
        itemName: _selected!.name,
        quantity: int.parse(_quantity.text.trim()),
        unitPrice: _unitPrice.text.trim().isEmpty ? null : double.parse(_unitPrice.text.trim().replaceAll(',', '.')),
        maintenanceIntervalMonths: _maintenanceMonths.text.trim().isEmpty ? null : int.parse(_maintenanceMonths.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Adicionar item' : 'Editar item'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _loading
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator())
                  : DropdownButtonFormField<Item>(
                      initialValue: _selected,
                      decoration: const InputDecoration(labelText: 'Item'),
                      items: _items.map((i) => DropdownMenuItem(value: i, child: Text(i.name))).toList(),
                      onChanged: (v) => setState(() => _selected = v),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _confirm, child: const Text('Adicionar')),
      ],
    );
  }
}
