import 'package:flutter/material.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_constants.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/utils/responsive.dart';

/// ─────────────────────────────────────────────────────────
/// CIMS GLOBAL MODAL
/// ─────────────────────────────────────────────────────────

Future<T?> showCimsModal<T>({
  required BuildContext context,
  required String title,
  required String subtitle,
  required Widget content,
  required String actionLabel,
  required VoidCallback onAction,
  bool isLoading = false,
}) {
  if (Responsive.isMobile(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: CimsModal(
            title: title,
            subtitle: subtitle,
            actionLabel: actionLabel,
            onAction: onAction,
            isLoading: isLoading,
            child: content,
          ),
        ),
      ),
    );
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: .72),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: CimsModal(
        title: title,
        subtitle: subtitle,
        actionLabel: actionLabel,
        onAction: onAction,
        isLoading: isLoading,
        child: content,
      ),
    ),
  );
}

/// ─────────────────────────────────────────────────────────
/// MODAL CONTAINER
/// ─────────────────────────────────────────────────────────

class CimsModal extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isLoading;
  final Widget child;

  const CimsModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.child,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final bg =
        isDark ? AppColors.darkSurface : AppColors.surface;

    final alt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;

    final border =
        isDark ? AppColors.darkBorder : AppColors.border;

    final isPhone = Responsive.isMobile(context);

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusLg),
            bottom: Radius.circular(
              isPhone ? 0 : AppConstants.radiusLg,
            ),
          ),

          child: Container(
            width: Responsive.modalWidth(context),
            constraints: BoxConstraints(
              maxWidth: isPhone ? double.infinity : 560,
              maxHeight: isPhone ? MediaQuery.of(context).size.height * 0.92 : 760,
            ),

            decoration: BoxDecoration(
              color: bg,

              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppConstants.radiusLg),
                bottom: Radius.circular(
                  isPhone ? 0 : AppConstants.radiusLg,
                ),
              ),

              border: Border.all(
                color: border,
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .35),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, 20),
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // ───────────────── HEADER ─────────────────

              Container(
                padding:
                    const EdgeInsets.fromLTRB(28, 24, 20, 20),

                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: border,
                    ),
                  ),
                ),

                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Text(
                            title,
                            style: AppTextStyles.h2,
                          ),

                          const SizedBox(height: 4),

                          Text(
                            subtitle,
                            style:
                                AppTextStyles.bodySm.copyWith(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    InkWell(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radius,
                      ),

                      onTap: () =>
                          Navigator.of(context).pop(),

                      child: Container(
                        width: 44,
                        height: 44,

                        decoration: BoxDecoration(
                          color: alt,

                          borderRadius:
                              BorderRadius.circular(
                            AppConstants.radius,
                          ),

                          border: Border.all(
                            color: border,
                          ),
                        ),

                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ───────────────── BODY ─────────────────

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),

                  child: child,
                ),
              ),

              // ───────────────── FOOTER ─────────────────

              Container(
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: alt,

                  border: Border(
                    top: BorderSide(
                      color: border,
                    ),
                  ),
                ),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end,

                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(),

                      child: const Text('Cancel'),
                    ),

                    const SizedBox(width: 12),

                    SizedBox(
                      height: 46,

                      child: ElevatedButton.icon(
                        onPressed:
                            isLoading ? null : onAction,

                        icon: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.add_rounded,
                                size: 18,
                              ),

                        label: Text(actionLabel),
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// TEXT FIELD
/// ─────────────────────────────────────────────────────────

class CimsFormField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  const CimsFormField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.suffixIcon,
    this.prefixIcon,
    this.readOnly = false,
    this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(label.toUpperCase(),
          style: AppTextStyles.label,
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,

          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// DROPDOWN FIELD
/// ─────────────────────────────────────────────────────────

class CimsDropdownField<T>
    extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;

  const CimsDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(label.toUpperCase(),
          style: AppTextStyles.label,
        ),

        const SizedBox(height: 8),

        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,

          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(itemLabel(e)),
                ),
              )
              .toList(),

          onChanged: onChanged,

          decoration: const InputDecoration(),

          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// DATE FIELD
/// ─────────────────────────────────────────────────────────

class CimsDateField extends StatelessWidget {
  final String label;
  final String hint;

  const CimsDateField({
    super.key,
    required this.label,
    this.hint = 'mm/dd/yyyy',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(label.toUpperCase(),
          style: AppTextStyles.label,
        ),

        const SizedBox(height: 8),

        TextFormField(
          readOnly: true,

          decoration: InputDecoration(
            hintText: hint,

            suffixIcon: const Icon(
              Icons.calendar_today_outlined,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// SEARCH FIELD
/// ─────────────────────────────────────────────────────────

class CimsSearchField extends StatelessWidget {
  final String hint;

  const CimsSearchField({
    super.key,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hint,

        prefixIcon: const Icon(
          Icons.search_rounded,
        ),
      ),
    );
  }
}
/// ─────────────────────────────────────────────────────────
/// RESPONSIVE FORM GRID
/// ─────────────────────────────────────────────────────────

class CimsFormGrid extends StatelessWidget {
  final List<Widget> children;

  const CimsFormGrid({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Wrap(
      spacing: 16,
      runSpacing: 16,

      children: children.map((child) {
        return SizedBox(
          width: isMobile
              ? double.infinity
              : (width > 1200 ? 240 : 220),

          child: child,
        );
      }).toList(),
    );
  }
}