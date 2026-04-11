import 'package:flutter_test/flutter_test.dart';
import 'package:bikerouter/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const BikeRouterApp());
    expect(find.byType(BikeRouterApp), findsOneWidget);
  });
}
