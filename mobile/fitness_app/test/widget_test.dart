import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_app/app/app.dart';

void main() {
  testWidgets('shows login entry point by default', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyfitApp()));
    await tester.pumpAndSettle();

    expect(find.text('Entrar al prototipo'), findsOneWidget);
  });
}
