import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class VeylolaApp extends StatelessWidget {
  const VeylolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veylola AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF08080D),
      ),
      home: const HomeScreen(),
    );
  }
}
