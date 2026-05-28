import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/utils/modal_helpers.dart';
import 'package:cims/core/utils/responsive.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/widgets/modal_sheet.dart';
import 'package:cims/core/session/app_session.dart';

import 'package:cims/features/admin/sessions/models/academic_session_model.dart';
import 'package:cims/features/admin/sessions/providers/session_provider.dart';
import 'package:cims/core/utils/csv_export_helper.dart' as csv_helper;

class SessionModel {

  final int id;
  final String label;
  final String startDate;
  final String endDate;
  final String status;
  final bool current;
  final int students;

  const SessionModel({
    required this.id,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.current,
    required this.students,
  });

  factory SessionModel.fromApi(
    AcademicSessionModel a,
  ) {
    String ymd(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final status =
        a.isCurrent
            ? 'Current'
            : (!a.isActive ? 'Closed' : 'Active');

    return SessionModel(
      id: a.id,
      label: a.name,
      startDate: ymd(a.startDate),
      endDate: ymd(a.endDate),
      status: status,
      current: a.isCurrent,
      students: 0,
    );
  }
}

class SessionsScreen extends ConsumerStatefulWidget {
  final void Function(String route) onNavigate;

  const SessionsScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<SessionsScreen> createState() =>
      _SessionsScreenState();
}

class _SessionsScreenState
    extends ConsumerState<SessionsScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _statusFilter = 'All Status';

  List<SessionModel> _filteredFromApi(
    List<AcademicSessionModel> api,
  ) {
    final ui =
        api.map(SessionModel.fromApi).toList();
    return ui.where((session) {
      final matchesSearch =
          _search.isEmpty ||
              session.label.toLowerCase().contains(
                    _search.toLowerCase(),
                  );
      final matchesStatus =
          _statusFilter == 'All Status' ||
              session.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final asyncSessions =
        ref.watch(sessionsListProvider);

    return AppScaffold(
      title: 'Academic Sessions',
      subtitle: 'ACADEMICS',
      currentRoute: '/sessions',
      role: AppSession.currentRole,
      onNavigate: widget.onNavigate,
      body: asyncSessions.when(
        skipLoadingOnReload: true,
        data: (apiList) {
          final filtered = _filteredFromApi(apiList);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SessionsCard(
                searchCtrl: _searchCtrl,
                status: _statusFilter,
                onSearch:
                    (value) => setState(() => _search = value),
                onStatus: (value) =>
                    setState(() => _statusFilter = value!),
                onSetCurrent: _setCurrentSession,
                onDelete: _deleteSession,
                onCreate: () => showResponsiveModal(
                  context: context,
                  child: const _AddSessionModal(),
                ),
                onExport: () => _exportSessionsCsv(filtered),
                sessions: filtered,
              ),
            ],
          );
        },
        loading: () => Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
        error:
            (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(err.toString(),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(
                        sessionsListProvider,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Future<void> _setCurrentSession(SessionModel session) async {
    try {
      final repository = ref.read(sessionRepositoryProvider);
      await repository.setCurrentSession(session.id);
      ref.invalidate(sessionsListProvider);
      ref.invalidate(currentAcademicSessionProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${session.label} set as current session.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set current session: $error')),
      );
    }
  }

  Future<void> _deleteSession(SessionModel session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Are you sure you want to delete session "${session.label}"? This action cannot be undone.'),
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
      final repository = ref.read(sessionRepositoryProvider);
      await repository.deleteSession(session.id);
      ref.invalidate(sessionsListProvider);
      ref.invalidate(currentAcademicSessionProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session "${session.label}" deleted successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete session: $error')),
      );
    }
  }

  void _exportSessionsCsv(List<SessionModel> list) {
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No session records to export.')),
      );
      return;
    }

    final StringBuffer csv = StringBuffer();
    csv.writeln('Session,Start Date,End Date,Enrolled Students,Status');

    for (final item in list) {
      final label = item.label.replaceAll('"', '""');
      final start = item.startDate;
      final end = item.endDate;
      final students = item.students;
      final status = item.current ? 'Current' : item.status;

      csv.writeln('"$label","$start","$end",$students,"$status"');
    }

    final csvString = csv.toString();
    final fileName = 'Sessions_Export_${DateTime.now().toLocal().toString().split(' ')[0]}.csv';

    csv_helper.saveAndShareCsv(
      csvString: csvString,
      fileName: fileName,
    );
  }
}

class _SessionsCard extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String status;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final Future<void> Function(SessionModel) onSetCurrent;
  final Future<void> Function(SessionModel) onDelete;
  final VoidCallback onCreate;
  final VoidCallback onExport;
  final List<SessionModel> sessions;

  const _SessionsCard({
    required this.searchCtrl,
    required this.status,
    required this.onSearch,
    required this.onStatus,
    required this.onSetCurrent,
    required this.onDelete,
    required this.onCreate,
    required this.onExport,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Responsive.isMobile(context)
                ? _MobileToolbar(
                    searchCtrl: searchCtrl,
                    status: status,
                    onSearch: onSearch,
                    onStatus: onStatus,
                    createLabel: 'New Session',
                    onCreate: onCreate,
                    onExport: onExport,
                  )
                : _DesktopToolbar(
                    searchCtrl: searchCtrl,
                    status: status,
                    onSearch: onSearch,
                    onStatus: onStatus,
                    createLabel: 'New Session',
                    onCreate: onCreate,
                    onExport: onExport,
                  ),
          ),
          Divider(
            height: 1,
            color:
                isDark
                    ? AppColors.darkBorder
                    : AppColors.border,
          ),
          if (Responsive.isMobile(context))
            ...sessions.map(
              (session) => _SessionMobileRow(
                session: session,
                onSetCurrent: onSetCurrent,
                onDelete: onDelete,
              ),
            )
          else
            _SessionTable(
              sessions: sessions,
              onSetCurrent: onSetCurrent,
              onDelete: onDelete,
            ),
        ],
      ),
    );
  }
}

