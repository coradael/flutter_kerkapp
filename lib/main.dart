import 'package:flutter/material.dart';
import 'core/config/supabase_config.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  runApp(const KerkApp());
}

