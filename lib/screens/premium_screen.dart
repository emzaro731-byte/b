import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/subscription_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});
  @override State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _subscriptions = SubscriptionService();
  bool _loading = true;
  bool _premium = false;
  static const _selarCheckoutUrl = 'https://selar.com/84z189877t';

  @override void initState() { super.initState(); _refresh(); }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final value = await _subscriptions.isPremium();
      if (mounted) setState(() => _premium = value);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _subscribe() async {
    final uri = Uri.tryParse(_selarCheckoutUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selar checkout link is invalid.')),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Veylola Premium')),
    body: Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: _loading ? const CircularProgressIndicator() : _premium
        ? Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.workspace_premium, size: 80),
            const SizedBox(height: 16),
            const Text('Premium is active', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Your Veylola Premium access is enabled.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton(onPressed: _refresh, child: const Text('Refresh subscription')),
          ])
        : Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.workspace_premium, size: 80),
            const SizedBox(height: 16),
            const Text('Upgrade to Premium', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Subscribe through Selar to unlock Premium features.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: _subscribe, child: const Text('Subscribe with Selar'))),
            const SizedBox(height: 10),
            TextButton(onPressed: _refresh, child: const Text('I already paid — check again')),
          ]),
    )),
  );
}
