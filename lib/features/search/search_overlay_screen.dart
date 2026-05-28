import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/widgets/app_scaffold.dart';

/// Full-screen search (mobile-first). Mock recents and suggestions.
class SearchOverlayScreen extends StatefulWidget {
  final void Function(String route) onNavigate;

  const SearchOverlayScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<SearchOverlayScreen> createState() =>
      _SearchOverlayScreenState();
}

class _SearchOverlayScreenState
    extends State<SearchOverlayScreen> {
  final _controller = TextEditingController();

  static const _recents = [
    'DPT attendance May',
    'Fee invoice 1024',
    'Student One',
  ];

  static const _suggestions = [
    _StudentSuggestion('Student One', 'CIMS-DPT-2104', '/students'),
    _StudentSuggestion('Student Two', 'CIMS-MLT-2208', '/students'),
    _StudentSuggestion('Student Three', 'CIMS-RIT-2311', '/students'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final strong = isDark ? AppColors.darkText : AppColors.text;

    return AppScaffold(
      title: 'Search',
      subtitle: 'CIMS',
      currentRoute: '/search',
      role: AppSession.currentRole,
      onNavigate: widget.onNavigate,
      suppressDefaultMobileSearch: true,
      actions: [
        IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Students, classes, invoices…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Recent',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w800,
              color: strong,
            ),
          ),
          SizedBox(height: 10),
          ..._recents.map(
            (q) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.history_rounded,
                color: muted,
              ),
              title: Text(q, style: AppTextStyles.body),
              onTap: () {
                _controller.text = q;
                setState(() {});
              },
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Suggested students',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w800,
              color: strong,
            ),
          ),
          SizedBox(height: 10),
          ..._suggestions.map(
            (s) => ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  s.name.split(' ').map((e) => e[0]).take(2).join(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              title: Text(
                s.name,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                s.roll,
                style: AppTextStyles.caption.copyWith(
                  color: muted,
                ),
              ),
              onTap: () {
                context.pop();
                widget.onNavigate(s.route);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentSuggestion {
  final String name;
  final String roll;
  final String route;

  const _StudentSuggestion(
    this.name,
    this.roll,
    this.route,
  );
}