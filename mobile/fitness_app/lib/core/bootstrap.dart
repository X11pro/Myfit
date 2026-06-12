import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_env.dart';

Future<void> bootstrapApp() async {
  if (!AppEnv.hasSupabaseConfig) {
    return;
  }

  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    publishableKey: AppEnv.supabaseAnonKey,
  );
}
