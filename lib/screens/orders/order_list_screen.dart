import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../di/service_locator.dart';
import '../../core/api_exception.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'order_create_screen.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key, this.personId, this.personName, this.actions});

  final String? personId;
  final String? personName;
  final List<Widget>? actions;

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final _orderService = sl<OrderService>();
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _scrollController = ScrollController();

  final List<Order> _orders = [];
  int _page = 0;
  bool _isLastPage = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _isLastPage = false;
      _orders.clear();
    });
    try {
      final result = await _orderService.page(
        personId: widget.personId,
        startDate: _startDate,
        endDate: _endDate,
        page: 0,
      );
      setState(() {
        _orders.addAll(result.content);
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
      final result = await _orderService.page(
        personId: widget.personId,
        startDate: _startDate,
        endDate: _endDate,
        page: nextPage,
      );
      setState(() {
        _page = nextPage;
        _orders.addAll(result.content);
        _isLastPage = result.last;
      });
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    _startDate = DateTime.utc(picked.year, picked.month, picked.day);
    _load();
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    _endDate = DateTime.utc(picked.year, picked.month, picked.day, 23, 59, 59);
    _load();
  }

  void _clearDateFilter() {
    _startDate = null;
    _endDate = null;
    _load();
  }

  Future<void> _openForm() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderCreateScreen(fixedPersonId: widget.personId, fixedPersonName: widget.personName),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _openDetail(Order order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id!)),
    );
    _load();
  }

  Future<void> _delete(Order order) async {
    final confirmed = await confirmDelete(context, title: 'Excluir pedido', message: 'Deseja excluir este pedido?');
    if (!confirmed) return;
    try {
      await _orderService.delete(order.id!);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.personName != null ? 'Pedidos de ${widget.personName}' : 'Pedidos'),
        actions: widget.actions,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickStartDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(_startDate != null ? 'De: ${_dateFormat.format(_startDate!)}' : 'De'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickEndDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(_endDate != null ? 'Até: ${_dateFormat.format(_endDate!)}' : 'Até'),
                  ),
                ),
                if (_startDate != null || _endDate != null)
                  IconButton(
                    tooltip: 'Limpar filtro de data',
                    onPressed: _clearDateFilter,
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
          ),
          Expanded(child: RefreshIndicator(onRefresh: _load, child: _buildBody())),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_orders_${widget.personId ?? 'all'}',
        onPressed: _openForm,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Tentar novamente')),
          ]),
        ),
      ]);
    }
    if (_orders.isEmpty) {
      final hasDateFilter = _startDate != null || _endDate != null;
      return ListView(children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(hasDateFilter
                ? 'Nenhum pedido encontrado no período selecionado.'
                : 'Nenhum pedido encontrado.'),
          ),
        ),
      ]);
    }
    return ListView.separated(
      controller: _scrollController,
      itemCount: _orders.length + 1,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == _orders.length) {
          if (_isLastPage) return const SizedBox.shrink();
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final order = _orders[index];
        return ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text(order.personName ?? 'Cliente #${order.personId}'),
          subtitle: Text(order.orderDate != null ? _dateFormat.format(order.orderDate!) : 'Sem data'),
          onTap: () => _openDetail(order),
          trailing: PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') _delete(order);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        );
      },
    );
  }
}
