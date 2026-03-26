import 'package:flutter_test/flutter_test.dart';

import 'package:server_monitor_app/main.dart';

void main() {
  testWidgets('App renders dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const ServerMonitorApp());

    // Verify the app title appears
    expect(find.text('Server Monitor'), findsOneWidget);
  });
}
