import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/admin/sessions/models/academic_session_model.dart';
import 'package:cims/features/admin/sessions/repository/session_repository.dart';

final sessionRepositoryProvider =
    Provider<SessionRepository>((ref) {
  return SessionRepository();
});

final sessionsListProvider =
    FutureProvider.autoDispose<List<AcademicSessionModel>>(
  (ref) async {
    final repo = ref.read(sessionRepositoryProvider);
    return repo.listSessions();
  },
);

/// App-wide current academic session (nullable if none configured).
final currentAcademicSessionProvider =
    FutureProvider.autoDispose<AcademicSessionModel?>(
  (ref) async {
    final repo = ref.read(sessionRepositoryProvider);
    return repo.getCurrentWithFallback();
  },
);
