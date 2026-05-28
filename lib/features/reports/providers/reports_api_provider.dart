import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cims/features/reports/repository/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository();
});
