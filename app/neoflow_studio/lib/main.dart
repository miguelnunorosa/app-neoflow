import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:neoflow_studio/core/constants.dart';
import 'firebase_options.dart';
import 'features/auth/screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // fullscreen mode
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
    if (systemOverlaysAreVisible) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  });

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Intl / Locale PT-PT
  await initializeDateFormatting('pt_PT');
  Intl.defaultLocale = 'pt_PT';

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NeoFlow',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        primaryColor: APP_PRIMARY_COLOR,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: APP_PRIMARY_COLOR),
      ),

      // Localização (datas, widgets traduzidos, etc.)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'PT'),
      ],

      home: const AuthGate(),
    );
  }
}
