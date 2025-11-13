import 'package:flutter/material.dart';

class SendForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String errorMessage;
  final ValueChanged<String> onSubmit;

  const SendForm({
    required this.formKey,
    required this.controller,
    required this.focusNode,
    required this.errorMessage,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: 'Invoice | Lightning Address | BTC Address | LNURL',
          helperText: 'Paste or scan payee information',
          errorText: errorMessage.isNotEmpty ? errorMessage : null,
        ),
        maxLines: 3,
        onFieldSubmitted: onSubmit,
      ),
    );
  }
}
