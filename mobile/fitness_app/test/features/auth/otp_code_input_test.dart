import 'package:fitness_app/features/auth/presentation/widgets/otp_code_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders each entered OTP digit in its own cell', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpCodeInput(
            controller: controller,
            enabled: true,
            label: 'Access code',
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '862');
    await tester.pump();

    expect(find.text('8'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
