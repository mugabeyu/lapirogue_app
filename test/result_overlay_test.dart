import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapirogue_hotel/core/theme/app_theme.dart';
import 'package:lapirogue_hotel/core/widgets/result_overlay.dart';

/// The overlay exists so a guest actually sees the outcome of an action
/// before the app moves on. These tests pin the two things that matter:
/// it blocks until acknowledged, and the caller's navigation runs after it.

void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    required void Function(BuildContext) onPressed,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => onPressed(context),
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the success title and message', (tester) async {
    await pumpHost(
      tester,
      onPressed: (context) => showResultOverlay(
        context,
        success: true,
        title: 'Booking confirmed',
        message: 'Reception has been notified.',
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Booking confirmed'), findsOneWidget);
    expect(find.text('Reception has been notified.'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // Let the auto-continue timer drain so the test ends cleanly.
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('sits on the hotel photograph, not a blank page', (tester) async {
    await pumpHost(
      tester,
      onPressed: (context) => showResultOverlay(
        context,
        success: true,
        title: 'Booking confirmed',
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final image = tester.widget<Image>(find.byType(Image).first);
    final provider = image.image as AssetImage;
    expect(provider.assetName, 'assets/images/home.jpeg');

    // Copy has to be light to stay readable on the darkened photo.
    final title = tester.widget<Text>(find.text('Booking confirmed'));
    expect(title.style?.color, Colors.white);

    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('uses a distinct mark for failure', (tester) async {
    await pumpHost(
      tester,
      onPressed: (context) => showResultOverlay(
        context,
        success: false,
        title: 'Booking not completed',
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Booking not completed'), findsOneWidget);
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);

    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('the caller continues only after the overlay closes',
      (tester) async {
    var continued = false;

    await pumpHost(
      tester,
      onPressed: (context) async {
        await showResultOverlay(
          context,
          success: true,
          title: 'Password updated',
        );
        continued = true;
      },
    );

    await tester.tap(find.text('Go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(continued, isFalse, reason: 'navigation ran before the guest saw the result');

    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(continued, isTrue);
  });

  testWidgets('tapping dismisses it early', (tester) async {
    await pumpHost(
      tester,
      onPressed: (context) => showResultOverlay(
        context,
        success: true,
        title: 'Done',
        autoContinueAfter: const Duration(seconds: 30),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.text('Tap to continue'));
    await tester.pumpAndSettle();

    expect(find.text('Done'), findsNothing);
  });
}
