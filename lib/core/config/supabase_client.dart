
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gotrue/gotrue.dart';

class SupabaseClientProvider {
  static SupabaseClient get client =>
      Supabase.instance.client;

  static GoTrueClient get auth =>
      Supabase.instance.client.auth;
}
