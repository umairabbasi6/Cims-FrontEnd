import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AppScaffold(
          title: 'Students',
          subtitle: 'People',
          currentRoute: '/students',
          role: 'admin',
          onNavigate: (_) {},
          body: const SizedBox(
            height: 200,
            child: Text('Body'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('phone shell uses header and bottom navigation', (
    WidgetTester tester,
  ) async {
    await pumpShell(
      tester,
      size: const Size(390, 844),
    );

    expect(find.byType(Drawer), findsNothing);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('desktop shell renders sidebar and top bar', (
    WidgetTester tester,
  ) async {
    await pumpShell(
      tester,
      size: const Size(1024, 768),
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Students'), findsWidgets);
    expect(find.text('Body'), findsOneWidget);
  });
}
