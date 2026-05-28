// Feature providers: Provider for repositories, StateProvider for UI flags.
// Data flow: widget → repository → service / ApiClient → Dio (interceptors).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:cims/core/session/auth_session_controller.dart';
import 'package:cims/features/auth/models/current_user.dart';
import 'package:cims/features/auth/repository/auth_repository.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authLoadingProvider =
    StateProvider<bool>((ref) => false);

/// Fetches `/auth/me` when [AuthSessionController] reports signed-in.
final currentUserProvider =
    FutureProvider.autoDispose<CurrentUser?>(
  (ref) async {
    if (!AuthSessionController.instance
        .isAuthenticated) {
      return null;
    }
    return ref.read(authRepositoryProvider).getMe();
  },
);