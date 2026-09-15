import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <Map<String, String>>[];
  final _ai = AiService();
  bool _busy = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _busy = true;
    });
    _controller.clear();
    try {
      final reply = await _ai.chat(text);
      if (mounted) setState(() => _messages.add({'role': 'assistant', 'text': reply}));
    } catch (e) {
      if (mounted) setState(() => _messages.add({'role': 'assistant', 'text': 'I could not complete that request yet. Connect the Veylola AI Cloud Function and try again.'}));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veylola AI', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Ask Veylola anything', style: TextStyle(fontSize: 20)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      final user = m['role'] == 'user';
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
                          child: Text(m['text'] ?? ''),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
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
                    icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_upward),
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
