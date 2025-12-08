import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/config/breez_config.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/theme/colors.dart';

/// Show bottom sheet for editing Lightning Address
Future<void> showEditLightningAddressSheet(
  BuildContext context,
  WidgetRef ref,
  BreezSdk sdk,
  String address,
) {
  final String username = address.split('@').first;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext bottomSheetContext) => EditLightningAddressSheet(
      sdk: sdk,
      currentUsername: username,
      onSuccess: () {
        ref.invalidate(lightningAddressProvider(true));
        if (context.mounted) {
          Navigator.of(bottomSheetContext).pop();
        }
      },
      onDelete: () {
        ref.read(lightningAddressManuallyDeletedProvider.notifier).markAsDeleted();
        ref.invalidate(lightningAddressProvider(true));
        if (context.mounted) {
          Navigator.of(bottomSheetContext).pop();
        }
      },
    ),
  );
}

/// Bottom sheet for editing or deleting Lightning Address
class EditLightningAddressSheet extends StatefulWidget {
  final BreezSdk sdk;
  final String currentUsername;
  final VoidCallback onSuccess;
  final VoidCallback onDelete;

  const EditLightningAddressSheet({
    required this.sdk,
    required this.currentUsername,
    required this.onSuccess,
    required this.onDelete,
    super.key,
  });

  @override
  State<EditLightningAddressSheet> createState() => _EditLightningAddressSheetState();
}

class _EditLightningAddressSheetState extends State<EditLightningAddressSheet> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _isProcessing = false;
  bool _showDeleteConfirmation = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUsername);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final String value = _controller.text.trim().toLowerCase().replaceAll(' ', '');

    if (value == widget.currentUsername) {
      widget.onSuccess();
      return;
    }

    if (value.isEmpty) {
      setState(() => _errorText = 'Username cannot be empty');
      return;
    }

    final String cleaned = value.replaceAll(RegExp(r'^\.+|\.+$'), '');

    setState(() {
      _isProcessing = true;
      _errorText = null;
    });

    try {
      final bool available = await widget.sdk.checkLightningAddressAvailable(
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

      await widget.sdk.deleteLightningAddress();
      await widget.sdk.registerLightningAddress(request: RegisterLightningAddressRequest(username: cleaned));

      if (mounted) {
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lightning Address updated: $value@${BreezConfig.lnurlDomain}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorText = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    setState(() => _isProcessing = true);

    try {
      await widget.sdk.deleteLightningAddress();
      if (mounted) {
        widget.onDelete();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lightning Address deleted')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorText = 'Failed to delete: ${e.toString()}';
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
        children: <Widget>[
          if (!_showDeleteConfirmation) ...<Widget>[
            const Text(
              'Customize Address',
              style: TextStyle(fontSize: 18.0, letterSpacing: 0.0, height: 1.28, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
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
              onSubmitted: (_) => _handleSave(),
            ),
            const SizedBox(height: 40),
            FilledButton(
              onPressed: _isProcessing ? null : _handleSave,
              child: _isProcessing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                  : const Text('DONE'),
            ),
            if (kDebugMode) ...<Widget>[
              const SizedBox(height: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: BreezColors.debugRed),
                onPressed: _isProcessing ? null : () => setState(() => _showDeleteConfirmation = true),
                icon: const Icon(Icons.delete_outline),
                label: _isProcessing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                    : const Text('DELETE'),
              ),
            ],
          ] else ...<Widget>[
            Text('Delete Lightning Address?', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isProcessing ? null : _handleDelete,
              style: FilledButton.styleFrom(backgroundColor: BreezColors.debugRed),
              child: _isProcessing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                  : const Text('DELETE'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _isProcessing ? null : () => setState(() => _showDeleteConfirmation = false),
              child: const Text('CANCEL'),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
