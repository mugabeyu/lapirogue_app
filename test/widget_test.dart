import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapirogue_hotel/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LapirogueHotelApp()));
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
