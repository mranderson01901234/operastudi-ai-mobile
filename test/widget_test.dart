import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:operamobile/main.dart';
import 'package:operamobile/services/app_state.dart';

void main() {
  testWidgets('Opera Mobile app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AppState(),
        child: const MyApp(),
      ),
    );

    // Verify that the app loads without crashing
    expect(find.byType(MyApp), findsOneWidget);
  });
}
