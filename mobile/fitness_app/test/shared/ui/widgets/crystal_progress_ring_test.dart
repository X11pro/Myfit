import 'package:fitness_app/shared/ui/widgets/crystal_progress_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders an empty and partially filled crystal progress ring',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CrystalProgressRing(progress: 0, child: Text('2200')),
              CrystalProgressRing(progress: 0.5, child: Text('1100')),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(CrystalProgressRing), findsNWidgets(2));
    expect(find.text('2200'), findsOneWidget);
    expect(find.text('1100'), findsOneWidget);
  });
}
