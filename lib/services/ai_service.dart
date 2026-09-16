import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class AiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> chat(String message, {String? imageData}) async {
    final response = await _supabase.functions.invoke(
      'veylola-ai',
      body: {
        'type': 'chat',
        'prompt': message,
        if (imageData != null) 'imageData': imageData,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['error'] != null) throw Exception(data['error'].toString());
    return (data['reply'] ?? data['message'] ?? '').toString();
  }

  Future<Map<String, dynamic>> generateMedia({
    required String type,
    required String prompt,
    Map<String, dynamic> options = const {},
  }) async {
    final response = await _supabase.functions.invoke(
      'veylola-ai',
      body: {'type': type, 'prompt': prompt, 'options': options},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['error'] != null) throw Exception(data['error'].toString());
    return data;
  }

  Future<Map<String, dynamic>> getMediaStatus({
    required String type,
    required String taskId,
  }) async {
    final response = await _supabase.functions.invoke(
      'veylola-ai',
      body: {'type': 'status', 'taskId': taskId, 'mediaType': type},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['error'] != null) throw Exception(data['error'].toString());
    return data;
  }

  Future<Map<String, dynamic>> waitForMedia({
    required String type,
    required String taskId,
    Duration interval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 15),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final result = await getMediaStatus(type: type, taskId: taskId);
      final data = Map<String, dynamic>.from(result['data'] is Map ? result['data'] : result);
      final state = (data['state'] ?? data['status'] ?? '').toString().toLowerCase();
      final success = state == 'success' || state == 'complete' || state == 'first_success';
      final failed = state == 'fail' || state == 'failed' || state.contains('failed') || state.contains('error');
      if (success || failed) return result;
      await Future<void>.delayed(interval);
    }
    throw TimeoutException('Veylola AI generation timed out.');
  }

  List<String> extractResultUrls(Map<String, dynamic> result) {
    final urls = <String>[];
    void scan(dynamic value) {
      if (value is String && (value.startsWith('http://') || value.startsWith('https://'))) {
        if (!urls.contains(value)) urls.add(value);
      } else if (value is Map) {
        for (final entry in value.entries) scan(entry.value);
      } else if (value is List) {
        for (final item in value) scan(item);
      }
    }
    scan(result);
    return urls;
  }
}
