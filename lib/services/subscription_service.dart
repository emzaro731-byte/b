import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> isPremium() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    final row = await _supabase.from('subscriptions')
        .select('status, plan, current_period_end')
        .eq('user_id', user.id).eq('status', 'active').eq('plan', 'premium')
        .maybeSingle();
    if (row == null) return false;
    final end = row['current_period_end'];
    if (end != null) {
      final expiry = DateTime.tryParse(end.toString());
      if (expiry != null && expiry.isBefore(DateTime.now().toUtc())) return false;
    }
    return true;
  }
}
