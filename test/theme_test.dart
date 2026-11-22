import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cims/core/theme/app_theme.dart';
import 'package:cims/core/theme/theme_mode_provider.dart';
import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/widgets/modal_sheet.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  group('Theme Configuration Verification', () {
    testWidgets('AppTheme.light configuration has correct brightness and colors', (tester) async {
      final light = AppTheme.light;
      expect(light.brightness, Brightness.light);
      expect(light.scaffoldBackgroundColor, AppColors.bg);
      expect(light.colorScheme.surface, AppColors.surface);
      expect(light.colorScheme.onSurface, AppColors.text);
      expect(light.colorScheme.surfaceTint, Colors.transparent);
      expect(light.dialogTheme.backgroundColor, AppColors.surface);
      expect(light.bottomSheetTheme.backgroundColor, AppColors.surface);
      expect(light.popupMenuTheme.color, AppColors.surface);
    });

    testWidgets('AppTheme.dark configuration has correct brightness and colors', (tester) async {
      final dark = AppTheme.dark;
      expect(dark.brightness, Brightness.dark);
      expect(dark.scaffoldBackgroundColor, AppColors.darkBg);
      expect(dark.colorScheme.surface, AppColors.darkSurface);
      expect(dark.colorScheme.onSurface, AppColors.darkText);
      expect(dark.colorScheme.surfaceTint, Colors.transparent);
      expect(dark.dialogTheme.backgroundColor, AppColors.darkSurface);
      expect(dark.bottomSheetTheme.backgroundColor, AppColors.darkSurface);
      expect(dark.popupMenuTheme.color, AppColors.darkSurface);
    });

    testWidgets('AppTextStyles.label does not lock static colors', (tester) async {
      expect(AppTextStyles.label.color, isNull);
      expect(AppTextStyles.labelSm.color, isNull);
      expect(AppTextStyles.labelLg.color, isNull);
    });

    test('themeModeProvider defaults to dark and toggles properly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);

      container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), ThemeMode.light);

      container.read(themeModeProvider.notifier).state = ThemeMode.dark;
      expect(container.read(themeModeProvider), ThemeMode.dark);

      container.read(themeModeProvider.notifier).update((s) => ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });

  group('Dynamic Theme Switching across Roles', () {
    Future<void> pumpThemedApp(
      WidgetTester tester, {
      required ThemeMode themeMode,
      required String role,
      required String title,
    }) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            home: AppScaffold(
              title: title,
              subtitle: 'Module',
              currentRoute: '/dashboard',
              role: role,
              onNavigate: (_) {},
              body: Column(
                children: [
                  Text('Dashboard Content', style: AppTextStyles.h1),
                  Text('Secondary detail', style: AppTextStyles.body),
                  Text('TABLE LABEL', style: AppTextStyles.labelSm),
                  const BadgeChip(label: 'Active', tone: BadgeTone.success),
                  const BadgeChip(label: 'Muted', tone: BadgeTone.muted),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
    }

    testWidgets('Admin panel renders cleanly in Light and Dark Mode', (tester) async {
      // Light Mode
      await pumpThemedApp(tester, themeMode: ThemeMode.light, role: 'admin', title: 'Admin Overview');
      expect(find.text('Admin Overview'), findsOneWidget);
      expect(find.text('Dashboard Content'), findsOneWidget);
      expect(find.text('TABLE LABEL'), findsOneWidget);

      // Dark Mode
      await pumpThemedApp(tester, themeMode: ThemeMode.dark, role: 'admin', title: 'Admin Overview');
      expect(find.text('Admin Overview'), findsOneWidget);
      expect(find.text('Dashboard Content'), findsOneWidget);
      expect(find.text('TABLE LABEL'), findsOneWidget);
    });

    testWidgets('Student panel renders cleanly in Light and Dark Mode', (tester) async {
      await pumpThemedApp(tester, themeMode: ThemeMode.light, role: 'student', title: 'Student Portal');
      expect(find.text('Student Portal'), findsOneWidget);
      expect(find.text('Dashboard Content'), findsOneWidget);

      await pumpThemedApp(tester, themeMode: ThemeMode.dark, role: 'student', title: 'Student Portal');
      expect(find.text('Student Portal'), findsOneWidget);
      expect(find.text('Dashboard Content'), findsOneWidget);
    });

    testWidgets('Teacher panel renders cleanly in Light and Dark Mode', (tester) async {
      await pumpThemedApp(tester, themeMode: ThemeMode.light, role: 'teacher', title: 'Teacher Desk');
      expect(find.text('Teacher Desk'), findsOneWidget);
      expect(find.text('Dashboard Content'), findsOneWidget);

      await pumpThemedApp(tester, themeMode: ThemeMode.dark, role: 'teacher', title: 'Teacher Desk');
      expect(find.text('Teacher Desk'), findsOneWidget);
      expect(find.text('Dashboard Content'), findsOneWidget);
    });

    testWidgets('Form fields and dropdowns adapt to Light and Dark modes', (tester) async {
      Widget buildForm(ThemeMode mode) {
        return MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const CimsFormField(label: 'Username', hint: 'Enter username'),
                  CimsDropdownField<String>(
                    label: 'Role',
                    value: 'Admin',
                    items: const ['Admin', 'Teacher', 'Student'],
                    itemLabel: (s) => s,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildForm(ThemeMode.light));
      await tester.pumpAndSettle();
      expect(find.text('USERNAME'), findsOneWidget);
      expect(find.text('ROLE'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);

      await tester.pumpWidget(buildForm(ThemeMode.dark));
      await tester.pumpAndSettle();
      expect(find.text('USERNAME'), findsOneWidget);
      expect(find.text('ROLE'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });
  });
}
