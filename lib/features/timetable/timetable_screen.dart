import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/utils/modal_helpers.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/features/admin/programs/providers/program_provider.dart';
import 'package:cims/features/admin/subjects/providers/subject_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/admin/staff/providers/staff_provider.dart';
import 'package:cims/features/timetable/providers/timetable_provider.dart';
import 'package:cims/features/timetable/services/timetable_service.dart' as api;
import 'package:cims/features/timetable/add_slot_modal.dart';
import 'package:dio/dio.dart';
import 'package:cims/core/network/dio_error_message.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  final void Function(String route) onNavigate;

  const TimetableScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<TimetableScreen> createState() =>
      _TimetableScreenState();
}

class _TimetableScreenState
    extends ConsumerState<TimetableScreen> {
  late final PageController _dayPageController;

  int? selectedProgramId;
  int? selectedStageInt;
  String selectedDay = 'Monday';
  bool _isPrinting = false;

  final List<String> timeSlots = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '01:00',
    '02:00',
    '03:00',
    '04:00',
    '05:00',
  ];

  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  List<api.TimetableSlot> slots = [];

  @override
  void initState() {
    super.initState();
    final i = days.indexOf(selectedDay);
    _dayPageController = PageController(
      initialPage: i < 0 ? 0 : i,
    );
  }

  @override
  void dispose() {
    _dayPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;
    final isPhone = Responsive.isMobile(context);

    final isStudent = AppSession.currentRole == 'student';
    final isTeacher = AppSession.currentRole == 'teacher';
    final sessionAsync = ref.watch(currentAcademicSessionProvider);
    final subjectsAsync = ref.watch(subjectsListProvider);

    int? activeSessionId;
    int? activeStage;
    int? filterProgramId;
    int? activeStaffId;

    if (isStudent) {
      final studentAsync = ref.watch(currentStudentProvider);
      final student = studentAsync.whenOrNull(data: (d) => d);
      if (student != null) {
        activeSessionId = sessionAsync.value?.id;
        activeStage = student.currentStage;
        filterProgramId = student.program?.id;
      }
    } else if (isTeacher) {
      final staffAsync = ref.watch(currentStaffProvider);
      final staff = staffAsync.whenOrNull(data: (d) => d);
      activeSessionId = sessionAsync.value?.id;
      if (staff != null) {
        activeStaffId = staff.id;
      }
      activeStage = selectedStageInt;
      filterProgramId = selectedProgramId;
    } else {
      activeSessionId = sessionAsync.whenOrNull(data: (d) => d)?.id;
      activeStage = selectedStageInt;
      filterProgramId = selectedProgramId;
    }

    if (isTeacher && selectedProgramId == null) {
      if (activeSessionId != null && activeStaffId != null) {
        final slotsAsync = ref.watch(timetableSlotsListProvider((
          sessionId: activeSessionId,
          stage: null,
          staffId: activeStaffId,
        )));
        slots = slotsAsync.value ?? [];
      }
    } else {
      if (activeSessionId != null && activeStage != null) {
        final timetableAsync = ref.watch(timetableWeeklyProvider((sessionId: activeSessionId, stage: activeStage)));
        final allSlots = timetableAsync.whenOrNull(data: (d) => d)?.days.expand((d) => d.slots).toList() ?? [];

        final subjects = subjectsAsync.value ?? [];
        if (filterProgramId != null && subjects.isNotEmpty) {
          slots = allSlots.where((slot) {
            final matches = subjects.where((s) => s.id == slot.subjectId);
            final sub = matches.isNotEmpty ? matches.first : null;
            return sub != null && sub.program?.id == filterProgramId;
          }).toList();
        } else {
          slots = allSlots;
        }
      }
    }

    return AppScaffold(
      title: 'Timetable',
      subtitle: 'Academics',
      currentRoute: '/timetable',
      role: AppSession.currentRole,
      onNavigate: widget.onNavigate,
      body: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildControls(isPhone),
          SizedBox(height: 20),
          if (isPhone)
            _buildPhoneAgenda(isDark)
          else
            _buildDesktopGrid(isDark),
        ],
      ),
    );
  }

  Widget _buildControls(bool isPhone) {
    final isStudent = AppSession.currentRole == 'student';
    final isTeacher = AppSession.currentRole == 'teacher';
    final programsAsync = ref.watch(programsProvider);
    final sessionAsync = ref.watch(currentAcademicSessionProvider);
    final activeSessionId = sessionAsync.value?.id;

    final filters = isStudent
        ? <Widget>[]
        : [
            programsAsync.when(
              data: (programs) {
                if (programs.isEmpty) return const SizedBox.shrink();

                if (!isTeacher) {
                  if (selectedProgramId == null || !programs.any((p) => p.id == selectedProgramId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => selectedProgramId = programs.first.id);
                    });
                    return const SizedBox.shrink();
                  }
                } else {
                  if (selectedProgramId != null && !programs.any((p) => p.id == selectedProgramId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => selectedProgramId = null);
                    });
                    return const SizedBox.shrink();
                  }
                }

                final List<String> dropdownItems = [];
                if (isTeacher) {
                  dropdownItems.add('My Timetable');
                }
                dropdownItems.addAll(programs.map((p) => p.code));

                final String currentValue = (isTeacher && selectedProgramId == null)
                    ? 'My Timetable'
                    : programs.firstWhere((p) => p.id == selectedProgramId).code;

                return _dropdown(
                  value: currentValue,
                  items: dropdownItems,
                  onChanged: (v) {
                    if (isTeacher && v == 'My Timetable') {
                      setState(() {
                        selectedProgramId = null;
                        selectedStageInt = null;
                      });
                    } else {
                      final p = programs.firstWhere((p) => p.code == v);
                      setState(() {
                        selectedProgramId = p.id;
                        selectedStageInt = null;
                      });
                    }
                  },
                );
              },
              loading: () => Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            if (selectedProgramId != null)
              ref.watch(programStagesProvider(selectedProgramId!)).when(
                data: (stages) {
                  if (stages.isEmpty) return const SizedBox.shrink();

                  if (selectedStageInt == null || !stages.any((s) => s.stage == selectedStageInt)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => selectedStageInt = stages.first.stage);
                    });
                    return const SizedBox.shrink();
                  }

                  return _dropdown(
                    value: stages.firstWhere((s) => s.stage == selectedStageInt).label,
                    items: stages.map((s) => s.label).toList(),
                    onChanged: (v) {
                      final s = stages.firstWhere((s) => s.label == v);
                      setState(() => selectedStageInt = s.stage);
                    },
                  );
                },
                loading: () => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
          ];

    final badges = [
      BadgeChip(label: 'Theory', tone: BadgeTone.primary),
      BadgeChip(label: 'Lab', tone: BadgeTone.success),
      BadgeChip(label: 'Both', tone: BadgeTone.accent),
      BadgeChip(label: 'Elective', tone: BadgeTone.purple),
    ];

    if (isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (filters.isNotEmpty) ...filters.expand((widget) => [
                widget,
                SizedBox(height: 12),
              ]),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: badges,
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = days[index];
                final active = selectedDay == day;

                return ChoiceChip(
                  label: Text(_shortDay(day)),
                  selected: active,
                  onSelected: (_) {
                    final idx = days.indexOf(day);
                    setState(() => selectedDay = day);
                    _dayPageController.animateToPage(
                      idx,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isPrinting ? null : _printTimetable,
                  icon: _isPrinting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : const Icon(Icons.print_rounded),
                  label: const Text('Print'),
                ),
              ),
              if (!isStudent && !isTeacher && selectedProgramId != null && selectedStageInt != null && activeSessionId != null) ...[
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showResponsiveModal(
                        context: context,
                        barrierColor: Colors.black54,
                        child: AddSlotModal(
                          programId: selectedProgramId!,
                          stage: selectedStageInt!,
                          sessionId: activeSessionId,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Slot'),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Left Group: Filters & Badges
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...filters,
                ...badges,
              ],
            ),
            // Right Group: Action Buttons
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _isPrinting ? null : _printTimetable,
                  icon: _isPrinting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : const Icon(Icons.print_rounded),
                  label: const Text('Print'),
                ),
                if (!isStudent && !isTeacher && selectedProgramId != null && selectedStageInt != null && activeSessionId != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      showResponsiveModal(
                        context: context,
                        barrierColor: Colors.black54,
                        child: AddSlotModal(
                          programId: selectedProgramId!,
                          stage: selectedStageInt!,
                          sessionId: activeSessionId,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Slot'),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _withSpacing(List<Widget> widgets) {
    return widgets
        .expand((widget) => [widget, SizedBox(width: 8)])
        .toList()
      ..removeLast();
  }

  Widget _buildPhoneAgenda(bool isDark) {
    final screenH = MediaQuery.sizeOf(context).height;
    final agendaHeight = (screenH * 0.52).clamp(340.0, 580.0);

    final todaySlots = slots
        .where((s) => s.dayOfWeek == selectedDay)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return SizedBox(
      height: agendaHeight,
      child: Container(
        decoration: BoxDecoration(
          color:
              isDark
                  ? AppColors.darkSurface
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isDark
                    ? AppColors.darkBorder
                    : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedDay,
                          style: AppTextStyles.h3,
                        ),
                        Text(
                          '${todaySlots.length} classes scheduled',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              height: 1,
            ),
            Expanded(
              child: PageView.builder(
                controller: _dayPageController,
                itemCount: days.length,
                onPageChanged: (i) {
                  setState(() => selectedDay = days[i]);
                },
                itemBuilder: (context, pageIndex) {
                  final day = days[pageIndex];
                  final filtered = slots
                      .where((slot) => slot.dayOfWeek == day)
                      .toList()
                    ..sort((a, b) => a.startTime.compareTo(b.startTime));

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No classes scheduled for this day.',
                          style: AppTextStyles.body.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      for (var i = 0; i < filtered.length; i++)
                        _timelineSlotRow(
                          filtered[i],
                          i == filtered.length - 1,
                          isDark,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineSlotRow(
    api.TimetableSlot slot,
    bool isLast,
    bool isDark,
  ) {
    final lineColor = isDark
        ? AppColors.darkBorder
        : AppColors.border;

    Color color;
    if (slot.classType == 'THEORY') {
      color = AppColors.primary;
    } else if (slot.classType == 'LAB') {
      color = AppColors.success;
    } else if (slot.classType == 'BOTH') {
      color = AppColors.accent;
    } else {
      color = AppColors.purple;
    }

    final isAdmin = AppSession.currentRole == 'admin';

    return InkWell(
      onTap: isAdmin ? () => _confirmDeleteSlot(slot) : null,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 22,
              child: Column(
                children: [
                  SizedBox(height: 22),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.only(
                          top: 6,
                          left: 5,
                        ),
                        color: lineColor,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _agendaCard(slot)),
          ],
        ),
      ),
    );
  }

  String _formatTimeForDisplay(String timeStr) {
    if (timeStr.isEmpty) return '—';
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final displayMin = minute.toString().padLeft(2, '0');
      return '$displayHour:$displayMin $period';
    } catch (_) {
      return timeStr;
    }
  }

  String _shortDay(String day) {
    const map = {
      'Monday': 'Mon',
      'Tuesday': 'Tue',
      'Wednesday': 'Wed',
      'Thursday': 'Thu',
      'Friday': 'Fri',
      'Saturday': 'Sat',
      'Sunday': 'Sun',
    };
    return map[day] ?? day;
  }

  Widget _agendaCard(api.TimetableSlot slot) {
    Color color;
    if (slot.classType == 'THEORY') {
      color = AppColors.primary;
    } else if (slot.classType == 'LAB') {
      color = AppColors.success;
    } else if (slot.classType == 'BOTH') {
      color = AppColors.accent;
    } else {
      color = AppColors.purple;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: color,
            width: 4,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 75,
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatTimeForDisplay(slot.startTime),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: isDark ? AppColors.darkText : AppColors.text,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h3.copyWith(
                    color: color,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '${_formatTimeForDisplay(slot.startTime)} - ${_formatTimeForDisplay(slot.endTime)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  AppSession.currentRole == 'teacher'
                      ? 'Stage ${slot.stage} · ${slot.room ?? 'N/A'}'
                      : '${slot.staffName} · ${slot.room ?? 'N/A'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkSurface
                : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark
                  ? AppColors.darkBorder
                  : AppColors.border,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1200,
            child: Column(
              children: [
                Row(
                  children: [
                    _timeHeader(),
                    ...days.map((d) => _dayHeader(d)),
                  ],
                ),
                ...timeSlots.map((time) => _timeRow(time, slots)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 90,
      height: 90,
      padding: const EdgeInsets.all(12),
      alignment: Alignment.topLeft,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: Text(
        'TIME',
        style: AppTextStyles.labelSm.copyWith(
          fontSize: 13,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _dayHeader(String day) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        height: 90,
        padding: const EdgeInsets.all(14),
        alignment: Alignment.topLeft,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
          border: Border(
            right: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
        ),
        child: Text(day.toUpperCase(),
          style: AppTextStyles.labelSm.copyWith(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _timeRow(String time, List<api.TimetableSlot> slots) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 105,
      child: Row(
        children: [
          Container(
            width: 90,
            padding: const EdgeInsets.all(12),
            alignment: Alignment.topLeft,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
                right: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
            ),
            child: Text(
              time,
              style: AppTextStyles.bodySm.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.text,
              ),
            ),
          ),
          ...days.map((day) => _buildCell(day, time, slots)),
        ],
      ),
    );
  }

  Widget _buildCell(
    String day,
    String time,
    List<api.TimetableSlot> slots,
  ) {
    api.TimetableSlot? slot;
    try {
      final rowHourRaw = int.tryParse(time.split(':')[0]) ?? 0;
      slot = slots.firstWhere(
        (s) {
          if (s.dayOfWeek != day) return false;
          final slotHour = int.tryParse(s.startTime.split(':')[0]) ?? 0;
          return slotHour == rowHourRaw || (rowHourRaw < 8 && slotHour == rowHourRaw + 12);
        },
      );
    } catch (_) {}

    final isAdmin = AppSession.currentRole == 'admin';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
            right: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
        ),
        child: slot == null
            ? const SizedBox()
            : InkWell(
                onTap: isAdmin ? () => _confirmDeleteSlot(slot!) : null,
                borderRadius: BorderRadius.circular(14),
                child: _slotCard(slot),
              ),
      ),
    );
  }

  Widget _slotCard(api.TimetableSlot slot) {
    Color color;
    if (slot.classType == 'THEORY') {
      color = AppColors.primary;
    } else if (slot.classType == 'LAB') {
      color = AppColors.success;
    } else if (slot.classType == 'BOTH') {
      color = AppColors.accent;
    } else {
      color = AppColors.purple;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: color,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            slot.subjectName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${_formatTimeForDisplay(slot.startTime)} - ${_formatTimeForDisplay(slot.endTime)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            AppSession.currentRole == 'teacher'
                ? 'Stage ${slot.stage} - ${slot.room ?? 'N/A'}'
                : '${slot.staffName} - ${slot.room ?? 'N/A'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkText : AppColors.text,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          onChanged: onChanged,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: TextStyle(
                      color: isDark ? AppColors.darkText : AppColors.text,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSlot(api.TimetableSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete timetable slot?'),
        content: Text('Remove "${slot.subjectName}" slot on ${slot.dayOfWeek} at ${slot.startTime}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final repo = ref.read(timetableRepositoryProvider);
      await repo.deleteSlot(slot.id);

      ref.invalidate(timetableWeeklyProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot deleted')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dioErrorMessage(
              e,
              fallback: 'Could not delete slot',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _printTimetable() async {
    final isStudent = AppSession.currentRole == 'student';
    final isTeacher = AppSession.currentRole == 'teacher';
    final sessionAsync = ref.read(currentAcademicSessionProvider);
    final activeSessionId = sessionAsync.value?.id;

    if (activeSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active academic session found.')),
      );
      return;
    }

    int? stage;
    int? staffId;
    int? programId;

    if (isStudent) {
      final studentAsync = ref.read(currentStudentProvider);
      final student = studentAsync.value;
      if (student != null) {
        stage = student.currentStage;
        programId = student.program?.id;
      }
    } else if (isTeacher) {
      if (selectedProgramId == null) {
        final staffAsync = ref.read(currentStaffProvider);
        final staff = staffAsync.value;
        if (staff != null) {
          staffId = staff.id;
        }
      } else {
        stage = selectedStageInt;
        programId = selectedProgramId;
      }
    } else {
      stage = selectedStageInt;
      programId = selectedProgramId;
    }

    // Validation: if printing a class timetable, stage must be selected
    if (staffId == null && stage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a program and stage first.')),
      );
      return;
    }

    setState(() => _isPrinting = true);

    try {
      final repo = ref.read(timetableRepositoryProvider);
      final pdfBytes = await repo.getTimetablePdf(
        sessionId: activeSessionId,
        stage: stage,
        programId: programId,
        staffId: staffId,
      );

      if (pdfBytes.isEmpty) {
        throw Exception('Empty PDF data received from server');
      }

      await Printing.layoutPdf(
        name: 'Timetable_${activeSessionId}_${stage ?? "teacher"}',
        onLayout: (format) => pdfBytes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print timetable: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }
}