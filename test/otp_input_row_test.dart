import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapirogue_hotel/core/theme/app_theme.dart';
import 'package:lapirogue_hotel/core/widgets/otp_input_row.dart';

/// Regression tests for the verification-code input.
///
/// The bug these guard against: typed digits were unreadable because the
/// boxes collapsed to the height of a single glyph and the field used a font
/// family that did not resolve, so the code the guest entered could not be
/// checked against what they received by email.

void main() {
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;

  setUp(() {
    controllers = List.generate(6, (_) => TextEditingController());
    focusNodes = List.generate(6, (_) => FocusNode());
  });

  tearDown(() {
    for (final c in controllers) {
      c.dispose();
    }
    // The focus nodes are deliberately not disposed here: the test binding
    // has already torn down its FocusManager by this point, and detaching a
    // node afterwards asserts. They do not outlive the test.
  });

  Future<void> pumpRow(
    WidgetTester tester, {
    double width = 375,
    ValueChanged<String>? onCompleted,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: OtpInputRow(
                controllers: controllers,
                focusNodes: focusNodes,
                onCompleted: onCompleted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders one box per digit', (tester) async {
    await pumpRow(tester);
    expect(find.byType(TextField), findsNWidgets(6));
  });

  testWidgets('each box is taller than it is wide so digits are not clipped',
      (tester) async {
    await pumpRow(tester);

    // The visible box is the container that paints the border, not the
    // borderless field sitting inside it.
    final box = tester.getSize(find.byType(AnimatedContainer).first);
    expect(
      box.height,
      greaterThan(box.width),
      reason: 'boxes collapsed to a squashed pill instead of a rounded square',
    );
    expect(
      box.height,
      greaterThanOrEqualTo(44),
      reason: 'box must be tall enough to show a 24px digit plus padding',
    );
  });

  testWidgets('six boxes fit inside a narrow phone without overflowing',
      (tester) async {
    await pumpRow(tester, width: 320);
    await tester.pumpAndSettle();

    // A layout overflow reports itself as a thrown exception during paint.
    expect(tester.takeException(), isNull);
  });

  testWidgets('typing a digit advances focus to the next box', (tester) async {
    await pumpRow(tester);

    await tester.enterText(find.byType(TextField).at(0), '4');
    await tester.pumpAndSettle();

    expect(controllers[0].text, '4');
    expect(focusNodes[1].hasFocus, isTrue);
  });

  testWidgets('a pasted code spreads across every box', (tester) async {
    String? completed;
    await pumpRow(tester, onCompleted: (code) => completed = code);

    await tester.enterText(find.byType(TextField).at(0), '079716');
    await tester.pumpAndSettle();

    expect(controllers.map((c) => c.text).join(), '079716');
    expect(completed, '079716');
  });

  testWidgets('non-digits are rejected', (tester) async {
    await pumpRow(tester);

    await tester.enterText(find.byType(TextField).at(0), 'a');
    await tester.pumpAndSettle();

    expect(controllers[0].text, isEmpty);
  });

  testWidgets('deleting a digit moves focus back to the previous box',
      (tester) async {
    await pumpRow(tester);

    // Fill the second box so there is something to delete, then clear it —
    // that is what backspacing on a filled box does.
    await tester.enterText(find.byType(TextField).at(1), '7');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), '');
    await tester.pumpAndSettle();

    expect(controllers[1].text, isEmpty);
    expect(focusNodes[0].hasFocus, isTrue);
  });
}
