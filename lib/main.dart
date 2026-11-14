import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/auth_state_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/presentation/screens/main_nav_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(authStateProvider.notifier).restoreSession();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AgroKeraApp(),
    ),
  );
}

class AgroKeraApp extends StatelessWidget {
  const AgroKeraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroKera',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const MainNavScreen(),
    );
  }
}
