import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/handlers/input_handlers.dart';
import 'package:glow/logging/app_logger.dart';

final log = AppLogger.getLogger('InputTextField');

/// A text field that can parse Lightning/Bitcoin payment requests
class InputTextField extends ConsumerStatefulWidget {
  final String? hintText;
  final VoidCallback? onScanPressed;

  const InputTextField({this.hintText, this.onScanPressed, super.key});

  @override
  ConsumerState<InputTextField> createState() => _InputTextFieldState();
}

class _InputTextFieldState extends ConsumerState<InputTextField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handlePaste() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
      final text = clipboardData.text!.trim();
      _controller.text = text;
      _handleSubmit(text);
    }
  }

  Future<void> _handleSubmit(String text) async {
    if (text.isEmpty) return;

    log.i('Handling input from text field');
    final inputHandler = ref.read(inputHandlerProvider);

    if (mounted) {
      await inputHandler.handleInput(context, text);
      // Clear text field after successful parse attempt
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'Enter text',
        prefixIcon: IconButton(
          icon: const Icon(Icons.content_paste),
          onPressed: _handlePaste,
          tooltip: 'Paste',
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onScanPressed != null)
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: widget.onScanPressed,
                tooltip: 'Scan QR code',
              ),
            IconButton(icon: const Icon(Icons.send), onPressed: () => _handleSubmit(_controller.text)),
          ],
        ),
        border: const OutlineInputBorder(),
      ),
      onSubmitted: _handleSubmit,
      textInputAction: TextInputAction.go,
    );
  }
}
