import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';

/// Full-screen search (mobile-first). Dynamic search over live student roster.
class SearchOverlayScreen extends ConsumerStatefulWidget {
  final void Function(String route) onNavigate;

  const SearchOverlayScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<SearchOverlayScreen> createState() =>
      _SearchOverlayScreenState();
}

class _SearchOverlayScreenState
    extends ConsumerState<SearchOverlayScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final strong = isDark ? AppColors.darkText : AppColors.text;

    final query = _controller.text.trim().toLowerCase();
    final studentsState = ref.watch(studentsListProvider);
    final allStudents = studentsState.value ?? [];

    final filteredStudents = query.isEmpty
        ? allStudents.take(5).toList()
        : allStudents.where((s) {
            return s.fullName.toLowerCase().contains(query) ||
                s.studentIdCode.toLowerCase().contains(query) ||
                (s.program?.code.toLowerCase().contains(query) ?? false);
          }).toList();

    return AppScaffold(
      title: 'Search',
      subtitle: 'CIMS',
      currentRoute: '/search',
      role: AppSession.currentRole,
      onNavigate: widget.onNavigate,
      suppressDefaultMobileSearch: true,
      actions: [
        IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search students by name, ID, or program…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => _controller.clear(),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            query.isEmpty ? 'Active Students' : 'Search Results (${filteredStudents.length})',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w800,
              color: strong,
            ),
          ),
          const SizedBox(height: 10),
          if (studentsState.isLoading && allStudents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredStudents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No matching students found.',
                style: AppTextStyles.bodySm.copyWith(color: muted),
              ),
            )
          else
            ...filteredStudents.map(
              (s) {
                final parts = s.fullName.trim().split(' ').where((p) => p.isNotEmpty);
                final initials = parts.take(2).map((e) => e[0].toUpperCase()).join();

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: isDark
                        ? AppColors.primary.withValues(alpha: 0.16)
                        : AppColors.primarySoft,
                    child: Text(
                      initials.isNotEmpty ? initials : 'ST',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    s.fullName,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${s.studentIdCode} · ${s.program?.code ?? 'General'}',
                    style: AppTextStyles.caption.copyWith(
                      color: muted,
                    ),
                  ),
                  onTap: () {
                    context.pop();
                    widget.onNavigate('/students');
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}