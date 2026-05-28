import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/features/student/providers/student_program_provider.dart';
import 'package:cims/features/admin/students/models/student_api_model.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/auth/providers/auth_provider.dart';
import 'package:cims/features/auth/models/change_password_request.dart';
import 'package:cims/core/theme/theme_mode_provider.dart';

class StudentProfileScreen extends ConsumerWidget {
  final void Function(String route) onNavigate;

  const StudentProfileScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    final studentAsync = ref.watch(currentStudentProvider);
    final overviewAsync = ref.watch(studentProgramOverviewProvider);

    return AppScaffold(
      title: 'My Profile',
      subtitle: 'ACCOUNT',
      currentRoute: '/settings',
      role: 'student',
      onNavigate: onNavigate,
      body: studentAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (student) {
          if (student == null) {
            return Center(child: Text('Student profile not found.'));
          }
          final programLabel = overviewAsync.when(
            data: (overview) => overview != null
                ? '${overview.programCode} · ${overview.semesterValue}'
                : student.program?.code ?? '',
            loading: () => student.program?.code ?? '',
            error: (_, __) => student.program?.code ?? '',
          );

          return SingleChildScrollView(
            child: Column(
              children: [
                _ProfileHeader(student: student, programLabel: programLabel),
                SizedBox(height: 20),
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PersonalInformationCard(student: student),
                      SizedBox(height: 20),
                      _SecurityCard(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _PersonalInformationCard(student: student),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: _SecurityCard(),
                      ),
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

class _ProfileHeader extends ConsumerWidget {
  final StudentApiModel student;
  final String programLabel;

  const _ProfileHeader({required this.student, required this.programLabel});

  String _initials(String fullName) {
    final parts = fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    final initials = _initials(student.fullName);
    final subtitleParts = [
      if (programLabel.isNotEmpty) programLabel,
      if (student.email != null && student.email!.isNotEmpty) student.email!,
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (subtitleParts.isNotEmpty)
                            Text(subtitleParts.join(' · '),
                              style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                Row(
                  children: [
                    _ProfileMeta(
                      label: 'Member since',
                      value: _memberSince(student.createdAt),
                    ),
                    SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status', style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 6),
                        BadgeChip(
                          label: student.isActive ? 'Active' : 'Inactive',
                          tone: student.isActive ? BadgeTone.success : BadgeTone.warning,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showChangePasswordDialog(context, ref),
                        icon: const Icon(Icons.lock_outline_rounded),
                        label: const Text('Change password'),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      if (subtitleParts.isNotEmpty)
                        Text(subtitleParts.join(' · '),
                          style: const TextStyle(color: AppColors.darkTextMuted),
                        ),
                      SizedBox(height: 14),
                      Row(
                        children: [
                          _ProfileMeta(
                            label: 'Member since',
                            value: _memberSince(student.createdAt),
                          ),
                          SizedBox(width: 24),
                          _ProfileMeta(
                            label: 'Student ID',
                            value: student.studentIdCode,
                          ),
                          SizedBox(width: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status', style: TextStyle(fontWeight: FontWeight.w700)),
                              SizedBox(height: 6),
                              BadgeChip(
                                label: student.isActive ? 'Active' : 'Inactive',
                                tone: student.isActive ? BadgeTone.success : BadgeTone.warning,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showChangePasswordDialog(context, ref),
                  icon: const Icon(Icons.lock_outline_rounded),
                  label: const Text('Change password'),
                ),
              ],
            ),
    );
  }

  String _memberSince(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

class _ProfileMeta extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.darkTextMuted)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Personal Information Card (editable)
// ─────────────────────────────────────────────

class _PersonalInformationCard extends ConsumerStatefulWidget {
  final StudentApiModel student;

  const _PersonalInformationCard({required this.student});

  @override
  ConsumerState<_PersonalInformationCard> createState() =>
      _PersonalInformationCardState();
}

class _PersonalInformationCardState
    extends ConsumerState<_PersonalInformationCard> {
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  bool _saving = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.student.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.student.email ?? '');
    _addressCtrl = TextEditingController(text: widget.student.address ?? '');

    _phoneCtrl.addListener(_onChanged);
    _emailCtrl.addListener(_onChanged);
    _addressCtrl.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(studentRepositoryProvider);
      final updates = <String, dynamic>{};
      if (_phoneCtrl.text.trim().isNotEmpty) {
        updates['phone'] = _phoneCtrl.text.trim();
      }
      if (_emailCtrl.text.trim().isNotEmpty) {
        updates['email'] = _emailCtrl.text.trim();
      }
      if (_addressCtrl.text.trim().isNotEmpty) {
        updates['address'] = _addressCtrl.text.trim();
      }
      if (updates.isEmpty) {
        setState(() {_saving = false; _isDirty = false;});
        return;
      }
      await repo.updateStudent(widget.student.id, updates);
      ref.invalidate(currentStudentProvider);
      if (mounted) {
        setState(() {_saving = false; _isDirty = false;});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    final student = widget.student;
    final programLabel = student.program != null
        ? '${student.program!.code} · Stage ${student.currentStage}'
        : 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal Information', style: AppTextStyles.h2),
            SizedBox(height: 4),
            Text('Update your account details',
              style: const TextStyle(color: AppColors.darkTextMuted),
            ),
            SizedBox(height: 20),
            if (isMobile) ...[
              _ReadOnlyField(label: 'FULL NAME', value: student.fullName),
              SizedBox(height: 16),
              _EditableField(label: 'EMAIL', controller: _emailCtrl, hint: 'Enter email'),
            ] else
              Row(
                children: [
                  Expanded(child: _ReadOnlyField(label: 'FULL NAME', value: student.fullName)),
                  SizedBox(width: 16),
                  Expanded(child: _EditableField(label: 'EMAIL', controller: _emailCtrl, hint: 'Enter email')),
                ],
              ),
            SizedBox(height: 16),
            if (isMobile) ...[
              _EditableField(label: 'PHONE', controller: _phoneCtrl, hint: 'e.g. +92 300 1234567'),
              SizedBox(height: 16),
              _ReadOnlyField(label: 'ROLE', value: programLabel),
            ] else
              Row(
                children: [
                  Expanded(child: _EditableField(label: 'PHONE', controller: _phoneCtrl, hint: 'e.g. +92 300 1234567')),
                  SizedBox(width: 16),
                  Expanded(child: _ReadOnlyField(label: 'ROLE', value: programLabel)),
                ],
              ),
            SizedBox(height: 16),
            _EditableField(label: 'ADDRESS', controller: _addressCtrl, hint: 'Enter your address'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isDirty && !_saving
                      ? () {
                          _phoneCtrl.text = student.phone ?? '';
                          _emailCtrl.text = student.email ?? '';
                          _addressCtrl.clear();
                          setState(() => _isDirty = false);
                        }
                      : null,
                  child: const Text('Cancel'),
                ),
                SizedBox(width: 16),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _isDirty && !_saving ? _save : null,
                    child: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceAlt.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Text(value.isEmpty ? '—' : value,
              style: const TextStyle(color: AppColors.darkTextMuted)),
        ),
      ],
    );
  }
}

class _EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _EditableField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.darkTextMuted),
            filled: true,
            fillColor: AppColors.darkSurfaceAlt,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Security & Preferences Card
// ─────────────────────────────────────────────

class _SecurityCard extends ConsumerWidget {
  const _SecurityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      (Icons.lock_outline_rounded, AppColors.primary, 'Change password',
          'Keep your account safe', 'Update', 'button'),
      (Icons.verified_user_outlined, AppColors.success, 'Two-step verification',
          'SMS to +92 300 ••• 4567', 'Enabled', 'success'),
      (Icons.notifications_none_rounded, AppColors.accent, 'Email notifications',
          'Activity, alerts, summaries', 'On', 'primary'),
      (Icons.dark_mode_outlined, AppColors.purple, 'Theme', 'Dark mode',
          'Toggle', 'button'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Security & Preferences', style: AppTextStyles.h2),
            SizedBox(height: 4),
            const Text('Account protection',
                style: TextStyle(color: AppColors.darkTextMuted)),
            SizedBox(height: 20),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: item.$2.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.$1, color: item.$2, size: 18),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$3,
                              style: AppTextStyles.body
                                  .copyWith(fontWeight: FontWeight.w700)),
                          Text(item.$4,
                              style: const TextStyle(
                                  color: AppColors.darkTextMuted)),
                        ],
                      ),
                    ),
                    item.$6 == 'success'
                        ? BadgeChip(label: item.$5, tone: BadgeTone.success)
                        : item.$6 == 'primary'
                            ? BadgeChip(label: item.$5, tone: BadgeTone.primary)
                            : OutlinedButton(
                                onPressed: item.$3 == 'Change password'
                                    ? () => _showChangePasswordDialog(context, ref)
                                    : item.$3 == 'Theme'
                                        ? () {
                                            ref.read(themeModeProvider.notifier).update(
                                                  (state) => state == ThemeMode.dark
                                                      ? ThemeMode.light
                                                      : ThemeMode.dark,
                                                );
                                          }
                                        : () {},
                                child: Text(item.$5),
                              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showChangePasswordDialog(BuildContext context, WidgetRef ref) async {
  final oldCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool loading = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.darkBorder)),
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    filled: true,
                    fillColor: AppColors.darkSurfaceAlt,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: newCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    filled: true,
                    fillColor: AppColors.darkSurfaceAlt,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (formKey.currentState!.validate()) {
                  setState(() => loading = true);
                  try {
                    final repo = ref.read(authRepositoryProvider);
                    await repo.changePassword(
                      ChangePasswordRequest(
                        oldPassword: oldCtrl.text,
                        newPassword: newCtrl.text,
                      ),
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password updated successfully!'), backgroundColor: AppColors.success),
                      );
                    }
                  } catch (e) {
                    setState(() => loading = false);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
                      );
                    }
                  }
                }
              },
              child: loading ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Update'),
            ),
          ],
        );
      },
    ),
  );
}