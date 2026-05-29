import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/features/admin/staff/models/staff_api_model.dart';
import 'package:cims/features/admin/staff/repository/staff_repository.dart';
import 'package:cims/features/auth/providers/auth_provider.dart';

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
        (s.lastName?.toLowerCase().contains(part) ?? false)
      );
      if (matchAllParts) return true;
    }

    return false;
  }).firstOrNull;

  return match;
});
