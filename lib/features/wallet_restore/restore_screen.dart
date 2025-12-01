import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/constants/wordlist.dart';
import 'package:glow/logging/logger_mixin.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:glow/features/wallet_restore/models/restore_state.dart';
import 'package:glow/features/wallet_restore/providers/restore_provider.dart';
import 'package:glow/features/wallet_restore/restore_layout.dart';
import 'package:glow/routing/app_routes.dart';

class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> with LoggerMixin {
  final List<TextEditingController> _mnemonicControllers = List<TextEditingController>.generate(
    12,
    (int _) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List<FocusNode>.generate(12, (int _) => FocusNode());
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Network _selectedNetwork = Network.mainnet;

  @override
  void initState() {
    super.initState();
    // Reset state when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Invalidate provider to get fresh state
      ref.invalidate(restoreWalletProvider);
    });
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _mnemonicControllers) {
      controller.dispose();
    }
    for (final FocusNode node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getMnemonic() {
    return _mnemonicControllers
        .map((TextEditingController c) => c.text.trim())
        .where((String t) => t.isNotEmpty)
        .join(' ');
  }

  void _validateMnemonic() {
    final String mnemonic = _getMnemonic();
    ref.read(restoreWalletProvider.notifier).validateMnemonic(mnemonic);
  }

  List<String> _getSuggestions(String query) {
    if (query.isEmpty) {
      return <String>[];
    }
    return bip39WordList.where((String word) => word.startsWith(query.toLowerCase())).take(5).toList();
  }

  void _onWordSelected(int index, String selection) {
    _validateMnemonic();
  }

  Future<void> _restoreWallet() async {
    final String mnemonic = _getMnemonic();

    final WalletMetadata? wallet = await ref
        .read(restoreWalletProvider.notifier)
        .restoreWallet(mnemonic, _selectedNetwork);

    if (!mounted) {
      return;
    }

    if (wallet != null) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeScreen, (_) => false);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) {
      return;
    }

    final List<String> words = data!.text!.trim().split(RegExp(r'\s+'));
    if (words.length == 12) {
      for (int i = 0; i < 12; i++) {
        _mnemonicControllers[i].text = words[i];
      }
      _validateMnemonic();
    }
  }

  @override
  Widget build(BuildContext context) {
    final RestoreState state = ref.watch(restoreWalletProvider);

    return RestoreLayout(
      formKey: _formKey,
      mnemonicControllers: _mnemonicControllers,
      focusNodes: _focusNodes,
      getSuggestions: _getSuggestions,
      mnemonicError: state.mnemonicError,
      isRestoring: state.isLoading,
      onWordSelected: _onWordSelected,
      onPaste: _pasteFromClipboard,
      onRestore: _restoreWallet,
    );
  }
}
