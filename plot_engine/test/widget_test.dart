import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plot_engine/main.dart';

void main() {
  testWidgets('PlotEngine app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const PlotEngineApp());

    expect(find.text('PlotEngine'), findsOneWidget);
    expect(find.text('AI Comments'), findsOneWidget);
    expect(find.text('Knowledge Base'), findsOneWidget);
  });
}
