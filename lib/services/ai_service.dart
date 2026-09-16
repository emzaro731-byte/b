import 'package:supabase_flutter/supabase_flutter.dart';

class AiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> chat(String message) async {
    final response = await _supabase.functions.invoke(
      'veylola-ai',
      body: {
        'type': 'chat',
        'prompt': message,
      },
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    return (data['reply'] ?? data['message'] ?? '').toString();
  }

  Future<Map<String, dynamic>> generateMedia({
    required String type,
    required String prompt,
    Map<String, dynamic> options = const {},
  }) async {
    final response = await _supabase.functions.invoke(
      'veylola-ai',
      body: {
        'type': type,
        'prompt': prompt,
        'options': options,
      },
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    return data;
  }
}
