import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/auth/login_screen.dart';

void main() {
  runApp(const SpendoraApp());
}

class SpendoraApp extends StatelessWidget {
  const SpendoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spendora',
      theme: buildSpendoraTheme(),
      home: const LoginScreen(),
    );
  }
}
