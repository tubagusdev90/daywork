
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// SUPABASE AUTH SERVICE
// ==========================================

class AuthProvider {
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
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // GET CURRENT USER
  User? get currentUser {
    return _supabase.auth.currentUser;
  }

  // GET CURRENT SESSION
  Session? get currentSession {
    return _supabase.auth.currentSession;
  }

  // CHECK LOGIN STATUS
  bool get isLoggedIn {
    return _supabase.auth.currentSession != null;
  }

  // AUTH STATE CHANGES
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }
}

// ==========================================
// RIVERPOD PROVIDER
// ==========================================

final authProvider = Provider<AuthProvider>((ref) {
  return AuthProvider();
});
