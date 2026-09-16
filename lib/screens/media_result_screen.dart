import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MediaResultScreen extends StatelessWidget {
  final String type;
  final String url;

  const MediaResultScreen({super.key, required this.type, required this.url});

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isImage = type == 'image';
    final isVideo = type == 'video';
    return Scaffold(
      appBar: AppBar(title: Text('${type[0].toUpperCase()}${type.substring(1)} Result')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: isImage
                    ? Image.network(url, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(child: Text('Image preview unavailable.')))
                    : isVideo
                        ? Center(child: Icon(Icons.video_library, size: 90, color: Theme.of(context).colorScheme.primary))
                        : Center(child: Icon(Icons.music_note, size: 90, color: Theme.of(context).colorScheme.primary)),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _open, icon: const Icon(Icons.open_in_new), label: const Text('Open / Download')),
          ],
        ),
      ),
    );
  }
}
