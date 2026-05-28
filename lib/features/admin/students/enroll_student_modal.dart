import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:cims/core/network/dio_error_message.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/features/admin/students/models/student_api_model.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/admin/programs/providers/program_provider.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';

class EnrollStudentModal extends ConsumerStatefulWidget {
  final StudentApiModel? studentToEdit;

  const EnrollStudentModal({
    super.key,
    this.studentToEdit,
  });

  @override
  ConsumerState<EnrollStudentModal> createState() =>
      _EnrollStudentModalState();
}

class _EnrollStudentModalState
    extends ConsumerState<EnrollStudentModal> {
  int? selectedProgramId;
  int? selectedSessionId;
  int? selectedStage;
  String status = 'Active';

  final firstCtrl = TextEditingController();
  final lastCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final guardianCtrl = TextEditingController();
  final guardianPhoneCtrl = TextEditingController();
  final registrationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.studentToEdit != null) {
      final s = widget.studentToEdit!;
      firstCtrl.text = s.firstName;
      lastCtrl.text = s.lastName;
      emailCtrl.text = s.email ?? '';
      phoneCtrl.text = s.phone ?? '';
      addressCtrl.text = s.address ?? '';
      registrationCtrl.text = s.registrationNumber;
      
      if (s.program != null) {
        selectedProgramId = s.program!.id;
      }
      if (s.admissionSession != null) {
        selectedSessionId = s.admissionSession!.id;
      }
      selectedStage = s.currentStage;
      status = s.status.isEmpty ? 'Active' : _capitalize(s.status);
      
      if (s.dateOfBirth != null && s.dateOfBirth!.isNotEmpty) {
        try {
          final d = DateTime.parse(s.dateOfBirth!);
          dobCtrl.text = '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
        } catch (_) {
          dobCtrl.text = s.dateOfBirth!;
        }
      }
      guardianCtrl.text = s.guardianName ?? '';
      guardianPhoneCtrl.text = s.guardianPhone ?? '';
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    final isPhone = Responsive.isMobile(context);
    final isEditing = widget.studentToEdit != null;

    final programsAsync = ref.watch(programsProvider);
    final sessionsAsync = ref.watch(sessionsListProvider);

    final programsList = programsAsync.value ?? [];
    final activeProgramId = selectedProgramId ?? (programsList.isNotEmpty ? programsList.first.id : null);

    AsyncValue<List<dynamic>>? stagesAsync;
    if (activeProgramId != null) {
      stagesAsync = ref.watch(programStagesProvider(activeProgramId));
    }

    final programDropdown = programsAsync.when(
      data: (list) {
        final currentActive = selectedProgramId ?? (list.isNotEmpty ? list.first.id : null);
        return _idDropdown(
          label: 'PROGRAM',
          value: currentActive,
          items: list.map((p) => DropdownMenuItem<int>(
            value: p.id,
            child: Text(p.name, overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: (v) {
            setState(() {
              selectedProgramId = v;
              selectedStage = null;
            });
          },
          hintText: 'Select program',
        );
      },
      loading: () => _idDropdown(
        label: 'PROGRAM',
        value: null,
        items: const [],
        onChanged: (_) {},
        hintText: 'Loading programs...',
      ),
      error: (err, _) => _idDropdown(
        label: 'PROGRAM',
        value: null,
        items: const [],
        onChanged: (_) {},
        hintText: 'Error loading programs',
      ),
    );

    final sessionDropdown = sessionsAsync.when(
      data: (list) {
        final currentActive = selectedSessionId ?? (list.isNotEmpty ? list.first.id : null);
        return _idDropdown(
          label: 'ADMISSION SESSION',
          value: currentActive,
          items: list.map((s) => DropdownMenuItem<int>(
            value: s.id,
            child: Text(s.name, overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: (v) => setState(() => selectedSessionId = v),
          hintText: 'Select session',
        );
      },
      loading: () => _idDropdown(
        label: 'ADMISSION SESSION',
        value: null,
        items: const [],
        onChanged: (_) {},
        hintText: 'Loading sessions...',
      ),
      error: (err, _) => _idDropdown(
        label: 'ADMISSION SESSION',
        value: null,
        items: const [],
        onChanged: (_) {},
        hintText: 'Error loading sessions',
      ),
    );

    Widget stageDropdown;
    if (activeProgramId == null) {
      stageDropdown = _idDropdown(
        label: 'STARTING STAGE',
        value: null,
        items: const [],
        onChanged: (_) {},
        hintText: 'Select a program first',
      );
    } else {
      stageDropdown = stagesAsync?.when(
        data: (list) {
          final currentActive = selectedStage ?? (list.isNotEmpty ? list.first.stage : null);
          return _idDropdown(
            label: 'STARTING STAGE',
            value: currentActive,
            items: list.map((stg) => DropdownMenuItem<int>(
              value: stg.stage,
              child: Text(stg.label, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) => setState(() => selectedStage = v),
            hintText: 'Select starting stage',
          );
        },
        loading: () => _idDropdown(
          label: 'STARTING STAGE',
          value: null,
          items: const [],
          onChanged: (_) {},
          hintText: 'Loading stages...',
        ),
        error: (err, _) => _idDropdown(
          label: 'STARTING STAGE',
          value: null,
          items: const [],
          onChanged: (_) {},
          hintText: 'Error loading stages',
        ),
      ) ?? _idDropdown(
        label: 'STARTING STAGE',
        value: null,
        items: const [],
        onChanged: (_) {},
        hintText: 'Select a program first',
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: Responsive.modalInsetPadding(context),
      child: Container(
        width: Responsive.modalWidth(context),
        constraints: BoxConstraints(
          maxHeight: isPhone ? MediaQuery.of(context).size.height * 0.94 : 820,
          maxWidth: isPhone ? double.infinity : 720,
        ),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(22),
            bottom: Radius.circular(isPhone ? 0 : 22),
          ),
          border: Border.all(
            color: AppColors.darkBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Student' : 'Enroll Student',
                          style: AppTextStyles.h2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEditing ? 'Update student details and records' : 'Generate roll number and welcome credentials',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.darkTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: AppColors.darkBorder,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _twoColumn(
                      context,
                      _field('FIRST NAME', firstCtrl),
                      _field('LAST NAME', lastCtrl),
                    ),
                    const SizedBox(height: 22),
                    _twoColumn(
                      context,
                      _field('PHONE', phoneCtrl),
                      _dateField('DATE OF BIRTH', dobCtrl),
                    ),
                    const SizedBox(height: 22),
                    _field('ADDRESS', addressCtrl),
                    const SizedBox(height: 22),
                    _field('EMAIL', emailCtrl),
                    const SizedBox(height: 22),
                    _twoColumn(
                      context,
                      _field('GUARDIAN NAME', guardianCtrl),
                      _field('GUARDIAN PHONE', guardianPhoneCtrl),
                    ),
                    const SizedBox(height: 22),
                    _twoColumn(
                      context,
                      programDropdown,
                      sessionDropdown,
                    ),
                    const SizedBox(height: 22),
                    _field('REGISTRATION NUMBER', registrationCtrl),
                    const SizedBox(height: 22),
                    _twoColumn(
                      context,
                      stageDropdown,
                      _dropdown(
                        'STATUS',
                        status,
                        const [
                          'Active',
                          'Suspended',
                        ],
                        (v) => setState(() => status = v!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceAlt,
                borderRadius: BorderRadius.vertical(
                  top: Radius.zero,
                  bottom: Radius.circular(isPhone ? 0 : 22),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.darkBorder,
                  ),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 12,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _enroll,
                    icon: Icon(isEditing ? Icons.save_rounded : Icons.add_rounded),
                    label: Text(isEditing ? 'Save Changes' : 'Enroll Student'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _twoColumn(
    BuildContext context,
    Widget left,
    Widget right,
  ) {
    if (Responsive.isMobile(context)) {
      return Column(
        children: [
          left,
          const SizedBox(height: 18),
          right,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 10),
        TextField(controller: ctrl),
      ],
    );
  }

  Widget _idDropdown({
    required String label,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required void Function(int?) onChanged,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: value,
          decoration: InputDecoration(
            hintText: hintText,
          ),
          dropdownColor: AppColors.darkSurface,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 10),
        Builder(builder: (ctx) {
          final opts = List<String>.from(items);
          if (value.isNotEmpty && !opts.contains(value)) {
            opts.insert(0, value);
          }

          final initial = opts.contains(value) ? value : null;

          return DropdownButtonFormField<String>(
            initialValue: initial,
            decoration: const InputDecoration(),
            dropdownColor: AppColors.darkSurface,
            items: opts
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          );
        }),
      ],
    );
  }

  Widget _dateField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 10),
        TextField(
          controller: ctrl,
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'mm/dd/yyyy',
            suffixIcon: Icon(
              Icons.calendar_today_rounded,
            ),
          ),
          onTap: () async {
            final initialDate = _parseDate(ctrl.text) ?? DateTime.now().subtract(const Duration(days: 365 * 18));
            final picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              final formatted = '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
              ctrl.text = formatted;
            }
          },
        ),
      ],
    );
  }

  DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;
    try {
      final parts = s.split('/');
      if (parts.length != 3) return null;
      final m = int.parse(parts[0]);
      final d = int.parse(parts[1]);
      final y = int.parse(parts[2]);
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppTextStyles.label,
    );
  }

  Future<void> _enroll() async {
    try {
      final repo = ref.read(studentRepositoryProvider);

      final programs = ref.read(programsProvider).value ?? [];
      final resolvedProgramId = selectedProgramId ?? (programs.isNotEmpty ? programs.first.id : null);
      if (resolvedProgramId == null) {
        throw Exception('Please select a program.');
      }

      final sessions = ref.read(sessionsListProvider).value ?? [];
      final resolvedSessionId = selectedSessionId ?? (sessions.isNotEmpty ? sessions.first.id : null);
      if (resolvedSessionId == null) {
        throw Exception('Please select an admission session.');
      }

      int resolvedStage = 1;
      final stages = ref.read(programStagesProvider(resolvedProgramId)).value ?? [];
      resolvedStage = selectedStage ?? (stages.isNotEmpty ? stages.first.stage : 1);

      final Map<String, dynamic> data = {
        "first_name": firstCtrl.text.trim(),
        "last_name": lastCtrl.text.trim(),
        "registration_number": registrationCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "phone": phoneCtrl.text.trim(),
        "address": addressCtrl.text.trim(),
        "guardian_name": guardianCtrl.text.trim(),
        "guardian_phone": guardianPhoneCtrl.text.trim(),
        "program_id": resolvedProgramId,
        "admission_session_id": resolvedSessionId,
        "current_stage": resolvedStage,
        "status": status.toLowerCase(),
      };

      if (data["first_name"].toString().isEmpty || data["last_name"].toString().isEmpty) {
        throw Exception('First and last names are required.');
      }
      if (data["registration_number"].toString().isEmpty) {
        throw Exception('Registration number is required.');
      }

      final dob = _parseDate(dobCtrl.text);
      if (dob != null) {
        data['date_of_birth'] = '${dob.year.toString().padLeft(4, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
      }

      if (widget.studentToEdit != null) {
        await repo.updateStudent(widget.studentToEdit!.id, data);
      } else {
        await repo.createStudent(data);
      }

      if (mounted) {
        ref.invalidate(studentsListProvider);
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      final message = dioErrorMessage(e, fallback: 'Error enrolling student');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }
}
