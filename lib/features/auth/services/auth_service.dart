
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // LOGIN
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login gagal. Pengguna tidak ditemukan.');
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // CURRENT USER
  User? get currentUser => _supabase.auth.currentUser;

  // CHECK LOGIN
  bool get isLoggedIn =>
      _supabase.auth.currentSession != null;
}
