import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/network/dio_error_message.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/features/teacher/attendance/providers/attendance_api_provider.dart';
import 'package:cims/features/teacher/leaves/widgets/leave_request_dialog.dart';
import 'package:cims/features/teacher/leaves/widgets/leave_history_modal.dart';

class TeacherCheckInCard extends ConsumerStatefulWidget {
  const TeacherCheckInCard({super.key});

  @override
  ConsumerState<TeacherCheckInCard> createState() => _TeacherCheckInCardState();
}

class _TeacherCheckInCardState extends ConsumerState<TeacherCheckInCard> {
  bool _isCheckingIn = false;

  Future<void> _handleCheckIn() async {
    setState(() {
      _isCheckingIn = true;
    });

    double? lat;
    double? lng;

    try {
      // 1. Try to obtain device GPS coordinates
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 8),
            ),
          );
          lat = position.latitude;
          lng = position.longitude;
        }
      }
    } catch (_) {
      // Location retrieval failed or timed out — fallback to IP validation
    }

    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final res = await repo.teacherCheckIn(
        latitude: lat,
        longitude: lng,
      );

      final status = res['status'] as String? ?? 'PRESENT';
      final checkInTime = res['check_in_time'] != null
          ? DateFormat('hh:mm a').format(DateTime.parse(res['check_in_time'].toString()))
          : 'Now';

      ref.invalidate(teacherAttendanceStatusProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: status == 'LATE' ? AppColors.warning : AppColors.success,
            content: Row(
              children: [
                Icon(
                  status == 'LATE' ? Icons.access_time_rounded : Icons.check_circle_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    status == 'LATE'
                        ? 'Check-in recorded at $checkInTime (Marked Late)'
                        : 'Check-in recorded successfully at $checkInTime (Present)',
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } on DioException catch (e) {
      final errorMsg = extractDioErrorMessage(e);
      if (mounted) {
        _showErrorDialog('Check-In Failed', errorMsg);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Check-In Failed', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);
    final statusAsync = ref.watch(teacherAttendanceStatusProvider);

    final todayFormatted = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: statusAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Could not load today\'s attendance status.',
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(teacherAttendanceStatusProvider),
            ),
          ],
        ),
        data: (statusData) {
          final String rawStatus = (statusData['status'] as String? ?? 'NOT_CHECKED_IN').toUpperCase();
          final String? checkInStr = statusData['check_in_time']?.toString();
          String formattedCheckIn = '—';
          if (checkInStr != null) {
            final dt = DateTime.tryParse(checkInStr);
            if (dt != null) {
              formattedCheckIn = DateFormat('hh:mm a').format(dt);
            }
          }

          final bool isCheckedIn = rawStatus == 'PRESENT' || rawStatus == 'LATE';
          final bool isOnLeave = rawStatus == 'ON_LEAVE';
          final bool isAbsent = rawStatus == 'ABSENT';

          Color statusColor = AppColors.warning;
          String statusTitle = 'Daily Check-In Pending';
          String statusSubtitle = 'Please mark your attendance via Campus GPS or College Wi-Fi.';
          IconData statusIcon = Icons.location_on_outlined;

          if (rawStatus == 'PRESENT') {
            statusColor = AppColors.success;
            statusTitle = 'Checked In (Present)';
            statusSubtitle = 'Recorded at $formattedCheckIn · Verified on campus.';
            statusIcon = Icons.check_circle_outline_rounded;
          } else if (rawStatus == 'LATE') {
            statusColor = AppColors.warning;
            statusTitle = 'Checked In (Late)';
            statusSubtitle = 'Recorded at $formattedCheckIn · Arrived after scheduled start.';
            statusIcon = Icons.alarm_on_rounded;
          } else if (isOnLeave) {
            statusColor = AppColors.info;
            statusTitle = 'On Approved Leave';
            statusSubtitle = 'You are scheduled on official leave for today.';
            statusIcon = Icons.event_available_rounded;
          } else if (isAbsent) {
            statusColor = AppColors.danger;
            statusTitle = 'Marked Absent';
            statusSubtitle = 'No check-in was registered during the duty hours.';
            statusIcon = Icons.cancel_outlined;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Date & Status Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todayFormatted,
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          statusTitle,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkText : AppColors.text,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BadgeChip(
                    label: rawStatus.replaceAll('_', ' '),
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                statusSubtitle,
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Action Buttons Row
              Row(
                children: [
                  if (!isCheckedIn && !isOnLeave) ...[
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isCheckingIn
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.my_location_rounded, size: 18),
                        label: Text(
                          _isCheckingIn ? 'Verifying...' : '📍 Check In with GPS',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isCheckingIn ? null : _handleCheckIn,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],

                  // Apply for Leave button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.event_note_rounded, size: 18),
                    label: Text(isMobile ? 'Leave' : 'Apply Leave'),
                    onPressed: () => LeaveRequestDialog.show(context),
                  ),
                  const SizedBox(width: 8),

                  // View Leave History button
                  IconButton(
                    tooltip: 'Leave History',
                    icon: const Icon(Icons.history_rounded),
                    onPressed: () => LeaveHistoryModal.show(context),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
