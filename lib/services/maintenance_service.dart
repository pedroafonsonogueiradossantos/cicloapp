import '../di/service_locator.dart';
import '../domain/repositories/maintenance_repository.dart';
import '../models/maintenance_due.dart';

class MaintenanceService {
  MaintenanceService({MaintenanceRepository? repository}) : _maintenance = repository ?? sl<MaintenanceRepository>();

  final MaintenanceRepository _maintenance;

  Future<List<MaintenanceDue>> due({required DateTime from, required DateTime to}) =>
      _maintenance.due(from: from, to: to);
}
