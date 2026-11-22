import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/network/dio_error_message.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/widgets/stat_card.dart';

import 'package:cims/features/admin/enrollments/models/enrollment_model.dart';
import 'package:cims/features/admin/enrollments/providers/enrollment_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/sessions/models/academic_session_model.dart';
import 'package:cims/features/admin/programs/providers/program_provider.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/admin/subjects/providers/subject_provider.dart';

class EnrollmentsScreen extends ConsumerStatefulWidget {
  final void Function(String route) onNavigate;

  const EnrollmentsScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<EnrollmentsScreen> createState() => _EnrollmentsScreenState();
}

class _EnrollmentsScreenState extends ConsumerState<EnrollmentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  int? _selectedSessionId;
  int? _selectedStage;
  String? _selectedStatus; // null = all, 'ongoing', 'completed', 'dropped', 'absent'
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val.trim();
    });
  }

  void _refreshList() {
    ref.invalidate(enrollmentsTypedListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    final sessionsAsync = ref.watch(sessionsListProvider);
    final filterArgs = EnrollmentFilterArgs(
      sessionId: _selectedSessionId,
      stage: _selectedStage,
      status: _selectedStatus,
      search: _searchQuery,
    );
    final enrollmentsAsync = ref.watch(enrollmentsTypedListProvider(filterArgs));

    return AppScaffold(
      title: 'Enrollments',
      subtitle: 'ACADEMICS',
      currentRoute: '/enrollments',
      role: 'admin',
      onNavigate: widget.onNavigate,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _refreshList,
        ),
      ],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TOP STATS ──────────────────────────────────────────────────
            enrollmentsAsync.when(
              data: (items) => _buildStatsRow(items, isMobile, isDark),
              loading: () => _buildStatsRow([], isMobile, isDark, isLoading: true),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // ── ACTION & FILTER TOOLBAR ────────────────────────────────────
            _buildToolbar(context, sessionsAsync, isMobile, isDark),
            const SizedBox(height: 16),

            // ── ENROLLMENTS DATA TABLE / LIST ──────────────────────────────
            enrollmentsAsync.when(
              loading: () => Container(
                height: 280,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: const CircularProgressIndicator(),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 44),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load enrollments: $err',
                      style: AppTextStyles.body.copyWith(
                        color: isDark ? AppColors.darkText : AppColors.text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _refreshList,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
              data: (enrollments) {
                if (enrollments.isEmpty) {
                  return _buildEmptyState(isDark);
                }
                return isMobile
                    ? _buildMobileCardList(enrollments, isDark)
                    : _buildDesktopTable(enrollments, isDark);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STATS CARDS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStatsRow(List<EnrollmentModel> items, bool isMobile, bool isDark, {bool isLoading = false}) {
    final total = items.length;
    final ongoing = items.where((e) => e.isOngoing).length;
    final completed = items.where((e) => e.isCompleted).length;
    final dropped = items.where((e) => e.isDropped).length;
    final absent = items.where((e) => e.isAbsent).length;

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'TOTAL ENROLLMENTS',
                  value: isLoading ? '...' : total.toString(),
                  icon: Icons.how_to_reg_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'ONGOING',
                  value: isLoading ? '...' : ongoing.toString(),
                  icon: Icons.sync_rounded,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'COMPLETED',
                  value: isLoading ? '...' : completed.toString(),
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'DROPPED',
                  value: isLoading ? '...' : dropped.toString(),
                  icon: Icons.remove_circle_outline_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'ABSENT',
                  value: isLoading ? '...' : absent.toString(),
                  icon: Icons.person_off_rounded,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      );
    }

    final isTablet = Responsive.isTablet(context);
    if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'TOTAL ENROLLMENTS',
                  value: isLoading ? '...' : total.toString(),
                  icon: Icons.how_to_reg_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'ONGOING CLASSES',
                  value: isLoading ? '...' : ongoing.toString(),
                  icon: Icons.sync_rounded,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'COMPLETED',
                  value: isLoading ? '...' : completed.toString(),
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'DROPPED',
                  value: isLoading ? '...' : dropped.toString(),
                  icon: Icons.remove_circle_outline_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'ABSENT',
                  value: isLoading ? '...' : absent.toString(),
                  icon: Icons.person_off_rounded,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'TOTAL ENROLLMENTS',
            value: isLoading ? '...' : total.toString(),
            icon: Icons.how_to_reg_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            label: 'ONGOING CLASSES',
            value: isLoading ? '...' : ongoing.toString(),
            icon: Icons.sync_rounded,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            label: 'COMPLETED',
            value: isLoading ? '...' : completed.toString(),
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            label: 'DROPPED',
            value: isLoading ? '...' : dropped.toString(),
            icon: Icons.remove_circle_outline_rounded,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            label: 'ABSENT',
            value: isLoading ? '...' : absent.toString(),
            icon: Icons.person_off_rounded,
            color: AppColors.danger,
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOOLBAR & FILTERS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildToolbar(
    BuildContext context,
    AsyncValue<List<AcademicSessionModel>> sessionsAsync,
    bool isMobile,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actions Row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Course Enrollments',
                  style: AppTextStyles.h4.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 18,
                    vertical: isMobile ? 10 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: Text(isMobile ? 'Bulk' : '⚡ Bulk Enroll Class'),
                onPressed: () => _openBulkEnrollModal(context),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 10 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: Text(isMobile ? 'Single' : 'Single Enroll'),
                onPressed: () => _openSingleEnrollModal(context),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Repeat Subject'),
                  onPressed: () => _openRepeatEnrollModal(context),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Filters Row
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search Field
              SizedBox(
                width: isMobile ? double.infinity : 260,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search student or subject...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? AppColors.darkInputBg : AppColors.inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radius),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                  ),
                ),
              ),

              // Session Dropdown
              sessionsAsync.when(
                data: (sessions) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkInputBg : AppColors.inputBg,
                    borderRadius: BorderRadius.circular(AppConstants.radius),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedSessionId,
                      hint: const Text('All Sessions'),
                      dropdownColor: isDark ? AppColors.darkCardBg : AppColors.surface,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Academic Sessions'),
                        ),
                        ...sessions.map(
                          (s) => DropdownMenuItem<int?>(
                            value: s.id,
                            child: Text(
                              '${s.name}${s.isCurrent ? ' (Current)' : ''}',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedSessionId = val;
                        });
                      },
                    ),
                  ),
                ),
                loading: () => const SizedBox(
                  width: 140,
                  height: 38,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Stage Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkInputBg : AppColors.inputBg,
                  borderRadius: BorderRadius.circular(AppConstants.radius),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedStage,
                    hint: const Text('All Stages'),
                    dropdownColor: isDark ? AppColors.darkCardBg : AppColors.surface,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Stages / Semesters'),
                      ),
                      for (int st = 1; st <= 8; st++)
                        DropdownMenuItem<int?>(
                          value: st,
                          child: Text('Stage / Semester $st'),
                        ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedStage = val;
                      });
                    },
                  ),
                ),
              ),

              // Status Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkInputBg : AppColors.inputBg,
                  borderRadius: BorderRadius.circular(AppConstants.radius),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedStatus,
                    hint: const Text('All Statuses'),
                    dropdownColor: isDark ? AppColors.darkCardBg : AppColors.surface,
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Statuses'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'ongoing',
                        child: Text('Ongoing'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'completed',
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'dropped',
                        child: Text('Dropped'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'absent',
                        child: Text('Absent'),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedStatus = val;
                      });
                    },
                  ),
                ),
              ),

              if (_selectedSessionId != null ||
                  _selectedStage != null ||
                  _selectedStatus != null ||
                  _searchQuery.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedSessionId = null;
                      _selectedStage = null;
                      _selectedStatus = null;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                  label: const Text('Reset Filters'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DESKTOP TABLE VIEW
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDesktopTable(List<EnrollmentModel> enrollments, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            isDark ? AppColors.darkBorderSoft : AppColors.primary.withValues(alpha: 0.04),
          ),
          dataRowMinHeight: 64,
          dataRowMaxHeight: 72,
          horizontalMargin: 20,
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('STUDENT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
            DataColumn(label: Text('SUBJECT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
            DataColumn(label: Text('SESSION & STAGE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
            DataColumn(label: Text('ATTEMPT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
            DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
            DataColumn(label: Text('ENROLLED DATE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
            DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
          ],
          rows: enrollments.map((item) {
            return DataRow(
              cells: [
                // Student info
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          _getInitials(item.student.fullName),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.student.fullName,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkText : AppColors.text,
                            ),
                          ),
                          Text(
                            item.student.studentIdCode,
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Subject info
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.subject.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkText : AppColors.text,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            item.subject.code,
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (item.subject.hasPractical) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LAB',
                                style: TextStyle(
                                  color: AppColors.info,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Session & Stage
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.session.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkText : AppColors.text,
                        ),
                      ),
                      Text(
                        'Stage ${item.subject.stage}',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Attempt
                DataCell(
                  item.attemptNumber > 1
                      ? BadgeChip(
                          label: 'Repeat #${item.attemptNumber}',
                          color: AppColors.warning,
                        )
                      : BadgeChip(
                          label: '1st Sit',
                          color: AppColors.primary,
                        ),
                ),

                // Status
                DataCell(
                  _buildStatusBadge(item.status),
                ),

                // Date
                DataCell(
                  Text(
                    item.formattedDate,
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  ),
                ),

                // Actions
                DataCell(
                  PopupMenuButton<String>(
                    tooltip: 'Options',
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (action) => _handleAction(action, item),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'status',
                        child: Row(
                          children: [
                            Icon(Icons.edit_note_rounded, size: 18),
                            SizedBox(width: 10),
                            Text('Change Status'),
                          ],
                        ),
                      ),
                      if (item.isOngoing)
                        const PopupMenuItem(
                          value: 'drop',
                          child: Row(
                            children: [
                              Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppColors.warning),
                              SizedBox(width: 10),
                              Text('Drop Course', style: TextStyle(color: AppColors.warning)),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                            SizedBox(width: 10),
                            Text('Delete Record', style: TextStyle(color: AppColors.danger)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MOBILE CARD LIST VIEW
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMobileCardList(List<EnrollmentModel> enrollments, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: enrollments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final item = enrollments[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      _getInitials(item.student.fullName),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.student.fullName,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkText : AppColors.text,
                          ),
                        ),
                        Text(
                          item.student.studentIdCode,
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(item.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.subject.name,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkText : AppColors.text,
                          ),
                        ),
                        Text(
                          '${item.subject.code} · Stage ${item.subject.stage} · ${item.session.name}',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.attemptNumber > 1)
                    BadgeChip(
                      label: 'Repeat #${item.attemptNumber}',
                      color: AppColors.warning,
                    )
                  else
                    BadgeChip(
                      label: '1st Sit',
                      color: AppColors.primary,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enrolled: ${item.formattedDate}',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.edit_note_rounded, size: 16),
                        label: const Text('Status'),
                        onPressed: () => _handleAction('status', item),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                        onPressed: () => _handleAction('delete', item),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // EMPTY STATE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.how_to_reg_rounded,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Enrollments Found',
            style: AppTextStyles.h4.copyWith(
              color: isDark ? AppColors.darkText : AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedSessionId != null || _selectedStage != null
                ? 'Try adjusting your filters or search keywords.'
                : 'Click "⚡ Bulk Enroll Class" to enroll all students into a stage at once.',
            style: AppTextStyles.body.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openBulkEnrollModal(context),
            icon: const Icon(Icons.flash_on_rounded, size: 18),
            label: const Text('⚡ Bulk Enroll Now'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ACTIONS HANDLER
  // ───────────────────────────────────────────────────────────────────────────
  void _handleAction(String action, EnrollmentModel item) {
    switch (action) {
      case 'status':
        _openChangeStatusDialog(item);
        break;
      case 'drop':
        _confirmDropCourse(item);
        break;
      case 'delete':
        _confirmDeleteEnrollment(item);
        break;
    }
  }

  void _confirmDropCourse(EnrollmentModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Drop Enrollment?'),
        content: Text(
          'Are you sure you want to drop "${item.subject.name}" for student ${item.student.fullName} (${item.student.studentIdCode})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(enrollmentRepositoryProvider).dropEnrollment(item.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Course dropped successfully.')),
                  );
                  _refreshList();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error dropping course: $e')),
                  );
                }
              }
            },
            child: const Text('Drop Course'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEnrollment(EnrollmentModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Enrollment Record?'),
        content: Text(
          'This will permanently remove the enrollment of ${item.student.fullName} in "${item.subject.name}". Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(enrollmentRepositoryProvider).deleteEnrollment(item.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enrollment deleted successfully.')),
                  );
                  _refreshList();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting enrollment: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openChangeStatusDialog(EnrollmentModel item) {
    String currentStatus = item.status.toLowerCase();
    final remarksCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Change Status: ${item.student.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subject: ${item.subject.name} (${item.subject.code})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: ['ongoing', 'completed', 'dropped', 'absent', 'suspended', 'canceled'].contains(currentStatus)
                    ? currentStatus
                    : 'ongoing',
                decoration: const InputDecoration(
                  labelText: 'Enrollment Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'dropped', child: Text('Dropped')),
                  DropdownMenuItem(value: 'absent', child: Text('Absent')),
                  DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                  DropdownMenuItem(value: 'canceled', child: Text('Canceled')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() {
                      currentStatus = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: remarksCtrl,
                decoration: const InputDecoration(
                  labelText: 'Remarks / Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(enrollmentRepositoryProvider).updateEnrollmentStatus(
                    item.id,
                    status: currentStatus,
                    remarks: remarksCtrl.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Status updated successfully!')),
                    );
                    _refreshList();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update status: $e')),
                    );
                  }
                }
              },
              child: const Text('Save Status'),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BULK ENROLL MODAL
  // ───────────────────────────────────────────────────────────────────────────
  void _openBulkEnrollModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BulkEnrollDialog(
        onSuccess: () {
          _refreshList();
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SINGLE ENROLL MODAL
  // ───────────────────────────────────────────────────────────────────────────
  void _openSingleEnrollModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _SingleEnrollDialog(
        isRepeat: false,
        onSuccess: () {
          _refreshList();
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // REPEAT ENROLL MODAL
  // ───────────────────────────────────────────────────────────────────────────
  void _openRepeatEnrollModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _SingleEnrollDialog(
        isRepeat: true,
        onSuccess: () {
          _refreshList();
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStatusBadge(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return const BadgeChip(label: 'Ongoing', color: AppColors.info);
      case 'completed':
        return const BadgeChip(label: 'Completed', color: AppColors.success);
      case 'dropped':
        return const BadgeChip(label: 'Dropped', color: AppColors.warning);
      case 'absent':
        return const BadgeChip(label: 'Absent', color: AppColors.danger);
      default:
        return BadgeChip(label: status, color: AppColors.slate);
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'ST';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BULK ENROLL DIALOG WIDGET
// ═════════════════════════════════════════════════════════════════════════════
class _BulkEnrollDialog extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const _BulkEnrollDialog({required this.onSuccess});

  @override
  ConsumerState<_BulkEnrollDialog> createState() => _BulkEnrollDialogState();
}

class _BulkEnrollDialogState extends ConsumerState<_BulkEnrollDialog> {
  int? _selectedProgramId;
  int? _selectedSessionId;
  int _selectedStage = 1;
  bool _isSubmitting = false;
  String? _errorMessage;
  BulkEnrollResultModel? _result;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final programsAsync = ref.watch(programsProvider);
    final sessionsAsync = ref.watch(sessionsListProvider);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.flash_on_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Text('⚡ Bulk Enroll Class'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enroll all active students of a specific program and stage into all corresponding subjects at once.',
                style: AppTextStyles.bodySm.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            _result!.message,
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('• Enrolled Records: ${_result!.enrolled}'),
                      Text('• Skipped (Already Enrolled): ${_result!.skipped}'),
                      Text('• Total Students Processed: ${_result!.totalStudents}'),
                      Text('• Total Subjects Enrolled: ${_result!.totalSubjects}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Program Selector
              programsAsync.when(
                data: (programs) {
                  final activePrograms = programs.where((p) => p.isActive).toList();
                  return DropdownButtonFormField<int>(
                    value: _selectedProgramId,
                    decoration: const InputDecoration(
                      labelText: 'Select Program *',
                      border: OutlineInputBorder(),
                    ),
                    items: activePrograms.map((p) {
                      return DropdownMenuItem<int>(
                        value: p.id,
                        child: Text('${p.name} (${p.code})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedProgramId = val;
                        _selectedStage = 1;
                      });
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading programs: $e'),
              ),
              const SizedBox(height: 16),

              // Stage Selector
              Builder(
                builder: (context) {
                  int maxStages = 8;
                  if (_selectedProgramId != null && programsAsync.hasValue) {
                    final matched = programsAsync.value!.where((p) => p.id == _selectedProgramId).firstOrNull;
                    if (matched != null) {
                      maxStages = matched.totalStages;
                    }
                  }

                  return DropdownButtonFormField<int>(
                    value: _selectedStage <= maxStages ? _selectedStage : 1,
                    decoration: const InputDecoration(
                      labelText: 'Stage / Semester *',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (int st = 1; st <= maxStages; st++)
                        DropdownMenuItem<int>(
                          value: st,
                          child: Text('Stage / Semester $st'),
                        ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedStage = val;
                        });
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Academic Session Selector
              sessionsAsync.when(
                data: (sessions) {
                  if (_selectedSessionId == null && sessions.isNotEmpty) {
                    final curr = sessions.where((s) => s.isCurrent).firstOrNull;
                    _selectedSessionId = curr?.id ?? sessions.first.id;
                  }

                  return DropdownButtonFormField<int>(
                    value: _selectedSessionId,
                    decoration: const InputDecoration(
                      labelText: 'Academic Session *',
                      border: OutlineInputBorder(),
                    ),
                    items: sessions.map((s) {
                      return DropdownMenuItem<int>(
                        value: s.id,
                        child: Text('${s.name}${s.isCurrent ? ' (Current)' : ''}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSessionId = val;
                      });
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading sessions: $e'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(_result != null ? 'Close' : 'Cancel'),
        ),
        if (_result == null)
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.flash_on_rounded, size: 18),
            label: Text(_isSubmitting ? 'Enrolling...' : 'Run Bulk Enrollment'),
            onPressed: _isSubmitting ? null : _submitBulkEnroll,
          ),
      ],
    );
  }

  Future<void> _submitBulkEnroll() async {
    if (_selectedProgramId == null || _selectedSessionId == null) {
      setState(() {
        _errorMessage = 'Please select a program and academic session.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await ref.read(enrollmentRepositoryProvider).bulkEnroll({
        'program_id': _selectedProgramId,
        'stage': _selectedStage,
        'session_id': _selectedSessionId,
      });

      setState(() {
        _result = BulkEnrollResultModel.fromJson(res);
        _isSubmitting = false;
      });
      widget.onSuccess();
    } on DioException catch (e) {
      setState(() {
        _errorMessage = extractDioErrorMessage(e);
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SINGLE / REPEAT ENROLL DIALOG WIDGET
// ═════════════════════════════════════════════════════════════════════════════
class _SingleEnrollDialog extends ConsumerStatefulWidget {
  final bool isRepeat;
  final VoidCallback onSuccess;

  const _SingleEnrollDialog({
    required this.isRepeat,
    required this.onSuccess,
  });

  @override
  ConsumerState<_SingleEnrollDialog> createState() => _SingleEnrollDialogState();
}

class _SingleEnrollDialogState extends ConsumerState<_SingleEnrollDialog> {
  int? _selectedProgramId;
  int? _selectedStudentId;
  int? _selectedSubjectId;
  int? _selectedSessionId;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final programsAsync = ref.watch(programsProvider);
    final sessionsAsync = ref.watch(sessionsListProvider);
    final studentsAsync = ref.watch(studentsListProvider);
    final subjectsAsync = ref.watch(subjectsListProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isRepeat ? Icons.replay_rounded : Icons.person_add_alt_1_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Text(widget.isRepeat ? '🔄 Repeat Subject Enrollment' : '➕ Single Student Enrollment'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isRepeat
                    ? 'Enroll a student who needs to repeat a previously attempted or failed subject in a new academic session.'
                    : 'Enroll an individual student into a specific subject for the selected session.',
                style: AppTextStyles.bodySm.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Academic Session
              sessionsAsync.when(
                data: (sessions) {
                  if (_selectedSessionId == null && sessions.isNotEmpty) {
                    final curr = sessions.where((s) => s.isCurrent).firstOrNull;
                    _selectedSessionId = curr?.id ?? sessions.first.id;
                  }

                  return DropdownButtonFormField<int>(
                    value: _selectedSessionId,
                    decoration: const InputDecoration(
                      labelText: 'Session *',
                      border: OutlineInputBorder(),
                    ),
                    items: sessions.map((s) {
                      return DropdownMenuItem<int>(
                        value: s.id,
                        child: Text('${s.name}${s.isCurrent ? ' (Current)' : ''}'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSessionId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading sessions: $e'),
              ),
              const SizedBox(height: 16),

              // Filter by Program
              programsAsync.when(
                data: (programs) {
                  return DropdownButtonFormField<int?>(
                    value: _selectedProgramId,
                    decoration: const InputDecoration(
                      labelText: 'Program Filter (optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All Programs')),
                      ...programs.map(
                        (p) => DropdownMenuItem<int?>(value: p.id, child: Text('${p.name} (${p.code})')),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedProgramId = val;
                        _selectedStudentId = null;
                        _selectedSubjectId = null;
                      });
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // Student Selector
              studentsAsync.when(
                data: (students) {
                  var filteredStudents = students;
                  if (_selectedProgramId != null) {
                    filteredStudents = filteredStudents.where((s) => s.program?.id == _selectedProgramId).toList();
                  }

                  return DropdownButtonFormField<int>(
                    value: _selectedStudentId,
                    decoration: const InputDecoration(
                      labelText: 'Select Student *',
                      border: OutlineInputBorder(),
                    ),
                    items: filteredStudents.map((s) {
                      return DropdownMenuItem<int>(
                        value: s.id,
                        child: Text(
                          '${s.fullName} (${s.studentIdCode})${s.program != null ? ' · ${s.program!.code}' : ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedStudentId = val;
                        // Auto match program if student has one
                        final stu = students.where((s) => s.id == val).firstOrNull;
                        if (stu?.program != null && _selectedProgramId == null) {
                          _selectedProgramId = stu!.program!.id;
                        }
                      });
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading students: $e'),
              ),
              const SizedBox(height: 16),

              // Subject Selector
              subjectsAsync.when(
                data: (subjects) {
                  var filteredSubjects = subjects;
                  if (_selectedProgramId != null) {
                    filteredSubjects = filteredSubjects.where((s) => s.program?.id == _selectedProgramId).toList();
                  }

                  return DropdownButtonFormField<int>(
                    value: _selectedSubjectId,
                    decoration: const InputDecoration(
                      labelText: 'Select Subject *',
                      border: OutlineInputBorder(),
                    ),
                    items: filteredSubjects.map((sub) {
                      return DropdownMenuItem<int>(
                        value: sub.id,
                        child: Text(
                          '${sub.name} (${sub.code}) · Stage ${sub.stage}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSubjectId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading subjects: $e'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(widget.isRepeat ? Icons.replay_rounded : Icons.check_rounded, size: 18),
          label: Text(_isSubmitting
              ? 'Enrolling...'
              : widget.isRepeat
                  ? 'Confirm Repeat'
                  : 'Enroll Student'),
          onPressed: _isSubmitting ? null : _submitSingleEnroll,
        ),
      ],
    );
  }

  Future<void> _submitSingleEnroll() async {
    if (_selectedStudentId == null || _selectedSubjectId == null || _selectedSessionId == null) {
      setState(() {
        _errorMessage = 'Please select a student, subject, and session.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(enrollmentRepositoryProvider);
      final body = {
        'student_id': _selectedStudentId,
        'subject_id': _selectedSubjectId,
        'session_id': _selectedSessionId,
      };

      if (widget.isRepeat) {
        await repo.repeatEnrollment(body);
      } else {
        await repo.enrollSingle(body);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isRepeat
                  ? 'Student enrolled for subject repeat successfully!'
                  : 'Student enrolled in subject successfully!',
            ),
          ),
        );
        widget.onSuccess();
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = extractDioErrorMessage(e);
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }
}
