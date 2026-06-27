import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_app/app/app.dart';

void main() {
  testWidgets('shows welcome screen in english by default',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyfitApp()));
    await tester.pumpAndSettle();

    expect(find.text('Continue as guest'), findsOneWidget);
  });

  testWidgets('switches splash copy to spanish when language changes',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyfitApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ESP'));
    await tester.pumpAndSettle();

    expect(find.text('Continuar como invitado'), findsOneWidget);
  });
}
