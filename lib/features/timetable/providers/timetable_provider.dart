import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/timetable/services/timetable_service.dart';
import 'package:cims/features/timetable/repository/timetable_repository.dart';

final timetableRepositoryProvider =
    Provider<TimetableRepository>((ref) {
  return TimetableRepository();
});

/// Family: (sessionId, stage) — optional staffId not in key; pass via custom call.
final timetableWeeklyProvider = FutureProvider.autoDispose
    .family<TimetableWeeklyResponse, ({int sessionId, int stage})>(
  (ref, args) async {
    final repo = ref.read(timetableRepositoryProvider);
    return repo.getWeekly(
      sessionId: args.sessionId,
      stage: args.stage,
    );
  },
);

final timetableSlotsListProvider = FutureProvider.autoDispose
    .family<List<TimetableSlot>, ({int sessionId, int? stage, int? staffId})>(
  (ref, args) async {
    final repo = ref.read(timetableRepositoryProvider);
    final raw = await repo.listSlots(
      sessionId: args.sessionId,
      stage: args.stage,
      staffId: args.staffId,
    );
    return raw.map((e) => TimetableSlot.fromJson(e)).toList();
  },
);
