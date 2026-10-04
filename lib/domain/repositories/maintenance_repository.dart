import '../../models/maintenance_due.dart';

abstract class MaintenanceRepository {
  Future<List<MaintenanceDue>> due({required DateTime from, required DateTime to});
}
