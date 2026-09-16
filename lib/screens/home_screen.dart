import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final _picker = ImagePicker();
  bool _busy = false;
  String? _attachedImageData;

  Future<void> _pickImage() async {
    if (_busy) return;
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final mime = file.mimeType ?? 'image/jpeg';
      setState(() {
        _attachedImageData = 'data:$mime;base64,${base64Encode(bytes)}';
      });
    } catch (e) {
      _show('Could not select the image.');
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final image = _attachedImageData;
    if ((text.isEmpty && image == null) || _busy) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'text': text.isEmpty ? 'Analyze this image' : text,
        'image': image,
      });
      _busy = true;
      _attachedImageData = null;
    });
    _controller.clear();

    try {
      final reply = await _ai.chat(
        text.isEmpty ? 'Analyze this image and describe what you see.' : text,
        imageData: image,
      );
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

  Widget _messageImage(String data) {
    try {
      final comma = data.indexOf(',');
      final bytes = base64Decode(data.substring(comma + 1));
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(bytes, width: 230, height: 180, fit: BoxFit.cover),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
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
                      final image = m['image'] as String?;
                      return Align(
                        alignment: user ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 340),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: user ? Theme.of(context).colorScheme.primaryContainer : const Color(0xFF15151D),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (image != null) _messageImage(image),
                              Text(m['text']?.toString() ?? ''),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_attachedImageData != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(_attachedImageData!.split(',').last),
                        width: 74,
                        height: 74,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: () => setState(() => _attachedImageData = null),
                        icon: const CircleAvatar(radius: 12, child: Icon(Icons.close, size: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _busy ? null : _pickImage,
                    tooltip: 'Add image',
                    icon: const Icon(Icons.image_outlined),
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
                        fillColor: const Color(0xFF15151D),
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
