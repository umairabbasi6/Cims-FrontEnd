import 'package:flutter/material.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/session/app_session.dart';

class SettingsScreen
    extends StatefulWidget {
  final void Function(String route)
  onNavigate;

  const SettingsScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  bool admissionsEnabled = true;
  bool smsEnabled = true;
  bool portalEnabled = false;
  bool lmsEnabled = false;

 @override
Widget build(BuildContext context) {
  return AppScaffold(
    title: 'Settings',
    subtitle: 'System',
    currentRoute: '/settings',
    role: AppSession.currentRole,
    onNavigate: widget.onNavigate,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _systemSettingsCard(),
        const SizedBox(height: 20),
        _modulesCard(),
      ],
    ),
  );
}

  Widget _systemSettingsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color:
              isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),

      child: Column(
        children: [
          // HEADER

          Padding(
            padding:
                const EdgeInsets.all(
              20,
            ),

            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        'System Settings',

                        style:
                            AppTextStyles
                                .h3,
                      ),

                      SizedBox(
                        height: 4,
                      ),

                      Text(
                        'Institute-wide configuration',

                        style:
                            AppTextStyles
                                .body
                                .copyWith(
                                  color:
                                      isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                ),
                      ),
                    ],
                  ),
                ),

                ElevatedButton(
                  onPressed: () {},

                  child: const Text(
                    'Save changes',
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color:
                isDark ? AppColors.darkBorder : AppColors.border,
          ),

          // FORM

          Padding(
            padding:
                const EdgeInsets.all(
              20,
            ),

            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller:
                            TextEditingController(
                              text:
                                  'Capital Institute of Para Medical Sciences',
                            ),

                        decoration:
                            const InputDecoration(
                              labelText:
                                  'INSTITUTE NAME',
                            ),
                      ),
                    ),

                    SizedBox(
                      width: 16,
                    ),

                    Expanded(
                      child: TextField(
                        controller:
                            TextEditingController(
                              text:
                                  'CIMS',
                            ),

                        decoration:
                            const InputDecoration(
                              labelText:
                                  'SHORT CODE',
                            ),
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: 18,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          DropdownButtonFormField<
                            String
                          >(
                        initialValue:
                            'PKR — Pakistani Rupee',

                        decoration:
                            const InputDecoration(
                              labelText:
                                  'CURRENCY',
                            ),

                        dropdownColor:
                            AppColors
                                .darkSurface,

                        items: const [
                          DropdownMenuItem(
                            value:
                                'PKR — Pakistani Rupee',

                            child: Text(
                              'PKR — Pakistani Rupee',
                            ),
                          ),
                        ],

                        onChanged:
                            (_) {},
                      ),
                    ),

                    SizedBox(
                      width: 16,
                    ),

                    Expanded(
                      child:
                          DropdownButtonFormField<
                            String
                          >(
                        initialValue:
                            'Asia/Karachi (GMT+5)',

                        decoration:
                            const InputDecoration(
                              labelText:
                                  'TIMEZONE',
                            ),

                        dropdownColor:
                            AppColors
                                .darkSurface,

                        items: const [
                          DropdownMenuItem(
                            value:
                                'Asia/Karachi (GMT+5)',

                            child: Text('Asia/Karachi (GMT+5)',
                            ),
                          ),
                        ],

                        onChanged:
                            (_) {},
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: 18,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          DropdownButtonFormField<
                            String
                          >(
                        initialValue:
                            'August',

                        decoration:
                            const InputDecoration(
                              labelText:
                                  'ACADEMIC YEAR START',
                            ),

                        dropdownColor:
                            AppColors
                                .darkSurface,

                        items: const [
                          DropdownMenuItem(
                            value:
                                'August',

                            child: Text(
                              'August',
                            ),
                          ),
                        ],

                        onChanged:
                            (_) {},
                      ),
                    ),

                    SizedBox(
                      width: 16,
                    ),

                    Expanded(
                      child: TextField(
                        controller:
                            TextEditingController(
                              text:
                                  '75%',
                            ),

                        decoration:
                            const InputDecoration(
                              labelText:
                                  'ATTENDANCE THRESHOLD',
                            ),
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: 18,
                ),

                TextField(
                  maxLines: 3,

                  controller:
                      TextEditingController(
                        text:
                            'Street 5, Sector G-7/2, Islamabad, Pakistan',
                      ),

                  decoration:
                      const InputDecoration(
                        labelText:
                            'ADDRESS',
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modulesCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color:
              isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),

      child: Column(
        children: [
          // HEADER

          Padding(
            padding:
                const EdgeInsets.all(
              20,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  'Modules',

                  style:
                      AppTextStyles.h3,
                ),

                SizedBox(
                  height: 4,
                ),

                Text(
                  'Enable or disable platform modules',

                  style:
                      AppTextStyles.body
                          .copyWith(
                    color:
                        isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color:
                isDark ? AppColors.darkBorder : AppColors.border,
          ),

          Padding(
            padding:
                const EdgeInsets.all(
              20,
            ),

            child: Column(
              children: [
                _moduleRow(
                  icon:
                      Icons.flash_on_rounded,

                  title:
                      'Online Admissions',

                  subtitle:
                      'Allow public application form',

                  enabled:
                      admissionsEnabled,

                  onChanged:
                      (v) {
                    setState(() {
                      admissionsEnabled =
                          v;
                    });
                  },
                ),

                SizedBox(
                  height: 18,
                ),

                _moduleRow(
                  icon:
                      Icons.flash_on_rounded,

                  title:
                      'SMS Notifications',

                  subtitle:
                      'Send fee reminders via SMS',

                  enabled: smsEnabled,

                  onChanged:
                      (v) {
                    setState(() {
                      smsEnabled = v;
                    });
                  },
                ),

                SizedBox(
                  height: 18,
                ),

                _moduleRow(
                  icon:
                      Icons.flash_on_rounded,

                  title:
                      'Parent Portal',

                  subtitle:
                      'Guardian login & progress view',

                  enabled:
                      portalEnabled,

                  onChanged:
                      (v) {
                    setState(() {
                      portalEnabled = v;
                    });
                  },
                ),

                SizedBox(
                  height: 18,
                ),

                _moduleRow(
                  icon:
                      Icons.flash_on_rounded,

                  title:
                      'LMS Integration',

                  subtitle:
                      'Sync with Moodle / Canvas',

                  enabled: lmsEnabled,

                  onChanged:
                      (v) {
                    setState(() {
                      lmsEnabled = v;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moduleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required ValueChanged<bool>
    onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,

          decoration: BoxDecoration(
            color:
                enabled
                    ? AppColors
                        .success
                        .withValues(alpha: .15)
                    : (isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt),

            borderRadius:
                BorderRadius.circular(
              10,
            ),
          ),

          alignment: Alignment.center,

          child: Icon(
            icon,

            size: 18,

            color:
                enabled
                    ? AppColors.success
                    : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
          ),
        ),

        SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              Text(
                title,

                style:
                    AppTextStyles.body
                        .copyWith(
                  fontWeight:
                      FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.text,
                ),
              ),

              SizedBox(
                height: 2,
              ),

              Text(
                subtitle,

                style:
                    AppTextStyles
                        .caption
                        .copyWith(
                          color:
                              isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
              ),
            ],
          ),
        ),

        Switch(
          value: enabled,

          onChanged: onChanged,

          activeThumbColor:
              AppColors.primary,
        ),

        SizedBox(width: 12),

        BadgeChip(
          label:
              enabled
                  ? 'Enabled'
                  : 'Disabled',

          tone:
              enabled
                  ? BadgeTone.success
                  : BadgeTone.muted,
        ),
      ],
    );
  }
}
