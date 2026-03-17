import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ios_edge_ocr/app.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EdgeOCRApp(),
      ),
    );

    // Verify the app starts and shows the download screen.
    expect(find.text('Edge OCR Setup'), findsOneWidget);
  });
}