class _DesktopToolbar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String status;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final String createLabel;
  final VoidCallback onCreate;
  final VoidCallback onExport;

  const _DesktopToolbar({
    required this.searchCtrl,
    required this.status,
    required this.onSearch,
    required this.onStatus,
    required this.createLabel,
    required this.onCreate,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 1100) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              decoration: const InputDecoration(
                hintText: 'Search records',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: _StatusDropdown(
              value: status,
              onChanged: onStatus,
            ),
          ),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.filter_alt_outlined),
            label: const Text('Filters'),
          ),
          OutlinedButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Export'),
          ),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: Text(createLabel),
          ),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 400,
          child: TextField(
            controller: searchCtrl,
            onChanged: onSearch,
            decoration: const InputDecoration(
              hintText: 'Search records',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        SizedBox(width: 16),
        SizedBox(
          width: 140,
          child: _StatusDropdown(
            value: status,
            onChanged: onStatus,
          ),
        ),
        SizedBox(width: 16),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_alt_outlined),
          label: const Text('Filters'),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: onExport,
          icon: const Icon(Icons.download_rounded),
          label: const Text('Export'),
        ),
        SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: Text(createLabel),
        ),
      ],
    );
  }
}

class _MobileToolbar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String status;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final String createLabel;
  final VoidCallback onCreate;
  final VoidCallback onExport;

  const _MobileToolbar({
    required this.searchCtrl,
    required this.status,
    required this.onSearch,
    required this.onStatus,
    required this.createLabel,
    required this.onCreate,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchCtrl,
          onChanged: onSearch,
          decoration: const InputDecoration(
            hintText: 'Search records',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatusDropdown(
                value: status,
                onChanged: onStatus,
              ),
            ),
            SizedBox(width: 12),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Filters'),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onExport,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Export'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: Text(createLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _StatusDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(),
      items: const [
        DropdownMenuItem(
          value: 'All Status',
          child: Text('All Status'),
        ),
        DropdownMenuItem(
          value: 'Current',
          child: Text('Current'),
        ),
        DropdownMenuItem(
          value: 'Active',
          child: Text('Active'),
        ),
        DropdownMenuItem(
          value: 'Closed',
          child: Text('Closed'),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _SessionTable extends StatelessWidget {
  final List<SessionModel> sessions;
  final Future<void> Function(SessionModel) onSetCurrent;
  final Future<void> Function(SessionModel) onDelete;

  const _SessionTable({
    required this.sessions,
    required this.onSetCurrent,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1100,
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color:
                  isDark
                      ? AppColors.darkSurfaceAlt
                      : AppColors.surfaceAlt,
              child: Row(
                children: [
                  _HeaderCell(label: 'SESSION', flex: 20),
                  _HeaderCell(label: 'START DATE', flex: 15),
                  _HeaderCell(label: 'END DATE', flex: 15),
                  _HeaderCell(label: 'ENROLLED', flex: 15),
                  _HeaderCell(label: 'STATUS', flex: 15),
                  _HeaderCell(label: 'ACTIONS', flex: 25),
                ],
              ),
            ),
            ...sessions.map(
              (session) => _SessionDesktopRow(
                session: session,
                onSetCurrent: onSetCurrent,
                onDelete: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionDesktopRow extends StatelessWidget {
  final SessionModel session;
  final Future<void> Function(SessionModel) onSetCurrent;
  final Future<void> Function(SessionModel) onDelete;

  const _SessionDesktopRow({
    required this.session,
    required this.onSetCurrent,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color:
                isDark
                    ? AppColors.darkBorder
                    : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          _BodyCell(
            flex: 20,
            child: Text(
              session.label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _BodyCell(flex: 15, child: Text(session.startDate)),
          _BodyCell(flex: 15, child: Text(session.endDate)),
          _BodyCell(
            flex: 15,
            child: Text('${session.students} students'),
          ),
          _BodyCell(
            flex: 15,
            child: session.current
                ? const BadgeChip(
                    label: 'Current',
                    tone: BadgeTone.success,
                  )
                : BadgeChip.status(session.status),
          ),
          _BodyCell(
            flex: 25,
            child: Row(
              children: [
                if (!session.current)
                  TextButton(
                    onPressed: () => onSetCurrent(session),
                    child: Text(
                      'Set current',
                      style: AppTextStyles.bodySm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (!session.current) SizedBox(width: 16),
                IconButton(
                  onPressed: () => showResponsiveModal(
                    context: context,
                    child: _AddSessionModal(initialSession: session),
                  ),
                  icon: const _IconAction(icon: Icons.edit_outlined),
                ),
                if (!session.current) ...[
                  SizedBox(width: 16),
                  IconButton(
                    onPressed: () => onDelete(session),
                    icon: const _IconAction(icon: Icons.delete_outline_rounded),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionMobileRow extends StatelessWidget {
  final SessionModel session;
  final Future<void> Function(SessionModel) onSetCurrent;
  final Future<void> Function(SessionModel) onDelete;

  const _SessionMobileRow({
    required this.session,
    required this.onSetCurrent,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color:
                isDark
                    ? AppColors.darkBorder
                    : AppColors.border,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              session.current
                  ? const BadgeChip(
                      label: 'Current',
                      tone: BadgeTone.success,
                    )
                  : BadgeChip.status(session.status),
            ],
          ),
          SizedBox(height: 12),
          Text('${session.startDate} - ${session.endDate}'),
          SizedBox(height: 6),
          Text('${session.students} students'),
          SizedBox(height: 12),
          Row(
            children: [
              if (!session.current) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onSetCurrent(session),
                    child: const Text('Set current'),
                  ),
                ),
                SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => showResponsiveModal(
                    context: context,
                    child: _AddSessionModal(initialSession: session),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              if (!session.current) ...[
                SizedBox(width: 12),
                IconButton(
                  onPressed: () => onDelete(session),
                  icon: const _IconAction(icon: Icons.delete_outline_rounded),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;

  const _HeaderCell({
    required this.label,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          fontSize: 13,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final int flex;
  final Widget child;

  const _BodyCell({
    required this.flex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: child,
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;

  const _IconAction({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isDark
                  ? AppColors.darkBorder
                  : AppColors.border,
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color:
            isDark
                ? AppColors.darkTextMuted
                : AppColors.textMuted,
      ),
    );
  }
}

class _AddSessionModal extends ConsumerStatefulWidget {
  final SessionModel? initialSession;

  const _AddSessionModal({
    Key? key,
    this.initialSession,
  }) : super(key: key);

  @override
  ConsumerState<_AddSessionModal> createState() =>
      _AddSessionModalState();
}

class _AddSessionModalState
    extends ConsumerState<_AddSessionModal> {
  final _nameCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  String _status = 'Upcoming';
  bool _saving = false;
  late final bool _isEdit;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.initialSession != null;
    if (_isEdit) {
      final s = widget.initialSession!;
      _nameCtrl.text = s.label;
      _startCtrl.text = s.startDate;
      _endCtrl.text = s.endDate;
      if (s.current) {
        _status = 'Current';
      } else if (s.status == 'Closed') {
        _status = 'Closed';
      } else {
        _status = 'Upcoming';
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final startText = _startCtrl.text.trim();
    final endText = _endCtrl.text.trim();

    DateTime? startDate;
    DateTime? endDate;

    try {
      startDate = DateTime.parse(startText);
      endDate = DateTime.parse(endText);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid ISO dates like 2026-02-01.'),
        ),
      );
      return;
    }

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session name is required.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repository = ref.read(sessionRepositoryProvider);

      if (_isEdit) {
        final id = widget.initialSession!.id;
        await repository.updateSession(
          id: id,
          name: name,
          startDate: startDate,
          endDate: endDate,
          isActive: _status != 'Closed',
        );

        if (_status == 'Current') {
          await repository.setCurrentSession(id);
        }
      } else {
        final created = await repository.createSession(
          name: name,
          startDate: startDate,
          endDate: endDate,
        );

        if (_status == 'Current') {
          await repository.setCurrentSession(created.id);
        } else if (_status == 'Closed') {
          await repository.updateSession(
            id: created.id,
            isActive: false,
          );
        }
      }

      ref.invalidate(sessionsListProvider);
      ref.invalidate(currentAcademicSessionProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save session: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CimsModal(
      title: _isEdit ? 'Edit Session' : 'New Session',
      subtitle: _isEdit ? 'Update an academic session' : 'Create an academic session',
      actionLabel: _isEdit ? 'Save Changes' : 'Save Session',
      isLoading: _saving,
      onAction: _save,
      child: Column(
        children: [
          CimsFormField(
            label: 'Session Name',
            controller: _nameCtrl,
            hint: '2026-27 Spring',
          ),
          SizedBox(height: 16),
          Responsive.isMobile(context)
              ? Column(
                  children: [
                    CimsFormField(
                      label: 'Start Date',
                      controller: _startCtrl,
                      hint: '2026-02-01',
                    ),
                    SizedBox(height: 16),
                    CimsFormField(
                      label: 'End Date',
                      controller: _endCtrl,
                      hint: '2026-07-15',
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: CimsFormField(
                        label: 'Start Date',
                        controller: _startCtrl,
                        hint: '2026-02-01',
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: CimsFormField(
                        label: 'End Date',
                        controller: _endCtrl,
                        hint: '2026-07-15',
                      ),
                    ),
                  ],
                ),
          SizedBox(height: 16),
          CimsDropdownField<String>(
            label: 'Status',
            value: _status,
            items: const [
              'Upcoming',
              'Current',
              'Closed',
            ],
            itemLabel: (value) => value,
            onChanged: (value) =>
                setState(() => _status = value!),
          ),
        ],
      ),
    );
  }
}