import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cims/core/network/app_router.dart';
import 'package:cims/core/session/auth_session_controller.dart';
import 'package:cims/core/theme/app_theme.dart';
import 'package:cims/core/theme/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await AuthSessionController.instance.restore();

  runApp(
    const ProviderScope(
      child: CimsApp(),
    ),
  );
}

class CimsApp extends ConsumerWidget {
  const CimsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'CIMS',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}