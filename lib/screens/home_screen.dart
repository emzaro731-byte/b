import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import 'media_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _messages = <Map<String, dynamic>>[];
  final _ai = AiService();
  final List<PlatformFile> _attachments = [];
  bool _busy = false;

  Future<void> _pickFiles() async {
    if (_busy) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      const maxFiles = 10;
      final selected = result.files.take(maxFiles).toList();
      setState(() {
        for (final file in selected) {
          if (!_attachments.any((item) => item.name == file.name && item.size == file.size)) {
            _attachments.add(file);
          }
        }
      });

      if (result.files.length > maxFiles) {
        _show('You can attach up to $maxFiles files at once.');
      }
    } catch (_) {
      _show('Could not select the files.');
    }
  }

  void _removeAttachment(int index) {
    setState(() => _attachments.removeAt(index));
  }

  List<Map<String, dynamic>> _attachmentPayloads() {
    return _attachments.map((file) {
      final bytes = file.bytes;
      final mime = _mimeFor(file.extension);
      return <String, dynamic>{
        'name': file.name,
        'size': file.size,
        'mimeType': mime,
        if (bytes != null && mime.startsWith('image/'))
          'data': 'data:$mime;base64,${base64Encode(bytes)}',
      };
    }).toList();
  }

  String _mimeFor(String? extension) {
    switch ((extension ?? '').toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      case 'csv':
        return 'text/csv';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if ((text.isEmpty && _attachments.isEmpty) || _busy) return;

    final payloads = _attachmentPayloads();
    final names = _attachments.map((file) => file.name).toList();
    final displayText = text.isEmpty ? 'Please analyze the attached files.' : text;

    setState(() {
      _messages.add({
        'role': 'user',
        'text': displayText,
        'attachments': names,
      });
      _busy = true;
    });
    _controller.clear();
    setState(() => _attachments.clear());

    try {
      final reply = await _ai.chat(displayText, attachments: payloads);
      if (mounted) {
        setState(() => _messages.add({'role': 'assistant', 'text': reply}));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages.add({'role': 'assistant', 'text': 'AI request failed: $e'}));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openStudio() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MediaScreen()));
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _attachmentPreview(List<dynamic> names) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: names.map((name) => Chip(
          avatar: const Icon(Icons.attach_file, size: 16),
          label: Text(name.toString(), overflow: TextOverflow.ellipsis),
          visualDensity: VisualDensity.compact,
        )).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veylola AI', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _openStudio, tooltip: 'AI Studio', icon: const Icon(Icons.auto_awesome)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 64),
                        const SizedBox(height: 12),
                        const Text('Ask Veylola anything', style: TextStyle(fontSize: 20)),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(onPressed: _openStudio, icon: const Icon(Icons.movie_creation_outlined), label: const Text('Open AI Studio')),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      final user = m['role'] == 'user';
                      final names = (m['attachments'] as List?) ?? const [];
                      return Align(
                        alignment: user ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 340),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: user ? Theme.of(context).colorScheme.primaryContainer : const Color(0xFF0A0A0A),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (names.isNotEmpty) _attachmentPreview(names),
                              Text(m['text']?.toString() ?? ''),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_attachments.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(_attachments.length, (index) {
                  final file = _attachments[index];
                  return InputChip(
                    avatar: const Icon(Icons.insert_drive_file, size: 17),
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: Text(file.name, overflow: TextOverflow.ellipsis),
                    ),
                    onDeleted: () => _removeAttachment(index),
                  );
                }),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _busy ? null : _pickFiles,
                    tooltip: 'Attach files',
                    icon: const Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Message Veylola...',
                        filled: true,
                        fillColor: const Color(0xFF111111),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _busy ? null : _send,
                    icon: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
