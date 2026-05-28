import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/utils/modal_helpers.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/widgets/stat_card.dart';
import 'package:cims/core/session/app_session.dart';

import 'package:cims/features/admin/departments/models/department_category.dart';
import 'package:cims/features/admin/departments/models/department_model.dart';
import 'package:cims/features/admin/departments/providers/department_provider.dart';

import 'package:cims/features/admin/departments/add_department_modal.dart';

// =====================================================
// SCREEN
// =====================================================

class DepartmentsScreen extends ConsumerStatefulWidget {
  final void Function(String route) onNavigate;

  const DepartmentsScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<DepartmentsScreen> createState() =>
      _DepartmentsScreenState();
}

class _DepartmentsScreenState
    extends ConsumerState<DepartmentsScreen> {
  String _activeTab = 'All';

  String _statusFilter =
      'All Status';

  String _search = '';

  final _searchCtrl =
      TextEditingController();

  final _tabs = const [
    'All',
    'Medical',
    'Academic',
    'Nursing',
    'Admin',
    'Finance',
  ];

  List<DepartmentModel> _filtered(
    List<DepartmentModel> departments,
  ) {
    final apiCategory = DepartmentCategory.apiFromTab(_activeTab);

    return departments.where((d) {
      final tabMatch =
          apiCategory == null ||
          d.category.toLowerCase() == apiCategory;

      final statusMatch =
          _statusFilter ==
                  'All Status' ||
              (_statusFilter == 'Active' && d.isActive) ||
              (_statusFilter == 'Inactive' && !d.isActive);

      final searchMatch =
          _search.isEmpty ||
              d.name
                  .toLowerCase()
                  .contains(
                    _search
                        .toLowerCase(),
                  ) ||
              d.code
                  .toLowerCase()
                  .contains(
                    _search
                        .toLowerCase(),
                  );

      return tabMatch &&
          statusMatch &&
          searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final departmentsState =
        ref.watch(
          departmentsProvider,
        );

    final departmentsData = departmentsState.value ?? [];

    final departments =
        _filtered(
          departmentsData,
        );

    final totalPrograms = 0;

    final totalStudents = 0;

    final activeDepartments =
        departmentsData
            .where(
              (
                e,
              ) =>
                  e.isActive,
            )
            .length;

    return AppScaffold(
      title:
          'Departments Management',

      subtitle: 'ACADEMICS',

      currentRoute:
          '/departments',

      role: AppSession.currentRole,

      onNavigate:
          widget.onNavigate,

      body: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          SizedBox(
            height: 12,
          ),

          // =========================================
          // STATS
          // =========================================

          _StatsSection(
            departments:
                departmentsData.length,

            active:
                activeDepartments,

            programs:
                totalPrograms,

            students:
                totalStudents,
          ),

          SizedBox(height: 16),

          // =========================================
          // TABS
          // =========================================

          _CategoryTabs(
            tabs: _tabs,
            active:
                _activeTab,

            totalCount:
                departmentsData.length,

            onSelect:
                (
                  t,
                ) => setState(
                  () =>
                      _activeTab =
                          t,
                ),
          ),

          SizedBox(
            height: 16,
          ),

          // =========================================
          // TOOLBAR
          // =========================================

          _Toolbar(
            controller:
                _searchCtrl,

            status:
                _statusFilter,

            onSearch:
                (
                  v,
                ) => setState(
                  () =>
                      _search =
                          v,
                ),

            onStatus:
                (
                  v,
                ) => setState(
                  () =>
                      _statusFilter =
                          v!,
                ),

            onExport: () {},

            onAdd:
                () => _showAddModal(
                  context,
                ),
          ),

          SizedBox(
            height: 16,
          ),

          // =========================================
          // CONTENT
          // =========================================

          if (departmentsState.isLoading && departmentsData.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (departmentsState.hasError && departmentsData.isEmpty)
            _DepartmentsError(
              message: '$departmentsState.error',
              onRetry:
                  () => ref.invalidate(departmentsProvider),
            )
          else if (departments.isEmpty)
            const _EmptyState()
          else if (Responsive.isMobile(
            context,
          ))
            _MobileList(
              depts:
                  departments,

              onEdit:
                  (dept) => _showAddModal(
                    context,
                    department: dept,
                  ),
            )
          else
            _DepartmentTable(
              depts:
                  departments,

              isDark:
                  isDark,

              onEdit:
                  (dept) => _showAddModal(
                    context,
                    department: dept,
                  ),
            ),
        ],
      ),
    );
  }

  
   
  void _showAddModal(
    BuildContext context, {
    DepartmentModel? department,
  }) {
    showResponsiveModal(
      context: context,
      child: AddDepartmentModal(department: department),
    );
  }
}

class _DepartmentsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DepartmentsError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.darkTextMuted,
              ),
            ),
            SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// STATS
