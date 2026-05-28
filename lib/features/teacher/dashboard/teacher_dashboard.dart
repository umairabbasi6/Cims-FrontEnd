import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/features/teacher/dashboard/providers/teacher_dashboard_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:cims/features/teacher/attendance/providers/attendance_api_provider.dart';

class TeacherDashboard extends ConsumerWidget {
  final void Function(String route) onNavigate;

  const TeacherDashboard({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(teacherDashboardProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final padding = isMobile ? 16.0 : 24.0;

    return AppScaffold(
      title: 'Dashboard',
      subtitle: 'TEACHER PORTAL',
      currentRoute: '/dashboard',
      role: 'teacher',
      onNavigate: onNavigate,
      body: dashboardAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $e', textAlign: TextAlign.center),
        )),
        data: (data) {
          if (data == null) {
            return Center(child: Text('Dashboard not available. Ensure you are logged in with a teacher account.'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TeacherHero(data: data),
                const SizedBox(height: 20),
                const _TeacherCheckInWidget(),
                const SizedBox(height: 20),
                _TeacherStats(data: data),
                SizedBox(height: 20),
                if (isMobile)
                  Column(
                    children: [
                      _TodaySchedule(data: data),
                      SizedBox(height: 16),
                      _MySubjects(data: data),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _TodaySchedule(data: data)),
                      SizedBox(width: 20),
                      Expanded(flex: 2, child: _MySubjects(data: data)),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TeacherHero extends StatelessWidget {
  final TeacherDashboardData data;
  const _TeacherHero({required this.data});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFD946EF)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Academic Year 2024-25',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Welcome back, ${data.staffName} 👋',
            style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 26),
          ),
          SizedBox(height: 10),
          Text(
            'You have ${data.todayClasses} classes scheduled for today. Your average attendance across subjects is ${data.averageAttendance}%.',
            style: AppTextStyles.bodyLg.copyWith(color: Colors.white.withValues(alpha: 0.9), height: 1.6),
          ),
          SizedBox(height: 20),
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.fact_check_rounded),
                      label: const Text('Mark Attendance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6366F1),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.grading_rounded),
                      label: const Text('Enter Marks'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.fact_check_rounded),
                      label: const Text('Mark Attendance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.grading_rounded),
                      label: const Text('Enter Marks'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _TeacherStats extends StatelessWidget {
  final TeacherDashboardData data;
  const _TeacherStats({required this.data});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    if (isMobile) {
      return Column(
        children: [
          _StatItem(label: 'Subjects', value: '${data.totalSubjects}', icon: Icons.book_rounded, color: AppColors.primary),
          const SizedBox(height: 12),
          _StatItem(label: 'Today Classes', value: '${data.todayClasses}', icon: Icons.calendar_today_rounded, color: AppColors.accent),
          const SizedBox(height: 12),
          _StatItem(label: 'Avg Attendance', value: '${data.averageAttendance}%', icon: Icons.people_rounded, color: AppColors.success),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _StatItem(label: 'Subjects', value: '${data.totalSubjects}', icon: Icons.book_rounded, color: AppColors.primary)),
        const SizedBox(width: 16),
        Expanded(child: _StatItem(label: 'Today Classes', value: '${data.todayClasses}', icon: Icons.calendar_today_rounded, color: AppColors.accent)),
        const SizedBox(width: 16),
        Expanded(child: _StatItem(label: 'Avg Attendance', value: '${data.averageAttendance}%', icon: Icons.people_rounded, color: AppColors.success)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.h2),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _TodaySchedule extends StatelessWidget {
  final TeacherDashboardData data;
  const _TodaySchedule({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today\'s Schedule', style: AppTextStyles.h3),
          SizedBox(height: 16),
          if (data.todaySchedule.isEmpty)
            const Text('No classes today.', style: TextStyle(color: AppColors.textMuted)),
          ...data.todaySchedule.map((s) => _ScheduleCard(item: s)),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ScheduleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['time'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              Text(item['subject'], style: AppTextStyles.body),
            ],
          ),
          const Spacer(),
          BadgeChip(label: item['type'], tone: BadgeTone.primary),
        ],
      ),
    );
  }
}

class _MySubjects extends StatelessWidget {
  final TeacherDashboardData data;
  const _MySubjects({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Subjects', style: AppTextStyles.h3),
          SizedBox(height: 16),
          ...data.subjectAssignments.map((s) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.accentSoft,
              child: Text(s['code'].toString().substring(0,1), style: const TextStyle(color: AppColors.accent)),
            ),
            title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${s['role']} · ${s['section']}'),
          )),
        ],
      ),
    );
  }
}

class _TeacherCheckInWidget extends ConsumerStatefulWidget {
  const _TeacherCheckInWidget();

  @override
  ConsumerState<_TeacherCheckInWidget> createState() => _TeacherCheckInWidgetState();
}

class _TeacherCheckInWidgetState extends ConsumerState<_TeacherCheckInWidget> {
  bool _isCheckingIn = false;
  String _loadingText = '';

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied. Please enable them in system settings.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  Future<void> _performCheckIn() async {
    setState(() {
      _isCheckingIn = true;
      _loadingText = kIsWeb ? 'Verifying Web IP...' : 'Securing GPS Lock...';
    });

    try {
      double? lat;
      double? lon;

      if (!kIsWeb) {
        final position = await _determinePosition();
        if (position != null) {
          lat = position.latitude;
          lon = position.longitude;
        }
      }

      final repo = ref.read(attendanceRepositoryProvider);
      final result = await repo.teacherCheckIn(
        latitude: lat,
        longitude: lon,
      );

      final statusVal = result['status']?.toString() ?? 'PRESENT';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in successful! Marked as $statusVal.'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(teacherAttendanceStatusProvider);
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception:')) {
        errorMsg = errorMsg.split('Exception:').last.trim();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: $errorMsg'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(teacherAttendanceStatusProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: statusAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Failed to load check-in status: $err',
                style: AppTextStyles.body,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              onPressed: () => ref.invalidate(teacherAttendanceStatusProvider),
            )
          ],
        ),
        data: (statusMap) {
          final statusVal = statusMap['status']?.toString() ?? 'NOT_CHECKED_IN';
          final checkInStr = statusMap['check_in_time']?.toString();

          String formattedTime = '';
          if (checkInStr != null && checkInStr.isNotEmpty) {
            try {
              final parsed = DateTime.parse(checkInStr);
              formattedTime = DateFormat('hh:mm a').format(parsed.toLocal());
            } catch (_) {
              formattedTime = '';
            }
          }

          Widget statusIcon;
          String statusTitle = '';
          String statusSubtitle = '';
          Color accentColor;

          switch (statusVal) {
            case 'PRESENT':
              statusIcon = const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 36);
              statusTitle = 'Checked In';
              statusSubtitle = formattedTime.isNotEmpty ? 'Check-in recorded at $formattedTime.' : 'Check-in recorded successfully.';
              accentColor = AppColors.success;
              break;
            case 'LATE':
              statusIcon = const Icon(Icons.alarm_rounded, color: AppColors.warning, size: 36);
              statusTitle = 'Checked In (Late)';
              statusSubtitle = formattedTime.isNotEmpty ? 'Check-in recorded at $formattedTime.' : 'Check-in recorded (Late).';
              accentColor = AppColors.warning;
              break;
            case 'ON_LEAVE':
              statusIcon = const Icon(Icons.beach_access_rounded, color: Colors.grey, size: 36);
              statusTitle = 'On Leave Today';
              statusSubtitle = 'Enjoy your approved leave.';
              accentColor = Colors.grey;
              break;
            case 'ABSENT':
              statusIcon = const Icon(Icons.cancel_rounded, color: AppColors.danger, size: 36);
              statusTitle = 'Marked Absent';
              statusSubtitle = 'You were marked absent by system cutoff.';
              accentColor = AppColors.danger;
              break;
            default:
              statusIcon = const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 36);
              statusTitle = 'Daily Attendance';
              statusSubtitle = kIsWeb
                  ? 'Verify your network IP connection to check in.'
                  : 'Verify your GPS location coordinates to check in.';
              accentColor = AppColors.primary;
          }

          final showButton = statusVal == 'NOT_CHECKED_IN';

          return isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        statusIcon,
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(statusTitle, style: AppTextStyles.h3),
                              const SizedBox(height: 2),
                              Text(statusSubtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (showButton) ...[
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: _isCheckingIn ? null : _performCheckIn,
                        icon: _isCheckingIn
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.fingerprint_rounded, size: 20),
                        label: Text(_isCheckingIn ? _loadingText : 'Check-In Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                        ),
                        child: Center(
                          child: Text(
                            statusVal == 'ON_LEAVE' ? 'ON LEAVE' : 'CHECK-IN LOCK ACTIVE',
                            style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ]
                  ],
                )
              : Row(
                  children: [
                    statusIcon,
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(statusTitle, style: AppTextStyles.h3),
                          const SizedBox(height: 2),
                          Text(statusSubtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    if (showButton)
                      SizedBox(
                        width: 220,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isCheckingIn ? null : _performCheckIn,
                          icon: _isCheckingIn
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.fingerprint_rounded, size: 20),
                          label: Text(_isCheckingIn ? _loadingText : 'Check-In Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 220,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          statusVal == 'ON_LEAVE' ? 'ON LEAVE' : 'CHECK-IN ACTIVE',
                          style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      )
                  ],
                );
        },
      ),
    );
  }
}
