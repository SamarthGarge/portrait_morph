import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portrait_morph/portrait_morph.dart';

void main() {
  testWidgets('renders a fallback Image before textures are ready',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 300,
          height: 300,
          child: PortraitMorph(
            imageA: AssetImage('assets/does_not_exist_a.png'),
            imageB: AssetImage('assets/does_not_exist_b.png'),
            alt: 'Test portrait',
          ),
        ),
      ),
    );

    // Shader compilation + image resolution is async, so the very first
    // frame must show the static fallback rather than throw.
    expect(find.byType(Image), findsOneWidget);
    expect(find.bySemanticsLabel('Test portrait'), findsOneWidget);
  });
}
