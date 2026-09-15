import 'package:cloud_functions/cloud_functions.dart';

class AiService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<String> chat(String message) async {
    final callable = _functions.httpsCallable('chat');
    final result = await callable.call({'message': message});
    final data = Map<String, dynamic>.from(result.data as Map);
    return (data['reply'] ?? '').toString();
  }

  Future<Map<String, dynamic>> generateMedia({
    required String type,
    required String prompt,
  }) async {
    final callable = _functions.httpsCallable('generateMedia');
    final result = await callable.call({'type': type, 'prompt': prompt});
    return Map<String, dynamic>.from(result.data as Map);
  }
}
