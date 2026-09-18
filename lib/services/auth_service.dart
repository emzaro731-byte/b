import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signInWithEmail(String email, String password) {
    return _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) {
    return _supabase.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> resetPassword(String email) {
    return _supabase.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() {
    return _supabase.auth.signOut();
  }
}