// =====================================================

class _StatsSection extends StatelessWidget {
  final int departments;
  final int active;
  final int programs;
  final int students;

  const _StatsSection({
    required this.departments,
    required this.active,
    required this.programs,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;

    final card1 = StatCard(
      label: 'Departments',
      value: '$departments',
      trend: '+2 this year',
      tone: StatTone.primary,
      icon: const Icon(Icons.account_balance),
    );

    final card2 = StatCard(
      label: 'Active',
      value: '$active',
      trend: 'Operational',
      tone: StatTone.success,
      icon: const Icon(Icons.check_circle),
    );

    final card3 = StatCard(
      label: 'Programs',
      value: '$programs',
      trend: 'Across all depts',
      tone: StatTone.accent,
      icon: const Icon(Icons.school),
    );

    final card4 = StatCard(
      label: 'Students',
      value: '$students',
      trend: '+8.2% growth',
      tone: StatTone.purple,
      icon: const Icon(Icons.people),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          card1,
          const SizedBox(height: 12),
          card2,
          const SizedBox(height: 12),
          card3,
          const SizedBox(height: 12),
          card4,
        ],
      );
    }

    if (isTablet) {
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: card1),
                const SizedBox(width: 12),
                Expanded(child: card2),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: card3),
                const SizedBox(width: 12),
                Expanded(child: card4),
              ],
            ),
          ),
        ],
      );
    }

    // Desktop
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: card1),
          const SizedBox(width: 12),
          Expanded(child: card2),
          const SizedBox(width: 12),
          Expanded(child: card3),
          const SizedBox(width: 12),
          Expanded(child: card4),
        ],
      ),
    );
  }
}

// =====================================================
// TOOLBAR
// =====================================================

class _Toolbar
    extends StatelessWidget {
  final TextEditingController
      controller;

  final String status;

  final ValueChanged<String>
      onSearch;

  final ValueChanged<String?>
      onStatus;

  final VoidCallback
      onExport;

  final VoidCallback onAdd;

  const _Toolbar({
    required this.controller,
    required this.status,
    required this.onSearch,
    required this.onStatus,
    required this.onExport,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    final isDark =
        Theme.of(context)
                .brightness ==
            Brightness.dark;

    

    final searchField = SizedBox(
      width: isMobile ? double.infinity : 280,
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: 'Search records',
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          filled: true,
          fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
        ),
      ),
    );

    final statusDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: DropdownButton<String>(
        value: status,
        underline: SizedBox(),
        dropdownColor: isDark ? AppColors.darkSurfaceAlt : Colors.white,
        style: AppTextStyles.bodySm.copyWith(
          color: isDark ? AppColors.darkText : AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        items: ['All Status', 'Active', 'Inactive']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onStatus,
      ),
    );

    final addButton = ElevatedButton.icon(
      onPressed: onAdd,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Add Department',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: statusDropdown),
            ],
          ),
          SizedBox(height: 12),
          addButton,
        ],
      );
    }

    return Row(
      children: [
        searchField,
        SizedBox(width: 12),
        statusDropdown,
        const Spacer(),
        addButton,
      ],
    );
  }
}

