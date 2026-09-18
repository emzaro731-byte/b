import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

const supabaseUrl = 'https://vihbsfrwnslnmheowkhy.supabase.co';
const supabasePublishableKey = 'sb_publishable_Rnc9vqvuULFLmtlpkw0_lQ_6xJCqkQ_';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const VeylolaApp());
}
