import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/features/admin/staff/add_staff_modal.dart';
import 'package:cims/core/utils/modal_helpers.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/features/admin/staff/models/staff_api_model.dart';
import 'package:cims/features/admin/staff/providers/staff_provider.dart';
import 'package:cims/features/teacher/attendance/providers/attendance_api_provider.dart';
import 'package:printing/printing.dart';
import 'package:cims/core/utils/csv_export_helper.dart' as csv_helper;

class StaffScreen extends ConsumerStatefulWidget {
  final void Function(String route) onNavigate;

  const StaffScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<StaffScreen> createState() =>
      _StaffScreenState();
}

class _StaffScreenState
    extends ConsumerState<StaffScreen> {
  String selectedTab = 'All';
  bool showAttendancePanel = false;
  DateTime selectedDate = DateTime.now();
  String searchQuery = '';
  String selectedStatusFilter = 'All Status';
  bool isExportingPdf = false;

  final List<String> tabs = [
    'All',
    'Medical',
    'Academic',
    'Nursing',
    'Admin',
  ];

  String? _apiCategoryForTab(String tab) {
    switch (tab) {
      case 'Medical':
        return 'MEDICAL';
      case 'Academic':
        return 'ACADEMIC';
      case 'Nursing':
        return 'NURSING';
      case 'Admin':
        return 'ADMIN';
      default:
        return null;
    }
  }

  static const List<Color> _avatarPalette = [
    AppColors.info,
    AppColors.primary,
    AppColors.purple,
    AppColors.warning,
    AppColors.success,
  ];

  Color _avatarColor(int index) =>
      _avatarPalette[index % _avatarPalette.length];

  List<Widget> _staffRows(
    AsyncValue<List<StaffApiModel>> async,
  ) {
    return async.when(
      data: (list) {
        final filteredList = list.where((staff) {
          final matchesSearch = searchQuery.isEmpty ||
              staff.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
              staff.staffIdCode.toLowerCase().contains(searchQuery.toLowerCase());
              
          final matchesStatus = selectedStatusFilter == 'All Status' ||
              (selectedStatusFilter == 'Active' && staff.isActive) ||
              (selectedStatusFilter == 'Inactive' && !staff.isActive);
              
          return matchesSearch && matchesStatus;
        }).toList();
        
        if (filteredList.isEmpty) {
          return [
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: Text(
                  'No matching staff members found.',
                  style: TextStyle(color: AppColors.darkTextMuted),
                ),
              ),
            ),
          ];
        }
        
        return filteredList
            .asMap()
            .entries
            .map(
              (e) => _staffRow(
                StaffMember.fromApi(
                  e.value,
                  _avatarColor(e.key),
                ),
                e.value,
              ),
            )
            .toList();
      },
      loading: () => [
        const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ],
      error:
          (err, _) => [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text('$err'),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref.invalidate(
                      allStaffListProvider(
                        _apiCategoryForTab(
                          selectedTab,
                        ),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ],
    );
  }

  void _viewStaff(StaffApiModel staff) {
    showResponsiveModal(
      context: context,
      barrierColor: Colors.black54,
      child: AddStaffModal(
        staff: staff,
        isViewOnly: true,
      ),
    );
  }

  Future<void> _editStaff(StaffApiModel staff) async {
    final updated = await showResponsiveModal<bool>(
      context: context,
      barrierColor: Colors.black54,
      child: AddStaffModal(
        staff: staff,
        isViewOnly: false,
      ),
    );
    if (updated == true) {
      ref.invalidate(staffListProvider(_apiCategoryForTab(selectedTab)));
      ref.invalidate(staffListProvider(null));
      ref.invalidate(allStaffListProvider(_apiCategoryForTab(selectedTab)));
      ref.invalidate(allStaffListProvider(null));
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(
      allStaffListProvider(
        _apiCategoryForTab(
          selectedTab,
        ),
      ),
    );

    final staffListAsync = ref.watch(allStaffListProvider(null));
    final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    final attendanceAsync = ref.watch(adminAttendanceRecordsProvider(dateStr));
    
    AsyncValue<List<Map<String, dynamic>>> combinedAsync = const AsyncValue.loading();
    if (staffListAsync.hasError) {
      combinedAsync = AsyncValue.error(staffListAsync.error!, staffListAsync.stackTrace!);
    } else if (attendanceAsync.hasError) {
      combinedAsync = AsyncValue.error(attendanceAsync.error!, attendanceAsync.stackTrace!);
    } else if (staffListAsync.hasValue && attendanceAsync.hasValue) {
      final staffList = staffListAsync.value!;
      final attendanceList = attendanceAsync.value!;
      
      final List<Map<String, dynamic>> combined = [];
      for (final record in attendanceList) {
        final teacherId = record['teacher_id'] as int;
        final staff = staffList.firstWhere(
          (s) => s.id == teacherId,
          orElse: () => StaffApiModel(
            id: teacherId,
            staffIdCode: record['staff_id_code'] ?? '',
            fullName: record['full_name'] ?? '',
            firstName: '',
            lastName: '',
            category: 'ACADEMIC',
            designation: 'Teacher',
            isActive: true,
            createdAt: DateTime.now(),
          ),
        );
        
        combined.add({
          'staff': staff,
          'record': record,
          'teacher_id': teacherId,
          'staff_id_code': record['staff_id_code'] ?? staff.staffIdCode,
          'full_name': record['full_name'] ?? staff.fullName,
          'department_name': record['department_name'] ?? staff.department?.name ?? '—',
          'designation': staff.designation,
          'category': staff.category,
          'status': record['status'] ?? 'NOT_CHECKED_IN',
          'check_in_time': record['check_in_time'],
          'check_out_time': record['check_out_time'],
          'admin_notes': record['admin_notes'],
        });
      }
      combinedAsync = AsyncValue.data(combined);
    }

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final search = _searchField();
    final status = _statusDropdown();
    final filters = TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.filter_alt_outlined),
      label: const Text('Filters'),
    );

    final dateDisplayStr = DateFormat('MMM dd, yyyy').format(selectedDate);
    final dateSelector = InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2025),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            selectedDate = picked;
          });
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.darkBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              dateDisplayStr,
              style: AppTextStyles.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );

    final attendanceToggleBtn = OutlinedButton.icon(
      onPressed: () {
        setState(() {
          showAttendancePanel = !showAttendancePanel;
          selectedStatusFilter = 'All Status';
          searchQuery = '';
        });
      },
      icon: Icon(showAttendancePanel ? Icons.people_alt_outlined : Icons.assignment_turned_in_outlined),
      label: Text(showAttendancePanel ? 'View Staff' : 'Check Attendance'),
    );

    final exportCsvBtn = OutlinedButton.icon(
      onPressed: isExportingPdf ? null : () {
        final staffList = staffListAsync.value ?? [];
        final attendanceList = attendanceAsync.value ?? [];
        
        final List<Map<String, dynamic>> recordsToExport = [];
        for (final record in attendanceList) {
          final teacherId = record['teacher_id'] as int;
          final staff = staffList.firstWhere(
            (s) => s.id == teacherId,
            orElse: () => StaffApiModel(
              id: teacherId,
              staffIdCode: record['staff_id_code'] ?? '',
              fullName: record['full_name'] ?? '',
              firstName: '',
              lastName: '',
              category: 'ACADEMIC',
              designation: 'Teacher',
              isActive: true,
              createdAt: DateTime.now(),
            ),
          );
          
          final status = record['status'] ?? 'NOT_CHECKED_IN';
          
          final categoryFilter = _apiCategoryForTab(selectedTab);
          final matchesCategory = categoryFilter == null || 
              staff.category.toUpperCase() == categoryFilter.toUpperCase();
          
          final matchesSearch = searchQuery.isEmpty ||
              staff.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
              staff.staffIdCode.toLowerCase().contains(searchQuery.toLowerCase());
              
          final matchesStatus = selectedStatusFilter == 'All Status' ||
              status.toUpperCase() == selectedStatusFilter.toUpperCase();
              
          if (matchesCategory && matchesSearch && matchesStatus) {
            recordsToExport.add({
              'full_name': staff.fullName,
              'department_name': record['department_name'] ?? staff.department?.name ?? '—',
              'designation': staff.designation,
              'status': status,
              'check_in_time': record['check_in_time'],
              'check_out_time': record['check_out_time'],
              'method': record['method'] ?? '—',
              'admin_notes': record['admin_notes'] ?? '',
            });
          }
        }
        _exportAttendanceCsv(recordsToExport);
      },
      icon: const Icon(Icons.insert_drive_file_outlined),
      label: const Text('Export CSV'),
    );

    final exportPdfBtn = OutlinedButton.icon(
      onPressed: isExportingPdf ? null : () async {
        setState(() {
          isExportingPdf = true;
        });
        try {
          final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
          final repo = ref.read(attendanceRepositoryProvider);
          final pdfBytes = await repo.getTeacherAttendancePdf(dateVal: dateStr);
          if (pdfBytes.isEmpty) {
            throw Exception('Empty PDF data received from server');
          }
          await Printing.layoutPdf(
            name: 'Teacher_Attendance_$dateStr',
            onLayout: (format) => pdfBytes,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to generate PDF: $e'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              isExportingPdf = false;
            });
          }
        }
      },
      icon: isExportingPdf
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
      label: const Text('Export PDF'),
    );

    final addBtn = ElevatedButton.icon(
      onPressed: () async {
        final created = await showResponsiveModal<bool>(
          context: context,
          barrierColor: Colors.black54,
          child: const AddStaffModal(),
        );
        if (created == true) {
          ref.invalidate(staffListProvider(_apiCategoryForTab(selectedTab)));
          ref.invalidate(staffListProvider(null));
          ref.invalidate(allStaffListProvider(_apiCategoryForTab(selectedTab)));
          ref.invalidate(allStaffListProvider(null));
        }
      },
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Staff'),
    );

    Widget toolbar;
    if (Responsive.isMobile(context)) {
      toolbar = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: 12),
          status,
          if (showAttendancePanel) ...[
            const SizedBox(height: 12),
            dateSelector,
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: filters,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (showAttendancePanel) ...[
                Expanded(child: exportCsvBtn),
                const SizedBox(width: 12),
                Expanded(child: exportPdfBtn),
                const SizedBox(width: 12),
              ],
              Expanded(child: attendanceToggleBtn),
            ],
          ),
        ],
      );
    } else if (Responsive.isTablet(context)) {
      toolbar = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              SizedBox(width: 160, child: status),
              if (showAttendancePanel) ...[
                const SizedBox(width: 12),
                dateSelector,
              ],
              const SizedBox(width: 12),
              filters,
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showAttendancePanel) ...[
                exportCsvBtn,
                const SizedBox(width: 12),
                exportPdfBtn,
                const SizedBox(width: 12),
              ],
              attendanceToggleBtn,
            ],
          ),
        ],
      );
    } else {
      toolbar = Row(
        children: [
          Expanded(child: search),
          const SizedBox(width: 12),
          SizedBox(width: 160, child: status),
          if (showAttendancePanel) ...[
            const SizedBox(width: 12),
            dateSelector,
          ],
          const SizedBox(width: 12),
          filters,
          const Spacer(),
          if (showAttendancePanel) ...[
            exportCsvBtn,
            const SizedBox(width: 12),
            exportPdfBtn,
            const SizedBox(width: 12),
          ],
          attendanceToggleBtn,
          if (!showAttendancePanel) ...[
            const SizedBox(width: 12),
            addBtn,
          ],
        ],
      );
    }

    return AppScaffold(
      title: 'Staff Management',
      subtitle: 'People',
      currentRoute: '/staff',
      role: AppSession.currentRole,
      onNavigate: widget.onNavigate,
      body: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // TABS
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                tabs.map((tab) {
              final active =
                  selectedTab == tab;

              return InkWell(
                borderRadius:
                    BorderRadius.circular(
                  999,
                ),
                onTap:
                    () => setState(
                      () =>
                          selectedTab =
                              tab,
                    ),
                child:
                    AnimatedContainer(
                  duration:
                      const Duration(
                    milliseconds: 180,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        active
                            ? AppColors
                                .primary
                            : Colors
                                .transparent,
                    borderRadius:
                        BorderRadius.circular(
                      999,
                    ),
                    border: Border.all(
                      color:
                          active
                              ? AppColors
                                  .primary
                              : AppColors
                                  .darkBorder,
                    ),
                  ),
                  child: Text(
                    tab,
                    style:
                        AppTextStyles
                            .bodySm
                            .copyWith(
                              fontWeight:
                                  FontWeight
                                      .w700,
                              color:
                                  active
                                      ? Colors
                                          .white
                                      : AppColors
                                          .darkText,
                            ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          // TABLE CARD
          Container(
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors
                          .darkSurface
                      : AppColors
                          .surface,
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              border: Border.all(
                color:
                    AppColors
                        .darkBorder,
              ),
            ),
            child: Column(
              children: [
                // TOOLBAR
                Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: toolbar,
                ),

                const Divider(
                  height: 1,
                  color:
                      AppColors
                          .darkBorder,
                ),

                // TABLE
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1200,
                    child: Column(
                      children: [
                        // TABLE HEADER
                        Container(
                          height: 52,
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 18,
                          ),
                          decoration: const BoxDecoration(
                            color:
                                AppColors
                                    .darkSurfaceAlt,
                          ),
                          child: Row(
                            children: showAttendancePanel
                                ? [
                                    _headerCell('NAME', 2.4),
                                    _headerCell('DEPARTMENT', 1.8),
                                    _headerCell('DESIGNATION', 2.0),
                                    _headerCell('TODAY\'S STATUS', 2.2),
                                    _headerCell('ACTIONS', 1.6),
                                  ]
                                : [
                                    _headerCell('NAME', 2),
                                    _headerCell('DEPARTMENT', 1.6),
                                    _headerCell('DESIGNATION', 1.8),
                                    _headerCell('PHONE', 2.2),
                                    _headerCell('STATUS', 1.2),
                                    _headerCell('ACTIONS', 1.8),
                                  ],
                          ),
                        ),
                        // ROWS
                        if (showAttendancePanel)
                          ..._buildAttendanceListWidget(
                            context,
                            combinedAsync,
                          )
                        else
                          ..._staffRows(
                            staffAsync,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStaff(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Are you sure you want to delete staff member "$name"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(staffRepositoryProvider);
      await repo.deleteStaff(id);
      
      ref.invalidate(staffListProvider(_apiCategoryForTab(selectedTab)));
      ref.invalidate(staffListProvider(null));
      ref.invalidate(allStaffListProvider(_apiCategoryForTab(selectedTab)));
      ref.invalidate(allStaffListProvider(null));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Staff member "$name" deleted successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete staff: $e')),
        );
      }
    }
  }

  Widget _staffRow(
    StaffMember s,
    StaffApiModel apiModel,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),

      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color:
                AppColors.darkBorder,
          ),
        ),
      ),

      child: Row(
        children: [
          // NAME
          Expanded(
            flex: 20,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: s.avatarColor,
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  alignment:
                      Alignment.center,
                  child: Text(
                    s.initials,
                    style:
                        AppTextStyles
                            .bodySm
                            .copyWith(
                              color:
                                  Colors
                                      .white,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTextStyles
                                .body
                                .copyWith(
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        s.role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTextStyles
                                .caption
                                .copyWith(
                                  color:
                                      AppColors
                                          .darkTextMuted,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // DEPARTMENT
          Expanded(
            flex: 16,
            child: BadgeChip(
              label: s.department,
            ),
          ),

          // DESIGNATION
          Expanded(
            flex: 18,
            child: Text(
              s.designation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.body,
            ),
          ),

          // PHONE
          Expanded(
            flex: 22,
            child: Text(
              s.phone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.body
                      .copyWith(
                color:
                    AppColors.primary,
              ),
            ),
          ),

          // STATUS
          Expanded(
            flex: 12,
            child:
                BadgeChip.status(
              s.status,
            ),
          ),

          // ACTIONS
          Expanded(
            flex: 18,
            child: Row(
              children: [
                _actionButton(
                  Icons.visibility_outlined,
                  () => _viewStaff(apiModel),
                ),
                const SizedBox(width: 6),
                _actionButton(
                  Icons.edit_outlined,
                  () => _editStaff(apiModel),
                ),
                const SizedBox(width: 6),
                _actionButton(
                  Icons.delete_outline_rounded,
                  () => _deleteStaff(s.id, s.name),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportAttendanceCsv(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance records to export.')),
      );
      return;
    }
    
    // Generate CSV string
    final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    final StringBuffer csv = StringBuffer();
    // Headers
    csv.writeln('Name,Department,Designation,Status,Check-In Time,Check-Out Time,Method,Notes');
    
    for (final item in records) {
      final name = item['full_name'] ?? '';
      final department = item['department_name'] ?? '';
      final designation = item['designation'] ?? '';
      final status = item['status'] ?? '';
      
      String checkInStr = '';
      if (item['check_in_time'] != null) {
        try {
          final parsed = DateTime.parse(item['check_in_time'].toString());
          checkInStr = DateFormat('hh:mm a').format(parsed);
        } catch (_) {}
      }
      
      String checkOutStr = '';
      if (item['check_out_time'] != null) {
        try {
          final parsed = DateTime.parse(item['check_out_time'].toString());
          checkOutStr = DateFormat('hh:mm a').format(parsed);
        } catch (_) {}
      }
      
      final method = item['method'] ?? '';
      final notes = (item['admin_notes'] ?? '').toString().replaceAll('"', '""');
      
      csv.writeln('"$name","$department","$designation","$status","$checkInStr","$checkOutStr","$method","$notes"');
    }
    
    final csvString = csv.toString();
    final fileName = 'Teacher_Attendance_$dateStr.csv';
    
    csv_helper.saveAndShareCsv(
      csvString: csvString,
      fileName: fileName,
    );
  }

  Widget _buildAttendanceBadge(String status) {
    Color foreground;
    Color background;
    bool isOutline = false;
    String label = status.replaceAll('_', ' ');

    switch (status.toUpperCase()) {
      case 'PRESENT':
        foreground = AppColors.success;
        background = AppColors.successSoft;
        break;
      case 'LATE':
        foreground = AppColors.warning;
        background = AppColors.warningSoft;
        break;
      case 'ABSENT':
        foreground = AppColors.danger;
        background = AppColors.dangerSoft;
        break;
      case 'ON_LEAVE':
        foreground = AppColors.darkTextMuted;
        background = AppColors.darkBorder;
        break;
      case 'EXCUSED':
        foreground = AppColors.purple;
        background = AppColors.purpleSoft;
        break;
      case 'NOT_CHECKED_IN':
      default:
        foreground = AppColors.darkTextMuted;
        background = Colors.transparent;
        isOutline = true;
        label = 'NOT CHECKED IN';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: isOutline ? Border.all(color: AppColors.darkBorder) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isOutline) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
              letterSpacing: 0.02,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showOverrideDialog(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final staff = item['staff'] as StaffApiModel;
    
    String currentStatus = item['status'] as String;
    if (currentStatus == 'NOT_CHECKED_IN' || currentStatus == 'ON_LEAVE') {
      currentStatus = 'PRESENT'; // default fallback for dropdown
    }
    
    String selectedStatus = currentStatus;
    final notesController = TextEditingController(text: item['admin_notes'] as String? ?? '');
    bool isSaving = false;
    
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurface
                  : AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: AppColors.darkBorder,
                  width: 1,
                ),
              ),
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Override Attendance',
                          style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: isSaving ? null : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Teacher: ${staff.fullName}',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current status for today is: ${item['status']}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.darkTextMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // STATUS DROPDOWN
                    Text(
                      'NEW STATUS',
                      style: AppTextStyles.labelSm,
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      dropdownColor: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkSurfaceAlt
                          : AppColors.surfaceAlt,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'PRESENT', child: Text('Present')),
                        DropdownMenuItem(value: 'LATE', child: Text('Late')),
                        DropdownMenuItem(value: 'ABSENT', child: Text('Absent')),
                        DropdownMenuItem(value: 'EXCUSED', child: Text('Excused')),
                      ],
                      onChanged: isSaving ? null : (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedStatus = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // NOTES
                    Text(
                      'ADMIN NOTES',
                      style: AppTextStyles.labelSm,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      enabled: !isSaving,
                      decoration: const InputDecoration(
                        hintText: 'Enter reason for override (e.g. medical emergency, late transit, etc.)',
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // ACTIONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            setDialogState(() {
                              isSaving = true;
                            });
                            
                            try {
                              final repo = ref.read(attendanceRepositoryProvider);
                              final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                              
                              await repo.overrideTeacherAttendance(
                                teacherId: staff.id,
                                dateVal: dateStr,
                                newStatus: selectedStatus,
                                notes: notesController.text.trim().isNotEmpty
                                    ? notesController.text.trim()
                                    : null,
                              );
                              
                              // Invalidate providers to force UI refresh
                              ref.invalidate(adminAttendanceRecordsProvider(dateStr));
                              ref.invalidate(teacherAttendanceStatusProvider);
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Attendance updated for ${staff.fullName}'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() {
                                isSaving = false;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to override attendance: $e'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            }
                          },
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Override'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _attendanceRow(
    Map<String, dynamic> item,
    int index,
  ) {
    final staff = item['staff'] as StaffApiModel;
    final status = item['status'] as String;
    
    final parts = staff.fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    String initials;
    if (parts.isEmpty) {
      initials = '?';
    } else if (parts.length == 1) {
      final t = parts.first;
      initials = t.length >= 2 ? t.substring(0, 2).toUpperCase() : t.toUpperCase();
    } else {
      initials = (parts.first[0] + parts.last[0]).toUpperCase();
    }
    
    final avatarColor = _avatarColor(index);
    
    String checkInTimeStr = '—';
    if (item['check_in_time'] != null) {
      try {
        final parsed = DateTime.parse(item['check_in_time'].toString());
        checkInTimeStr = DateFormat('hh:mm a').format(parsed);
      } catch (_) {
        checkInTimeStr = item['check_in_time'].toString();
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.darkBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // NAME
          Expanded(
            flex: 24,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: AppTextStyles.bodySm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        staff.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        staff.staffIdCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.darkTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // DEPARTMENT
          Expanded(
            flex: 18,
            child: BadgeChip(
              label: item['department_name'] ?? '—',
            ),
          ),
          
          // DESIGNATION
          Expanded(
            flex: 20,
            child: Text(
              item['designation'] ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body,
            ),
          ),
          
          // TODAY'S STATUS
          Expanded(
            flex: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAttendanceBadge(status),
                if (status == 'PRESENT' || status == 'LATE') ...[
                  const SizedBox(height: 4),
                  Text(
                    'In: $checkInTimeStr',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.darkTextMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // ACTIONS
          Expanded(
            flex: 16,
            child: Row(
              children: [
                _actionButton(
                  Icons.edit_note_outlined,
                  () => _showOverrideDialog(context, item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _attendanceRows(
    List<Map<String, dynamic>> list,
  ) {
    return list.asMap().entries.map((e) {
      final index = e.key;
      final item = e.value;
      return _attendanceRow(item, index);
    }).toList();
  }

  List<Widget> _buildAttendanceListWidget(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> combinedAsync,
  ) {
    return combinedAsync.when(
      data: (list) {
        final filteredList = list.where((item) {
          final staff = item['staff'] as StaffApiModel;
          final status = item['status'] as String;
          
          final categoryFilter = _apiCategoryForTab(selectedTab);
          final matchesCategory = categoryFilter == null || 
              staff.category.toUpperCase() == categoryFilter.toUpperCase();
          
          final matchesSearch = searchQuery.isEmpty ||
              staff.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
              staff.staffIdCode.toLowerCase().contains(searchQuery.toLowerCase());
              
          final matchesStatus = selectedStatusFilter == 'All Status' ||
              status.toUpperCase() == selectedStatusFilter.toUpperCase();
              
          return matchesCategory && matchesSearch && matchesStatus;
        }).toList();
        
        if (filteredList.isEmpty) {
          return [
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: Text(
                  'No matching attendance records found.',
                  style: TextStyle(color: AppColors.darkTextMuted),
                ),
              ),
            ),
          ];
        }
        
        return _attendanceRows(filteredList);
      },
      loading: () => [
        const Padding(
          padding: EdgeInsets.all(48),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ],
      error: (err, stack) => [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Failed to load attendance records: $err'),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                  ref.invalidate(adminAttendanceRecordsProvider(dateStr));
                  ref.invalidate(allStaffListProvider(null));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: (val) {
        setState(() {
          searchQuery = val;
        });
      },
      decoration: InputDecoration(
        hintText: showAttendancePanel ? 'Search by name or code' : 'Search records',
        prefixIcon: const Icon(
          Icons.search_rounded,
        ),
      ),
    );
  }

  Widget _statusDropdown() {
    final items = showAttendancePanel
        ? const [
            DropdownMenuItem(value: 'All Status', child: Text('All Status', overflow: TextOverflow.ellipsis, maxLines: 1)),
            DropdownMenuItem(value: 'PRESENT', child: Text('Present', overflow: TextOverflow.ellipsis, maxLines: 1)),
            DropdownMenuItem(value: 'LATE', child: Text('Late', overflow: TextOverflow.ellipsis, maxLines: 1)),
            DropdownMenuItem(value: 'ABSENT', child: Text('Absent', overflow: TextOverflow.ellipsis, maxLines: 1)),
            DropdownMenuItem(value: 'ON_LEAVE', child: Text('On Leave', overflow: TextOverflow.ellipsis, maxLines: 1)),
            DropdownMenuItem(value: 'EXCUSED', child: Text('Excused', overflow: TextOverflow.ellipsis, maxLines: 1)),
            DropdownMenuItem(value: 'NOT_CHECKED_IN', child: Text('Not Checked In', overflow: TextOverflow.ellipsis, maxLines: 1)),
          ]
        : const [
            DropdownMenuItem(value: 'All Status', child: Text('All Status', overflow: TextOverflow.ellipsis, maxLines: 1)),
            DropdownMenuItem(value: 'Active', child: Text('Active', overflow: TextOverflow.ellipsis, maxLines: 1)),
            DropdownMenuItem(value: 'Inactive', child: Text('Inactive', overflow: TextOverflow.ellipsis, maxLines: 1)),
          ];

    return DropdownButtonFormField<String>(
      value: selectedStatusFilter,
      decoration: const InputDecoration(),
      isExpanded: true,
      items: items,
      onChanged: (val) {
        if (val != null) {
          setState(() {
            selectedStatusFilter = val;
          });
        }
      },
    );
  }

  Widget _headerCell(
    String text,
    double flex,
  ) {
    return Expanded(
      flex: (flex * 10).toInt(),

      child: Text(
        text,

        style:
            AppTextStyles.labelSm
                .copyWith(
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(
        10,
      ),

      onTap: onTap,

      child: Container(
        width: 34,
        height: 34,

        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(
            10,
          ),

          border: Border.all(
            color:
                AppColors.darkBorder,
          ),
        ),

        child: Icon(
          icon,
          size: 18,
          color:
              AppColors.darkTextMuted,
        ),
      ),
    );
  }
}

class StaffMember {
  final int id;
  final String initials;
  final String name;
  final String role;
  final String department;
  final String designation;
  final String email;
  final String phone;
  final String status;
  final Color avatarColor;

  StaffMember({
    required this.id,
    required this.initials,
    required this.name,
    required this.role,
    required this.department,
    required this.designation,
    required this.email,
    required this.phone,
    required this.status,
    required this.avatarColor,
  });

  factory StaffMember.fromApi(
    StaffApiModel s,
    Color avatarColor,
  ) {
    final parts =
        s.fullName
            .trim()
            .split(RegExp(r'\s+'))
            .where((e) => e.isNotEmpty)
            .toList();
    String initials;
    if (parts.isEmpty) {
      initials = '?';
    } else if (parts.length == 1) {
      final t = parts.first;
      initials =
          t.length >= 2
              ? t.substring(0, 2).toUpperCase()
              : t.toUpperCase();
    } else {
      initials =
          (parts.first[0] + parts.last[0])
              .toUpperCase();
    }

    final dept =
        s.department?.name.isNotEmpty == true
            ? s.department!.name
            : (s.department?.code ?? '—');

    return StaffMember(
      id: s.id,
      initials: initials,
      name: s.fullName,
      role: s.designation,
      department: dept,
      designation: s.designation,
      email: s.email ?? '—',
      phone: s.phone ?? '—',
      status: s.isActive ? 'Active' : 'Inactive',
      avatarColor: avatarColor,
    );
  }
}