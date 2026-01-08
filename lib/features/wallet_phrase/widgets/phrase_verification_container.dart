import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:glow/features/wallet_phrase/models/phrase_verification_form_state.dart';
import 'package:glow/features/wallet_phrase/providers/phrase_verification_provider.dart';
import 'package:glow/features/wallet_phrase/widgets/phrase_verification_view.dart';

class PhraseVerificationContainer extends ConsumerStatefulWidget {
  final WalletMetadata wallet;
  final String mnemonic;

  const PhraseVerificationContainer({required this.wallet, required this.mnemonic, super.key});

  @override
  ConsumerState<PhraseVerificationContainer> createState() => _PhraseVerificationContainerState();
}

class _PhraseVerificationContainerState extends ConsumerState<PhraseVerificationContainer> {
  final List<TextEditingController> _controllers = List<TextEditingController>.generate(
    3,
    (_) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    // Initialize the provider with the mnemonic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(phraseVerificationProvider.notifier).initialize(widget.mnemonic);
    });
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final List<String> providedWords = _controllers
        .map((TextEditingController c) => c.text)
        .toList();
    final bool success = await ref
        .read(phraseVerificationProvider.notifier)
        .verifyWords(providedWords, widget.wallet);

    if (!mounted) {
      return;
    }

    final String? errorMessage = ref.read(phraseVerificationProvider).errorMessage;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup phrase verified!'), backgroundColor: Colors.green),
      );
    } else if (errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final PhraseVerificationFormState state = ref.watch(phraseVerificationProvider);

    return PhraseVerificationView(
      wordIndices: state.wordIndices,
      controllers: _controllers,
      isVerifying: state.isVerifying,
      onVerify: _handleVerify,
    );
  }
}
