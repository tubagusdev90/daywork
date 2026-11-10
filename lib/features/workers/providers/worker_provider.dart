import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/worker_model.dart';
import '../services/worker_service.dart';

final workerServiceProvider = Provider<WorkerService>((ref) {
  return WorkerService();
});

final workersProvider = FutureProvider<List<Worker>>((ref) async {
  final service = ref.watch(workerServiceProvider);

  return service.getWorkers();
});