import 'package:flutter_test/flutter_test.dart';

import 'package:survivor/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const SurvivorApp());
    expect(find.byType(SurvivorApp), findsOneWidget);
  });
}
