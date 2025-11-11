import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/config/breez_config.dart';
import 'package:glow/core/providers/sdk_provider.dart';

/// Show bottom sheet for registering a new Lightning Address
Future<void> showRegisterLightningAddressSheet(BuildContext context, WidgetRef ref, BreezSdk sdk) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (bottomSheetContext) => RegisterLightningAddressSheet(
      sdk: sdk,
      onSuccess: () {
        ref.invalidate(lightningAddressProvider(true));
        if (context.mounted) {
          Navigator.of(bottomSheetContext).pop();
        }
      },
    ),
  );
}

/// Bottom sheet for registering a new Lightning Address
class RegisterLightningAddressSheet extends StatefulWidget {
  final BreezSdk sdk;
  final VoidCallback onSuccess;

  const RegisterLightningAddressSheet({super.key, required this.sdk, required this.onSuccess});

  @override
  State<RegisterLightningAddressSheet> createState() => _RegisterLightningAddressSheetState();
}

class _RegisterLightningAddressSheetState extends State<RegisterLightningAddressSheet> {
  final _controller = TextEditingController();
  String? _errorText;
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final value = _controller.text.trim().toLowerCase().replaceAll(' ', '');

    if (value.isEmpty) {
      setState(() => _errorText = 'Username cannot be empty');
      return;
    }

    final cleaned = value.replaceAll(RegExp(r'^\.+|\.+$'), '');

    setState(() {
      _isProcessing = true;
      _errorText = null;
    });

    try {
      final available = await widget.sdk.checkLightningAddressAvailable(
        request: CheckLightningAddressRequest(username: cleaned),
      );

      if (!available) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _errorText = 'Username not available';
          });
        }
        return;
      }
      log.i('Registering Lightning Address for username: $cleaned');
      await widget.sdk.registerLightningAddress(request: RegisterLightningAddressRequest(username: cleaned));

      if (mounted) {
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lightning Address registered: $value@${BreezConfig.lnurlDomain}')),
        );
      }
    } catch (e) {
      log.e('Error registering Lightning Address. ', error: e);
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorText = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Register Lightning Address', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Choose a username for your Lightning Address',
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_isProcessing,
            decoration: InputDecoration(
              labelText: 'Username',
              errorText: _errorText,
              suffixText: '@${BreezConfig.lnurlDomain}',
              suffixStyle: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _errorText = null),
            onSubmitted: (_) => _handleRegister(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isProcessing ? null : _handleRegister,
            child: _isProcessing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Register'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
