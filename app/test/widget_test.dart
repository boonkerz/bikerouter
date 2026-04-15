import 'package:flutter_test/flutter_test.dart';
import 'package:bikerouter/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const WegwieselApp());
    expect(find.byType(WegwieselApp), findsOneWidget);
  });
}
