import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/logging/logger_mixin.dart';
import 'package:glow/core/models/wallet_metadata.dart';
import 'package:glow/core/providers/wallet_provider.dart';
import 'package:glow/features/widgets/bottom_nav_button.dart';

class PhraseVerificationScreen extends ConsumerStatefulWidget {
  final WalletMetadata wallet;
  final String mnemonic;
  const PhraseVerificationScreen({required this.wallet, required this.mnemonic, super.key});

  @override
  ConsumerState<PhraseVerificationScreen> createState() => _PhraseVerificationScreenState();
}

class _PhraseVerificationScreenState extends ConsumerState<PhraseVerificationScreen> with LoggerMixin {
  late final List<String> words;
  late final List<int> indices;
  final List<TextEditingController> controllers = List<TextEditingController>.generate(
    3,
    (_) => TextEditingController(),
  );
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    words = widget.mnemonic.split(' ');
    final Random rand = Random();
    final Set<int> idxs = <int>{};
    while (idxs.length < 3) {
      idxs.add(rand.nextInt(words.length));
    }
    indices = idxs.toList()..sort();
  }

  @override
  void dispose() {
    for (final TextEditingController c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _isVerifying = true);
    try {
      bool valid = true;
      for (int i = 0; i < 3; i++) {
        if (controllers[i].text.trim() != words[indices[i]]) {
          valid = false;
          break;
        }
      }
      if (!valid) {
        setState(() => _isVerifying = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect words. Please try again.'), backgroundColor: Colors.red),
          );
        }
        return;
      }
      await ref.read(walletListProvider.notifier).markWalletAsVerified(widget.wallet.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recovery phrase verified!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      log.e('Failed to verify wallet', error: e);
      setState(() => _isVerifying = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Let's verify")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Form(
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < 3; i++) ...<Widget>[
                    TextFormField(
                      controller: controllers[i],
                      decoration: InputDecoration(label: Text('${indices[i] + 1}')),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                padding: EdgeInsets.zero,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  width: MediaQuery.of(context).size.width,
                  child: Text(
                    'Please type words number ${indices[0] + 1}, ${indices[1] + 1} and ${indices[2] + 1} of the generated backup phrase.',
                    style: const TextStyle(
                      color: Color(0xccffffff),
                      fontSize: 14.3,
                      letterSpacing: 0.4,
                      height: 1.16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavButton(text: 'VERIFY', loading: _isVerifying, onPressed: _verify),
    );
  }
}
