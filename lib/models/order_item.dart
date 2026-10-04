class OrderItem {
  final String? id;
  final String orderId;
  final String itemId;
  final String? itemName;
  final int quantity;
  final double? unitPrice;
  final int? maintenanceIntervalMonths;

  OrderItem({
    this.id,
    required this.orderId,
    required this.itemId,
    this.itemName,
    required this.quantity,
    this.unitPrice,
    this.maintenanceIntervalMonths,
  });

  double get subtotal => (unitPrice ?? 0) * quantity;

  factory OrderItem.fromJson(String id, Map<String, dynamic> json) => OrderItem(
        id: id,
        orderId: json['orderId'] as String? ?? '',
        itemId: json['itemId'] as String? ?? '',
        itemName: json['itemName'] as String?,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble(),
        maintenanceIntervalMonths: json['maintenanceIntervalMonths'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'itemId': itemId,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'maintenanceIntervalMonths': maintenanceIntervalMonths,
      };
}
