import 'package:flutter/material.dart';
import 'auth/auth_gate.dart';

class KerkApp extends StatelessWidget {
  const KerkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kerk App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
