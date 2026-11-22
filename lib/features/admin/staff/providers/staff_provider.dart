import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/admin/staff/models/staff_api_model.dart';
import 'package:cims/features/admin/staff/repository/staff_repository.dart';
import 'package:cims/features/auth/providers/auth_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/subjects/models/subject_api_model.dart';
import 'package:cims/features/admin/subjects/providers/subject_provider.dart';

final staffRepositoryProvider =
    Provider<StaffRepository>((ref) {
  return StaffRepository();
});

/// Optional [category] e.g. `MEDICAL` (API enum). Null loads all.
final staffListProvider = FutureProvider.autoDispose
    .family<List<StaffApiModel>, String?>(
  (ref, category) async {
    final repo = ref.read(staffRepositoryProvider);
    return repo.listStaff(category: category, isActive: true);
  },
);

/// Loads all staff (both active and inactive) for Staff Management view
final allStaffListProvider = FutureProvider.autoDispose
    .family<List<StaffApiModel>, String?>(
  (ref, category) async {
    final repo = ref.read(staffRepositoryProvider);
    return repo.listStaff(category: category, isActive: null);
  },
);

/// Logged-in staff record, resolved by matching email from currentUser.
final currentStaffProvider = FutureProvider.autoDispose<StaffApiModel?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null || (user.role != 'teacher' && user.role != 'admin')) return null;

  final staff = await ref.watch(allStaffListProvider(null).future);
  
  // Try to match by email, username, or name parts
  final match = staff.where((s) {
    final staffEmail = s.email?.toLowerCase();
    final userEmail = user.username.contains('@') ? user.username.toLowerCase() : '${user.username.toLowerCase()}@cims.edu.pk';
    if (staffEmail == userEmail) return true;

    final usernameLower = user.username.toLowerCase();
    final fullNameLower = s.fullName.toLowerCase();
    final firstNameLower = s.firstName.toLowerCase();
    
    if (fullNameLower == usernameLower || firstNameLower == usernameLower) return true;

    // Split username by '.', '_', '-', '@' and check if name contains all parts
    final parts = usernameLower.split(RegExp(r'[._\-\@]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      final matchAllParts = parts.every((part) => 
        fullNameLower.contains(part) || 
        firstNameLower.contains(part) || 
        s.lastName.toLowerCase().contains(part)
      );
      if (matchAllParts) return true;
    }

    return false;
  }).firstOrNull;

  return match;
});

/// The subjects assigned to the logged-in teacher for the active academic session.
final teacherAssignedSubjectsProvider = FutureProvider.autoDispose<List<SubjectApiModel>>((ref) async {
  final staff = await ref.watch(currentStaffProvider.future);
  if (staff == null) return [];

  final session = await ref.watch(currentAcademicSessionProvider.future);
  final sessionId = session?.id;

  try {
    final res = await ref.read(staffRepositoryProvider).getStaffSubjects(staff.id, sessionId: sessionId);
    final assignments = res['assignments'] as List? ?? [];
    final allSubjects = ref.watch(subjectsListProvider).value ?? [];
    final subjectMap = {for (final s in allSubjects) s.id: s};

    final List<SubjectApiModel> list = [];
    for (var a in assignments) {
      final rawSub = (a is Map) ? a['subject'] : null;
      if (rawSub is Map) {
        final subId = rawSub['id'] as int? ?? 0;
        final fullSub = subjectMap[subId];
        list.add(SubjectApiModel(
          id: subId,
          name: rawSub['name'] as String? ?? (fullSub?.name ?? ''),
          code: rawSub['code'] as String? ?? (fullSub?.code ?? ''),
          stage: fullSub?.stage ?? (rawSub['stage'] as int? ?? 1),
          creditHours: (rawSub['credit_hours'] as num?)?.toDouble() ?? (fullSub?.creditHours ?? 3.0),
          hasPractical: rawSub['has_practical'] as bool? ?? (fullSub?.hasPractical ?? false),
          isActive: true,
          createdAt: DateTime.now(),
          program: fullSub?.program,
        ));
      }
    }
    return list;
  } catch (e) {
    return [];
  }
});
