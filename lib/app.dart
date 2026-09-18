import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

class VeylolaApp extends StatelessWidget {
  const VeylolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const black = Color(0xFF000000);
    const surface = Color(0xFF0A0A0A);
    const surface2 = Color(0xFF111111);
    const accent = Color(0xFF7C4DFF);

    return MaterialApp(
      title: 'Veylola AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: black,
        canvasColor: black,
        cardColor: surface,
        colorScheme: const ColorScheme.dark(
          surface: black,
          surfaceContainer: surface,
          surfaceContainerHigh: surface2,
          primary: accent,
          onPrimary: Colors.white,
          secondary: accent,
          onSurface: Colors.white,
          onSurfaceVariant: Color(0xFFBDBDBD),
          outline: Color(0xFF2A2A2A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: black,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: surface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
            borderSide: BorderSide(color: accent, width: 1),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (snapshot.connectionState == ConnectionState.waiting && session == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return session == null ? const LoginScreen() : const HomeScreen();
      },
    );
  }
}

class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sign out',
      icon: const Icon(Icons.logout),
      onPressed: () => Supabase.instance.client.auth.signOut(),
    );
  }
}
