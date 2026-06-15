import 'package:flutter_test/flutter_test.dart';

import 'package:lapirogue_hotel/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LapirogueHotelApp());

    // Verify that our welcome screen loads.
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('La Pirogue Mauritius'), findsOneWidget);
  });
}
