import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/main.dart';
import 'package:agrokera/core/widgets/primary_button.dart';
import 'package:agrokera/core/widgets/custom_text_field.dart';
import 'package:agrokera/core/widgets/status_badge.dart';

void main() {
  testWidgets('AgroKera foundation smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgroKeraApp()));

    // Verify Title and Core Widgets are present
    expect(find.text('AgroKera 🌱'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsAtLeastNWidgets(1));
    expect(find.byType(CustomTextField), findsAtLeastNWidgets(1));
    expect(find.byType(StatusBadge), findsAtLeastNWidgets(1));
    expect(find.text('შეკვეთის გაფორმება'), findsOneWidget);
  });
}
