import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'secrets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const InsightsProApp(),
    ),
  );
}

class InsightsProApp extends StatelessWidget {
  const InsightsProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insights Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Use a Consumer to decide which screen to show based on AppState
      home: Consumer<AppState>(
        builder: (context, appState, child) {
          if (!appState.isAuthenticated) {
            return const AuthScreen();
          }
          if (appState.isFirstTimeUser) {
            return const OnboardingScreen();
          }
          return const DashboardScreen();
        },
      ),
    );
  }
}

// Removed placeholder screens from main.dart, they will be in their own files
