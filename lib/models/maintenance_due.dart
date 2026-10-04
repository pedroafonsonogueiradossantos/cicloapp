class MaintenanceDue {
  final String personId;
  final String personName;
  final String itemId;
  final String itemName;
  final String lastOrderId;
  final DateTime lastOrderDate;
  final int maintenanceIntervalMonths;
  final DateTime dueDate;
  final List<String> phoneNumbers;

  MaintenanceDue({
    required this.personId,
    required this.personName,
    required this.itemId,
    required this.itemName,
    required this.lastOrderId,
    required this.lastOrderDate,
    required this.maintenanceIntervalMonths,
    required this.dueDate,
    required this.phoneNumbers,
  });
}
