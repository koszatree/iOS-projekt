import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('wyszukiwarka przyjmuje wpisany tekst', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final searchField = find.byKey(const Key('searchField'));
    expect(searchField, findsOneWidget);

    await tester.tap(searchField);
    await tester.enterText(searchField, 'gda');
    await tester.pump();

    expect(find.text('gda'), findsWidgets);
  });
}
