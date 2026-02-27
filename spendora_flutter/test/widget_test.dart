import 'package:flutter_test/flutter_test.dart';

import 'package:spendora_flutter/main.dart';

void main() {
  testWidgets('Spendora login screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SpendoraApp());

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('No account yet? Create one'), findsOneWidget);
  });
}
