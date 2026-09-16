import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  final _prompt = TextEditingController();
  final _ai = AiService();
  String _type = 'image';
  bool _loading = false;
  String? _result;

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    try {
      final data = await _ai.generateMedia(type: _type, prompt: prompt);
      final value = data['data'] ?? data['taskId'] ?? data['task_id'] ?? data['result'] ?? data;
      if (mounted) setState(() => _result = value.toString());
    } catch (e) {
      if (mounted) setState(() => _result = 'Generation failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Studio')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'image', label: Text('Image'), icon: Icon(Icons.image_outlined)),
              ButtonSegment(value: 'video', label: Text('Video'), icon: Icon(Icons.videocam_outlined)),
              ButtonSegment(value: 'music', label: Text('Music'), icon: Icon(Icons.music_note_outlined)),
            ],
            selected: {_type},
            onSelectionChanged: (v) => setState(() => _type = v.first),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _prompt,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Describe what you want to create',
              hintText: 'Example: A futuristic Nigerian city at night...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
              label: Text(_loading ? 'Generating...' : 'Generate ${_type[0].toUpperCase()}${_type.substring(1)}'),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            const Text('Generation response', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SelectableText(_result!),
          ],
        ],
      ),
    );
  }
}
