import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'app.dart';

const _supabaseUrl = 'https://vihbsfrwnslnmheowkhy.supabase.co';
// Publishable client key only. Provider secrets stay in the Edge Function.
const _supabasePublishableKey = 'sb_publishable_RNvbXKwTRLQU5WIYmX0A-g_zokdaYLe';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabasePublishableKey,
  );
  runApp(const VeylolaApp());
}
