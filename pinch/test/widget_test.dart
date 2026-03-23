import 'package:flutter_test/flutter_test.dart';

import 'package:pinch/main.dart';

void main() {
  testWidgets('App renders PINCH text', (WidgetTester tester) async {
    await tester.pumpWidget(const PinchApp());
    expect(find.text('PINCH'), findsOneWidget);
  });
}
