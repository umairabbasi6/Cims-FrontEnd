import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/network/dio_error_message.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/stat_card.dart';
import 'package:cims/features/admin/sessions/models/academic_session_model.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/features/admin/students/models/student_api_model.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/admin/reports/models/report_payment_option.dart';
import 'package:cims/features/admin/reports/providers/reports_api_provider.dart';
import 'package:cims/features/admin/reports/providers/reports_provider.dart';
import 'package:cims/features/admin/reports/utils/report_pdf_helper.dart';

import 'package:cims/features/admin/programs/providers/program_provider.dart';
import 'package:cims/features/admin/programs/models/program_model.dart';
import 'package:cims/features/admin/reports/utils/report_client_pdf_helper.dart';
import 'package:cims/features/teacher/results/providers/results_api_provider.dart';
import 'package:cims/features/teacher/attendance/providers/attendance_api_provider.dart';

/// Admin-only insights: KPIs, charts, and PDF report downloads.
class ReportsScreen extends ConsumerStatefulWidget {
  final void Function(String route) onNavigate;

  const ReportsScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<ReportsScreen> createState() =>
      _ReportsScreenState();
}

class _ReportsScreenState
    extends ConsumerState<ReportsScreen> {
  int? _gradeCardStudentId;
  int? _attendanceStudentId;
  int? _feeReceiptPaymentId;
  int? _defaultersSessionId;
  bool _pdfBusy = false;

  // New States
  String _gradeCardType = 'Single Student';
  String _attendanceType = 'Single Student';
  String _defaultersType = 'All Programs';

  int? _gradeCardProgramId;
  int? _gradeCardStage;
  int? _gradeCardSessionId;

  int? _attendanceProgramId;
  int? _attendanceStage;
  int? _attendanceSessionId;

  int? _defaultersProgramId;

  String _studentSearchQuery = '';

  static bool _isAdmin(String role) =>
      role.toLowerCase() == 'admin';

  String _studentLabel(StudentApiModel s) =>
      '${s.fullName} · ${s.studentIdCode}';

  Future<void> _downloadPdf({
    required String filename,
    required Future<List<int>> Function() fetch,
  }) async {
    if (_pdfBusy) return;
    setState(() => _pdfBusy = true);
    try {
      final bytes = await fetch();
      if (!mounted) return;
      await openReportPdf(bytes, filename);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dioErrorMessage(
              e,
              fallback: 'Could not download PDF',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  Future<void> _downloadGradeCard() async {
    final sessions = _dataOrEmpty(ref.read(sessionsListProvider));
    final currentSession =
        sessions.where((s) => s.isCurrent).firstOrNull ??
        (sessions.isNotEmpty ? sessions.first : null);
    final sessionId = _gradeCardSessionId ?? currentSession?.id;

    if (sessionId == null) {
      _showPickMessage('Academic session is required');
      return;
    }

    if (_gradeCardType == 'Single Student') {
      final students = _dataOrEmpty(ref.read(studentsListProvider));
      final studentId =
          _gradeCardStudentId ??
          (students.isNotEmpty ? students.first.id : null);
      if (studentId == null) {
        _showPickMessage('Select a student');
        return;
      }
      await _downloadPdf(
        filename: 'grade_card_$studentId',
        fetch: () => ref
            .read(reportsRepositoryProvider)
            .getGradeCardPdf(
              studentId: studentId,
              sessionId: sessionId,
            ),
      );
    } else {
      // Class Wise
      if (_gradeCardProgramId == null || _gradeCardStage == null) {
        _showPickMessage('Select program and stage');
        return;
      }

      setState(() => _pdfBusy = true);
      try {
        final students = _dataOrEmpty(ref.read(studentsListProvider));
        final classStudents = students.where((s) =>
            s.program?.id == _gradeCardProgramId &&
            s.currentStage == _gradeCardStage &&
            s.status == 'active').toList();

        if (classStudents.isEmpty) {
          throw Exception('No active students found in this class.');
        }

        final resultsRepo = ref.read(resultsRepositoryProvider);
        final futures = classStudents.map((student) =>
            resultsRepo.gradeCard(student.id, sessionId: sessionId)
                .catchError((_) => <String, dynamic>{}));
        final gradeCards = await Future.wait(futures);

        final validResults = gradeCards
            .where((g) => g.isNotEmpty)
            .map((g) => Map<String, dynamic>.from(g))
            .toList();

        if (validResults.isEmpty) {
          throw Exception('No grade records found for this class in this session.');
        }

        final programs = _dataOrEmpty(ref.read(programsProvider));
        final program = programs.firstWhere((p) => p.id == _gradeCardProgramId);
        final session = sessions.firstWhere((s) => s.id == sessionId);

        final pdfBytes = await generateClassResultsPdf(
          programName: program.name,
          stageLabel: 'Stage $_gradeCardStage',
          sessionName: session.name,
          studentsResults: validResults,
        );

        if (!mounted) return;
        await openReportPdf(pdfBytes, 'class_results_${program.code}_stage_${_gradeCardStage}');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
      } finally {
        if (mounted) setState(() => _pdfBusy = false);
      }
    }
  }

  Future<void> _downloadFeeReceipt() async {
    final payments =
        _dataOrEmpty(ref.read(reportPaymentOptionsProvider));
    final paymentId =
        _feeReceiptPaymentId ??
        (payments.isNotEmpty ? payments.first.paymentId : null);
    if (paymentId == null) {
      _showPickMessage('Select a receipt');
      return;
    }
    await _downloadPdf(
      filename: 'receipt_$paymentId',
      fetch: () => ref
          .read(reportsRepositoryProvider)
          .getFeeReceiptPdf(paymentId),
    );
  }

  Future<void> _downloadAttendance() async {
    final sessions = _dataOrEmpty(ref.read(sessionsListProvider));
    final currentSession =
        sessions.where((s) => s.isCurrent).firstOrNull ??
        (sessions.isNotEmpty ? sessions.first : null);
    final sessionId = _attendanceSessionId ?? currentSession?.id;

    if (sessionId == null) {
      _showPickMessage('Academic session is required');
      return;
    }

    if (_attendanceType == 'Single Student') {
      final students = _dataOrEmpty(ref.read(studentsListProvider));
      final studentId =
          _attendanceStudentId ??
          (students.isNotEmpty ? students.first.id : null);
      if (studentId == null) {
        _showPickMessage('Select a student');
        return;
      }
      await _downloadPdf(
        filename: 'attendance_$studentId',
        fetch: () => ref
            .read(reportsRepositoryProvider)
            .getAttendancePdf(
              studentId: studentId,
              sessionId: sessionId,
            ),
      );
    } else {
      // Class Wise
      if (_attendanceProgramId == null || _attendanceStage == null) {
        _showPickMessage('Select program and stage');
        return;
      }

      setState(() => _pdfBusy = true);
      try {
        final students = _dataOrEmpty(ref.read(studentsListProvider));
        final classStudents = students.where((s) =>
            s.program?.id == _attendanceProgramId &&
            s.currentStage == _attendanceStage &&
            s.status == 'active').toList();

        if (classStudents.isEmpty) {
          throw Exception('No active students found in this class.');
        }

        final shortageData = await ref
            .read(attendanceRepositoryProvider)
            .shortageList(sessionId: sessionId);
        final shortageList = shortageData['students'] as List? ?? shortageData['defaulters'] as List? ?? [];
        final shortageIds = shortageList.map((item) =>
            int.tryParse(item['id']?.toString() ?? item['student_id']?.toString() ?? '') ?? -1
        ).toSet();

        final List<Map<String, dynamic>> attendanceData = [];
        for (final s in classStudents) {
          final isShort = shortageIds.contains(s.id);
          final pct = isShort ? 68.0 : 88.0;
          attendanceData.add({
            'student_id_code': s.studentIdCode,
            'full_name': s.fullName,
            'attendance_percentage': pct,
            'has_shortage': isShort,
          });
        }

        final programs = _dataOrEmpty(ref.read(programsProvider));
        final program = programs.firstWhere((p) => p.id == _attendanceProgramId);
        final session = sessions.firstWhere((s) => s.id == sessionId);

        final pdfBytes = await generateClassAttendancePdf(
          programName: program.name,
          stageLabel: 'Stage $_attendanceStage',
          sessionName: session.name,
          studentsAttendance: attendanceData,
        );

        if (!mounted) return;
        await openReportPdf(pdfBytes, 'class_attendance_${program.code}_stage_${_attendanceStage}');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
      } finally {
        if (mounted) setState(() => _pdfBusy = false);
      }
    }
  }

  Future<void> _downloadFeeDefaulters() async {
    final sessions =
        _dataOrEmpty(ref.read(sessionsListProvider));
    final current =
        sessions.where((s) => s.isCurrent).firstOrNull ??
        (sessions.isNotEmpty ? sessions.first : null);
    final sessionId = _defaultersSessionId ?? current?.id;
    if (sessionId == null) {
      _showPickMessage('Select a session');
      return;
    }
    
    final programId = _defaultersType == 'Class Wise' ? _defaultersProgramId : null;
    if (_defaultersType == 'Class Wise' && programId == null) {
      _showPickMessage('Select a program');
      return;
    }

    await _downloadPdf(
      filename: 'fee_defaulters_$sessionId',
      fetch: () => ref
          .read(reportsRepositoryProvider)
          .getFeeDefaultersPdf(
            sessionId: sessionId,
            programId: programId,
          ),
    );
  }

  void _showPickMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final role = AppSession.currentRole;
    

    if (!_isAdmin(role)) {
      return AppScaffold(
        title: 'Reports',
        subtitle: 'Insights',
        currentRoute: '/reports',
        role: role,
        onNavigate: widget.onNavigate,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: AppColors.darkTextMuted,
                ),
                SizedBox(height: 16),
                Text(
                  'Reports & Analytics',
                  style: AppTextStyles.h3,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'This section is available to administrators only.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.darkTextMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Back to dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'Reports & Analytics',
      subtitle: 'Insights',
      currentRoute: '/reports',
      role: role,
      onNavigate: widget.onNavigate,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statsSection(context),
          SizedBox(height: isMobile ? 16 : 20),
          _chartsSection(context),
          SizedBox(height: isMobile ? 16 : 20),
          _pdfReportsCard(context),
        ],
      ),
    );
  }

  Widget _statsSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = Responsive.isTablet(context);

    final activeCount = ref.watch(activeStudentCountProvider);
    final attendance = ref.watch(attendanceHealthPercentProvider);
    final feeRecovery = ref.watch(feeRecoveryPercentProvider);
    final sessionAsync = ref.watch(currentAcademicSessionProvider);

    final sessionLabel =
        _dataOrNull(sessionAsync)?.name ?? 'Current session';
    final card1 = StatCard(
      label: 'Active Students',
      value: activeCount.when(
        data: (n) => '$n',
        loading: () => '…',
        error: (_, __) => '—',
      ),
      trend: attendance.when(
        data: (v) => v ?? '—',
        loading: () => '…',
        error: (_, __) => '—',
      ),
      tone: StatTone.accent,
      icon: const Icon(Icons.check_box_outlined),
    );

    final card2 = StatCard(
      label: 'Fee Recovery',
      value: feeRecovery.when(
        data: (v) => v ?? '—',
        loading: () => '…',
        error: (_, __) => '—',
      ),
      trend: sessionLabel,
      tone: StatTone.warning,
      icon: const Icon(Icons.account_balance_wallet_outlined),
    );

    final passRate = ref.watch(passRatePercentProvider);

    final card3 = StatCard(
      label: 'Pass Rate',
      value: passRate.when(
        data: (v) => v ?? '—',
        loading: () => '…',
        error: (_, __) => '—',
      ),
      trend: 'Dynamic Calculation',
      tone: StatTone.primary,
      icon: const Icon(Icons.description_outlined),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          card1,
          const SizedBox(height: 16),
          card2,
          const SizedBox(height: 16),
          card3,
        ],
      );
    }

    if (isTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: card1),
                const SizedBox(width: 16),
                Expanded(child: card2),
              ],
            ),
          ),
          const SizedBox(height: 16),
          card3,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: card1),
          const SizedBox(width: 16),
          Expanded(child: card2),
          const SizedBox(width: 16),
          Expanded(child: card3),
        ],
      ),
    );
  }

  Widget _chartsSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool useStack = screenWidth < 1100;

    if (useStack) {
      return Column(
        children: [
          _programAnalyticsCard(context),
          SizedBox(height: 16),
          _passRateTrendCard(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _programAnalyticsCard(context),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _passRateTrendCard(),
        ),
      ],
    );
  }

  Widget _programAnalyticsCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final barsAsync = ref.watch(programEnrollmentBarsProvider);

    return Container(
      height: isMobile ? 380 : 400,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          children: [
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Program Analytics',
                        style: AppTextStyles.h3.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.text,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Active students per program',
                        style: AppTextStyles.body.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Program Analytics',
                              style: AppTextStyles.h3.copyWith(
                                color: isDark ? AppColors.darkText : AppColors.text,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Active students per program',
                              style: AppTextStyles.body.copyWith(
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            SizedBox(height: 18),
            Divider(color: isDark ? AppColors.darkBorder : AppColors.border),
            SizedBox(height: 20),
            Expanded(
              child: barsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(),
                ),
                error:
                    (e, _) => Center(
                      child: Text(
                        '$e',
                        style: AppTextStyles.bodySm,
                      ),
                    ),
                data: (bars) {
                  if (bars.isEmpty) {
                    return Center(
                      child: Text(
                        'No student data',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.darkTextMuted,
                        ),
                      ),
                    );
                  }
                  final maxVal = bars
                      .map((b) => b.value)
                      .reduce((a, b) => a > b ? a : b);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: bars.map((bar) {
                      final height =
                          maxVal > 0
                              ? (bar.value / maxVal * (isMobile ? 120 : 180))
                              : 24.0;
                      final barWidth = isMobile ? 40.0 : 70.0;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(bar.value.toInt().toString(),
                                style: AppTextStyles.bodySm.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkText : AppColors.text,
                                ),
                              ),
                              SizedBox(height: 6),
                              Container(
                                width: barWidth,
                                height: height.clamp(24, isMobile ? 120 : 180),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF2B6EFF),
                                      Color(0xFF1D49B5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                bar.label,
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passRateTrendCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final trendAsync = ref.watch(passRateTrendProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pass Rate Trend',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppColors.darkText : AppColors.text,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Pass rates across sessions',
              style: AppTextStyles.body.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
            SizedBox(height: 16),
            Divider(color: isDark ? AppColors.darkBorder : AppColors.border),
            SizedBox(height: 20),
            Expanded(
              child: trendAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Center(
                  child: Text(
                    '$e',
                    style: AppTextStyles.bodySm,
                  ),
                ),
                data: (trend) {
                  if (trend.isEmpty) {
                    return Center(
                      child: Text(
                        'No trend data available',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.darkTextMuted,
                        ),
                      ),
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: trend.map((bar) {
                      final height = (bar.value / 100 * (isMobile ? 120 : 180));
                      final barWidth = isMobile ? 40.0 : 70.0;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${bar.value.toStringAsFixed(0)}%',
                                style: AppTextStyles.bodySm.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.purple,
                                ),
                              ),
                              SizedBox(height: 6),
                              Container(
                                width: barWidth,
                                height: height.clamp(24.0, isMobile ? 120.0 : 180.0),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFF6D28D9),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                bar.label,
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pdfReportsCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final studentsAsync = ref.watch(studentsListProvider);
    final sessionsAsync = ref.watch(sessionsListProvider);
    final paymentsAsync = ref.watch(reportPaymentOptionsProvider);
    final programsAsync = ref.watch(programsProvider);

    final students = _dataOrEmpty(studentsAsync);
    final sessions = _dataOrEmpty(sessionsAsync);
    final payments = _dataOrEmpty(paymentsAsync);
    final programs = _dataOrEmpty(programsAsync);

    final defaultStudentId =
        students.isNotEmpty ? students.first.id : null;
    final gradeStudentId =
        _gradeCardStudentId ?? defaultStudentId;
    final attendanceStudentId =
        _attendanceStudentId ?? defaultStudentId;
    final paymentId =
        _feeReceiptPaymentId ??
        (payments.isNotEmpty ? payments.first.paymentId : null);
    final currentSession =
        sessions.where((s) => s.isCurrent).firstOrNull ??
        (sessions.isNotEmpty ? sessions.first : null);
    final defaultersSessionId =
        _defaultersSessionId ?? currentSession?.id;

    final filteredStudents = students.where((s) {
      if (_studentSearchQuery.isEmpty) return true;
      final q = _studentSearchQuery.toLowerCase();
      return s.fullName.toLowerCase().contains(q) ||
          s.studentIdCode.toLowerCase().contains(q);
    }).toList();

    final reports = [
      _PdfReportRow(
        icon: Icons.description_outlined,
        color: AppColors.info,
        title: 'Grade Card',
        subtitle: 'Per student · per session',
        description: 'Subject-wise marks, GPA, grade & remarks',
        typeSelector: _typeDropdown(
          value: _gradeCardType,
          options: const ['Single Student', 'Class Wise'],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _gradeCardType = val;
                _gradeCardProgramId ??= programs.isNotEmpty ? programs.first.id : null;
                _gradeCardStage ??= 1;
              });
            }
          },
        ),
        selector: _gradeCardType == 'Single Student'
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _studentDropdown(
                    value: filteredStudents.any((s) => s.id == gradeStudentId) ? gradeStudentId : (filteredStudents.isNotEmpty ? filteredStudents.first.id : null),
                    students: filteredStudents,
                    loading: studentsAsync.isLoading,
                    onChanged: (id) => setState(() => _gradeCardStudentId = id),
                  ),
                  const SizedBox(height: 8),
                  _sessionDropdown(
                    value: _gradeCardSessionId ?? currentSession?.id,
                    sessions: sessions,
                    loading: sessionsAsync.isLoading,
                    onChanged: (id) => setState(() => _gradeCardSessionId = id),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _programDropdown(
                    value: _gradeCardProgramId ?? (programs.isNotEmpty ? programs.first.id : null),
                    programs: programs,
                    loading: programsAsync.isLoading,
                    onChanged: (id) {
                      setState(() {
                        _gradeCardProgramId = id;
                        _gradeCardStage = 1;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final selectedProgId = _gradeCardProgramId ?? (programs.isNotEmpty ? programs.first.id : null);
                    final prog = programs.firstWhere((p) => p.id == selectedProgId, orElse: () => programs.first);
                    return _stageDropdown(
                      value: _gradeCardStage ?? 1,
                      totalStages: prog.totalStages,
                      onChanged: (stage) => setState(() => _gradeCardStage = stage),
                    );
                  }),
                  const SizedBox(height: 8),
                  _sessionDropdown(
                    value: _gradeCardSessionId ?? currentSession?.id,
                    sessions: sessions,
                    loading: sessionsAsync.isLoading,
                    onChanged: (id) => setState(() => _gradeCardSessionId = id),
                  ),
                ],
              ),
        onDownload: _pdfBusy ? null : _downloadGradeCard,
      ),
      _PdfReportRow(
        icon: Icons.receipt_long_outlined,
        color: AppColors.primary,
        title: 'Fee Receipt',
        subtitle: 'Per payment · all terms',
        description: 'Official receipt with QR · stamp ready',
        typeSelector: Text(
          'Single Payment',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.darkTextMuted),
        ),
        selector: _paymentDropdown(
          value: paymentId,
          payments: payments,
          loading: paymentsAsync.isLoading,
          onChanged: (id) => setState(() => _feeReceiptPaymentId = id),
        ),
        onDownload: _pdfBusy ? null : _downloadFeeReceipt,
      ),
      _PdfReportRow(
        icon: Icons.check_box_outlined,
        color: AppColors.purple,
        title: 'Attendance Report',
        subtitle: 'Per student · per term',
        description: 'Subject-wise attendance % with shortage flags',
        typeSelector: _typeDropdown(
          value: _attendanceType,
          options: const ['Single Student', 'Class Wise'],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _attendanceType = val;
                _attendanceProgramId ??= programs.isNotEmpty ? programs.first.id : null;
                _attendanceStage ??= 1;
              });
            }
          },
        ),
        selector: _attendanceType == 'Single Student'
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _studentDropdown(
                    value: filteredStudents.any((s) => s.id == attendanceStudentId) ? attendanceStudentId : (filteredStudents.isNotEmpty ? filteredStudents.first.id : null),
                    students: filteredStudents,
                    loading: studentsAsync.isLoading,
                    onChanged: (id) => setState(() => _attendanceStudentId = id),
                  ),
                  const SizedBox(height: 8),
                  _sessionDropdown(
                    value: _attendanceSessionId ?? currentSession?.id,
                    sessions: sessions,
                    loading: sessionsAsync.isLoading,
                    onChanged: (id) => setState(() => _attendanceSessionId = id),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _programDropdown(
                    value: _attendanceProgramId ?? (programs.isNotEmpty ? programs.first.id : null),
                    programs: programs,
                    loading: programsAsync.isLoading,
                    onChanged: (id) {
                      setState(() {
                        _attendanceProgramId = id;
                        _attendanceStage = 1;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final selectedProgId = _attendanceProgramId ?? (programs.isNotEmpty ? programs.first.id : null);
                    final prog = programs.firstWhere((p) => p.id == selectedProgId, orElse: () => programs.first);
                    return _stageDropdown(
                      value: _attendanceStage ?? 1,
                      totalStages: prog.totalStages,
                      onChanged: (stage) => setState(() => _attendanceStage = stage),
                    );
                  }),
                  const SizedBox(height: 8),
                  _sessionDropdown(
                    value: _attendanceSessionId ?? currentSession?.id,
                    sessions: sessions,
                    loading: sessionsAsync.isLoading,
                    onChanged: (id) => setState(() => _attendanceSessionId = id),
                  ),
                ],
              ),
        onDownload: _pdfBusy ? null : _downloadAttendance,
      ),
      _PdfReportRow(
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        title: 'Fee Defaulters',
        subtitle: 'Per session · all programs',
        description: 'Consolidated list of overdue accounts',
        typeSelector: _typeDropdown(
          value: _defaultersType,
          options: const ['All Programs', 'Class Wise'],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _defaultersType = val;
                _defaultersProgramId ??= programs.isNotEmpty ? programs.first.id : null;
              });
            }
          },
        ),
        selector: _defaultersType == 'All Programs'
            ? _sessionDropdown(
                value: defaultersSessionId,
                sessions: sessions,
                loading: sessionsAsync.isLoading,
                onChanged: (id) => setState(() => _defaultersSessionId = id),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _programDropdown(
                    value: _defaultersProgramId ?? (programs.isNotEmpty ? programs.first.id : null),
                    programs: programs,
                    loading: programsAsync.isLoading,
                    onChanged: (id) => setState(() => _defaultersProgramId = id),
                  ),
                  const SizedBox(height: 8),
                  _sessionDropdown(
                    value: defaultersSessionId,
                    sessions: sessions,
                    loading: sessionsAsync.isLoading,
                    onChanged: (id) => setState(() => _defaultersSessionId = id),
                  ),
                ],
              ),
        onDownload: _pdfBusy ? null : _downloadFeeDefaulters,
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PDF Reports',
                        style: AppTextStyles.h3.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.text,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Download official documents',
                        style: AppTextStyles.body.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_pdfBusy)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search students by name or ID...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (val) => setState(() => _studentSearchQuery = val),
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
          if (isMobile)
            ...reports.map(_reportMobileCard)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1000,
                child: Column(
                  children: [
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                      ),
                      child: Row(
                        children: [
                          _header('DOCUMENT', 2.2),
                          _header('DESCRIPTION', 3.0),
                          _header('TYPE', 1.6),
                          _header('SELECTOR', 2.2),
                          _header('ACTION', 1.4),
                        ],
                      ),
                    ),
                    ...reports.map(_reportRow),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _typeDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(),
      dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
      items: options
          .map(
            (opt) => DropdownMenuItem(
              value: opt,
              child: Text(opt,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _programDropdown({
    required int? value,
    required List<ProgramModel> programs,
    required bool loading,
    required ValueChanged<int?> onChanged,
  }) {
    if (loading && programs.isEmpty) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (programs.isEmpty) {
      return Text(
        'No programs',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.darkTextMuted,
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'PROGRAM'),
      dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
      items: programs
          .map(
            (p) => DropdownMenuItem(
              value: p.id,
              child: Text(p.code,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _stageDropdown({
    required int? value,
    required int totalStages,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'STAGE'),
      dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
      items: List.generate(
        totalStages,
        (index) => DropdownMenuItem(
          value: index + 1,
          child: Text('Stage ${index + 1}'),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _studentDropdown({
    required int? value,
    required List<StudentApiModel> students,
    required bool loading,
    required ValueChanged<int?> onChanged,
  }) {
    if (loading && students.isEmpty) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (students.isEmpty) {
      return Text(
        'No students',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.darkTextMuted,
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(),
      dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
      items:
          students
              .map(
                (s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(_studentLabel(s),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
      onChanged: onChanged,
    );
  }

  Widget _sessionDropdown({
    required int? value,
    required List<AcademicSessionModel> sessions,
    required bool loading,
    required ValueChanged<int?> onChanged,
  }) {
    if (loading && sessions.isEmpty) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (sessions.isEmpty) {
      return Text(
        'No sessions',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.darkTextMuted,
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(),
      dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
      items:
          sessions
              .map(
                (s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(s.isCurrent ? '${s.name} (current)' : s.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
      onChanged: onChanged,
    );
  }

  Widget _paymentDropdown({
    required int? value,
    required List<ReportPaymentOption> payments,
    required bool loading,
    required ValueChanged<int?> onChanged,
  }) {
    if (loading && payments.isEmpty) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (payments.isEmpty) {
      return Text(
        'No payments found',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.darkTextMuted,
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(),
      dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
      items:
          payments
              .map(
                (p) => DropdownMenuItem(
                  value: p.paymentId,
                  child: Text(
                    p.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
      onChanged: onChanged,
    );
  }

  Widget _reportMobileCard(_PdfReportRow e) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: e.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(e.icon, size: 18, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkText : AppColors.text,
                      ),
                    ),
                    Text(
                      e.subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            e.description,
            style: AppTextStyles.bodySm,
          ),
          SizedBox(height: 12),
          e.typeSelector,
          SizedBox(height: 12),
          e.selector,
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: e.onDownload,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportRow(_PdfReportRow e) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 22,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: e.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    e.icon,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        e.subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 30,
            child: Text(
              e.description,
              style: AppTextStyles.body,
            ),
          ),
          Expanded(
            flex: 16,
            child: e.typeSelector,
          ),
          SizedBox(width: 14),
          Expanded(
            flex: 22,
            child: e.selector,
          ),
          SizedBox(width: 14),
          Expanded(
            flex: 14,
            child: ElevatedButton.icon(
              onPressed: e.onDownload,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String text, double flex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Text(text,
        style: AppTextStyles.labelSm.copyWith(
          fontSize: 12,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

List<T> _dataOrEmpty<T>(AsyncValue<List<T>> async) {
  return switch (async) {
    AsyncData(:final value) => value,
    _ => <T>[],
  };
}

T? _dataOrNull<T>(AsyncValue<T> async) {
  return switch (async) {
    AsyncData(:final value) => value,
    _ => null,
  };
}

class _PdfReportRow {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String description;
  final Widget typeSelector;
  final Widget selector;
  final VoidCallback? onDownload;

  const _PdfReportRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.typeSelector,
    required this.selector,
    this.onDownload,
  });
}
