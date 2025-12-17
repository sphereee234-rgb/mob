import 'package:flutter/material.dart';
import 'home_screen.dart';

// File: main.dart
// Purpose: Application entry point. Launches the `HomeScreen` wrapped in
// a minimal `MaterialApp`.
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Currecy Converter",
      home: HomeScreen(),
    );
  }
}
