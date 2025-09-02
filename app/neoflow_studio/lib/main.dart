import 'package:flutter/material.dart';
import 'package:neoflow_studio/core/constants.dart';
import 'features/auth/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,  //TODO: change this before release
      title: 'NeoFlow',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        primaryColor: APP_PRIMARY_COLOR,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: APP_PRIMARY_COLOR),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: APP_PRIMARY_COLOR, width: 2),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
