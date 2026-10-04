import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../di/service_locator.dart';
import '../../core/api_exception.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../services/order_item_service.dart';
import '../../services/order_service.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/order_item_form_dialog.dart';
import 'order_form_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orderService = sl<OrderService>();
  final _orderItemService = sl<OrderItemService>();
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  Order? _order;
  List<OrderItem> _orderItems = [];
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
        _orderService.getById(widget.orderId),
        _orderItemService.listByOrder(widget.orderId),
      ]);
      setState(() {
        _order = results[0] as Order;
        _orderItems = results[1] as List<OrderItem>;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _editOrder() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderFormScreen(order: _order, fixedPersonId: _order!.personId, fixedPersonName: _order!.personName),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _deleteOrder() async {
    final confirmed = await confirmDelete(context, title: 'Excluir pedido', message: 'Deseja excluir este pedido e seus itens?');
    if (!confirmed) return;
    try {
      await _orderService.delete(widget.orderId);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _addOrEditItem({OrderItem? orderItem}) async {
    final changed = await showOrderItemFormDialog(context, orderId: widget.orderId, orderItem: orderItem);
    if (changed) _load();
  }

  Future<void> _deleteItem(OrderItem item) async {
    final confirmed = await confirmDelete(context, title: 'Remover item', message: 'Deseja remover "${item.itemName ?? 'item'}" do pedido?');
    if (!confirmed) return;
    try {
      await _orderItemService.delete(item.id!);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  double get _total => _orderItems.fold(0, (sum, i) => sum + i.subtotal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido'),
        actions: _order == null
            ? null
            : [
                IconButton(onPressed: _editOrder, icon: const Icon(Icons.edit_outlined)),
                IconButton(onPressed: _deleteOrder, icon: const Icon(Icons.delete_outline)),
              ],
      ),
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
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_order!.personName ?? 'Cliente #${_order!.personId}',
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              if (_order!.orderDate != null)
                                Text('Data: ${DateFormat('dd/MM/yyyy').format(_order!.orderDate!)}'),
                              if (_order!.hasAddressSnapshot)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 18),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text([
                                          [_order!.addressStreet, _order!.addressNumber]
                                              .where((s) => s != null && s.isNotEmpty)
                                              .join(', '),
                                          if (_order!.addressNeighborhood != null && _order!.addressNeighborhood!.isNotEmpty)
                                            _order!.addressNeighborhood!,
                                          if (_order!.addressCityName != null && _order!.addressCityName!.isNotEmpty)
                                            _order!.addressCityName!,
                                        ].join(' - ')),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_order!.observation != null && _order!.observation!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(_order!.observation!),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Itens do pedido', style: Theme.of(context).textTheme.titleMedium),
                          IconButton(onPressed: () => _addOrEditItem(), icon: const Icon(Icons.add_circle_outline)),
                        ],
                      ),
                      if (_orderItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Nenhum item adicionado ainda.'),
                        ),
                      ..._orderItems.map((i) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.inventory_2_outlined),
                              title: Text(i.itemName ?? 'Item #${i.itemId}'),
                              subtitle: Text('Qtd: ${i.quantity}'
                                  '${i.unitPrice != null ? ' · ${_currency.format(i.unitPrice)} · Subtotal: ${_currency.format(i.subtotal)}' : ''}'
                                  '${i.maintenanceIntervalMonths != null ? ' · Manutenção a cada ${i.maintenanceIntervalMonths}m' : ''}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _addOrEditItem(orderItem: i);
                                  if (v == 'delete') _deleteItem(i);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                                  PopupMenuItem(value: 'delete', child: Text('Remover')),
                                ],
                              ),
                            ),
                          )),
                      if (_orderItems.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('Total: ${_currency.format(_total)}',
                                style: Theme.of(context).textTheme.titleMedium),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