// =====================================================
// CATEGORY TABS
// =====================================================

class _CategoryTabs
    extends StatelessWidget {
  final List<String> tabs;

  final String active;

  final int totalCount;

  final ValueChanged<String>
      onSelect;

  const _CategoryTabs({
    required this.tabs,
    required this.active,
    required this.totalCount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    final isDark =
        Theme.of(context)
                .brightness ==
            Brightness.dark;

    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,

      child: Row(
        children:
            tabs
                .map(
                  (
                    t,
                  ) => Padding(
                    padding:
                        const EdgeInsets.only(
                      right: 8,
                    ),

                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(
                        AppConstants
                            .radiusFull,
                      ),

                      onTap:
                          () =>
                              onSelect(
                                t,
                              ),

                      child:
                          AnimatedContainer(
                        duration:
                            const Duration(
                          milliseconds:
                               180,
                        ),

                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              active ==
                                      t
                                  ? AppColors
                                      .primary
                                  : (isDark
                                      ? AppColors
                                          .darkSurface
                                      : AppColors
                                          .surface),

                          borderRadius:
                              BorderRadius.circular(
                            8,
                          ),

                          border:
                              Border.all(
                            color:
                                active ==
                                        t
                                    ? AppColors
                                        .primary
                                    : (isDark
                                        ? AppColors
                                            .darkBorder
                                        : AppColors
                                            .border),
                          ),
                        ),

                        child: Row(
                          mainAxisSize:
                              MainAxisSize
                                  .min,

                          children: [
                            Text(
                              t,

                              style:
                                  TextStyle(
                                fontSize:
                                    13,

                                fontWeight:
                                    active ==
                                            t
                                        ? FontWeight
                                            .w700
                                        : FontWeight
                                            .w600,

                                color:
                                    active ==
                                            t
                                        ? Colors
                                            .white
                                        : (isDark
                                            ? AppColors
                                                .darkText
                                            : AppColors
                                                .text),
                              ),
                            ),

                            if (t ==
                                'All') ...[
                              SizedBox(
                                width: 6,
                              ),

                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal:
                                      6,
                                  vertical:
                                      2,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color:
                                      active ==
                                              t
                                          ? Colors
                                              .white
                                              .withValues(
                                                alpha: 0.2,
                                              )
                                          : (isDark
                                              ? AppColors
                                                  .darkBorder
                                              : AppColors
                                                  .bg),

                                  borderRadius:
                                      BorderRadius.circular(
                                    10,
                                  ),
                                ),

                                child: Text(
                                  '$totalCount',

                                  style:
                                      TextStyle(
                                    fontSize:
                                        11,

                                    fontWeight:
                                        FontWeight
                                            .w700,

                                    color:
                                        active ==
                                                t
                                            ? Colors
                                                .white
                                            : (isDark
                                                ? AppColors
                                                    .darkText
                                                : AppColors
                                                    .text),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

// =====================================================
// TABLE
// =====================================================

class _DepartmentTable
    extends StatelessWidget {
  final List<DepartmentModel>
      depts;

  final bool isDark;

  final void Function(
    DepartmentModel,
  )
  onEdit;

  const _DepartmentTable({
    required this.depts,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    final bg =
        isDark
            ? AppColors.darkSurface
            : AppColors.surface;

    final border =
        isDark
            ? AppColors.darkBorder
            : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: bg,

        borderRadius:
            BorderRadius.circular(
          AppConstants.radiusMd,
        ),

        border: Border.all(
          color: border,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: isDark ? 0.16 : 0.04,
            ),

            blurRadius: 18,

            offset: const Offset(
              0,
              8,
            ),
          ),
        ],
      ),

      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1100,
          child: Column(
            children: [
              _TableHeader(border: border),
              ...depts.map(
                (d) => _DepartmentRow(
                  dept: d,
                  border: border,
                  onEdit: () => onEdit(d),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final Color border;

  const _TableHeader({
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    final cols = [
      'DEPARTMENT',
      'CODE',
      'CATEGORY',
      'PROGRAMS',
      'STUDENTS',
      'STATUS',
      'ACTIONS',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: border,
          ),
        ),
      ),
      child: Row(
        children: cols.asMap().entries.map((e) {
          return Expanded(
            flex: e.key == 0 ? 3 : e.key == 6 ? 2 : 1,
            child: Text(
              e.value,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DepartmentRow extends StatefulWidget {
  final DepartmentModel dept;
  final Color border;
  final VoidCallback onEdit;

  const _DepartmentRow({
    required this.dept,
    required this.border,
    required this.onEdit,
  });

  @override
  State<_DepartmentRow> createState() => _DepartmentRowState();
}

class _DepartmentRowState extends State<_DepartmentRow> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = [
      AppColors.primary,
      AppColors.accent,
      AppColors.purple,
      AppColors.warning,
      AppColors.pink,
    ][widget.dept.name.hashCode % 5];

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        color: hovered
            ? (isDark ? AppColors.darkSurfaceHover : AppColors.surfaceHover)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            // DEPARTMENT
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.dept.name.substring(0, 2).toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.dept.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkText : AppColors.text,
                          ),
                        ),
                        Text(
                          DepartmentCategory.label(
                            widget.dept.category,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSm.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // CODE
            Expanded(
              child: Text(
                widget.dept.code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // CATEGORY
            Expanded(
              child: Text(DepartmentCategory.label(widget.dept.category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // PROGRAMS
            Expanded(
              child: Text(
                '0',
                style: AppTextStyles.bodySm.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // STUDENTS
            Expanded(
              child: Text(
                '0',
                style: AppTextStyles.bodySm.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // STATUS
            Expanded(
              child: BadgeChip.status(
                widget.dept.isActive ? 'Active' : 'Inactive',
              ),
            ),

            // ACTIONS
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  _ActionButton(icon: Icons.visibility_outlined, onTap: () {}),
                  SizedBox(width: 8),
                  _ActionButton(icon: Icons.edit_outlined, onTap: widget.onEdit),
                  SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    onTap: () {},
                    color: AppColors.danger,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// MOBILE LIST
// =====================================================

class _MobileList extends StatelessWidget {
  final List<DepartmentModel> depts;
  final void Function(DepartmentModel) onEdit;

  const _MobileList({
    required this.depts,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: depts.length,
      itemBuilder: (ctx, i) {
        final d = depts[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _MobileCard(
            dept: d,
            onEdit: () => onEdit(d),
            onDelete: () {},
          ),
        );
      },
    );
  }
}

class _MobileCard extends StatelessWidget {
  final DepartmentModel dept;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MobileCard({
    required this.dept,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Row(
        children: [
          // Left: dept info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dept.name,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(dept.code,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // Status badge
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: BadgeChip.status(dept.isActive ? 'Active' : 'Inactive'),
          ),

          // Actions: edit / delete
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                onPressed: onDelete,
                color: AppColors.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =====================================================
// EMPTY STATE
// =====================================================

class _EmptyState
    extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    return Container(
      padding:
          const EdgeInsets.all(
        40,
      ),

      alignment:
          Alignment.center,

      child: Column(
        children: [
          Icon(
            Icons
                .folder_off_outlined,

            size: 54,

            color:
                AppColors.textMuted,
          ),

          SizedBox(
            height: 14,
          ),

          Text(
            'No departments found',

            style:
                AppTextStyles.h3,
          ),

          SizedBox(
            height: 8,
          ),

          Text(
            'Try changing filters or search query.',

            style:
                AppTextStyles.body
                    .copyWith(
                      color:
                          AppColors.textMuted,
                    ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// ACTION BUTTON
// =====================================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: Icon(icon, size: 16, color: color ?? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
      ),
    );
  }
}
