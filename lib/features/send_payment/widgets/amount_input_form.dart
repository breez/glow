import 'package:flutter/material.dart';
import 'package:glow/features/send_payment/widgets/amount_input_card.dart';
import 'package:glow/widgets/card_wrapper.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class AmountInputForm extends StatefulWidget {
  final TextEditingController controller;
  final GlobalKey<FormState> formKey;
  final FocusNode? focusNode;
  final BigInt? minAmount;
  final BigInt? maxAmount;
  final String? Function(String?)? validator;
  final Widget? header;
  final bool showUseAllFunds;
  final void Function(BigInt)? onPaymentLimitTapped;

  const AmountInputForm({
    required this.controller,
    required this.formKey,
    this.focusNode,
    this.minAmount,
    this.maxAmount,
    this.validator,
    this.header,
    this.showUseAllFunds = true,
    this.onPaymentLimitTapped,
    super.key,
  });

  @override
  State<AmountInputForm> createState() => _AmountInputFormState();
}

class _AmountInputFormState extends State<AmountInputForm> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardActions(
      tapOutsideBehavior: TapOutsideBehavior.translucentDismiss,
      disableScroll: true,
      config: KeyboardActionsConfig(
        keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
        keyboardBarColor: Theme.of(context).colorScheme.surfaceContainer,
        actions: <KeyboardActionsItem>[
          KeyboardActionsItem(
            focusNode: _focusNode,
            toolbarButtons: <ButtonBuilder>[
              (FocusNode node) {
                return TextButton(
                  style: TextButton.styleFrom(padding: const EdgeInsets.only(right: 16.0)),
                  onPressed: () {
                    node.unfocus();
                  },
                  child: const Text('DONE', style: TextStyle(color: Colors.white)),
                );
              },
            ],
          ),
        ],
      ),
      child: Form(
        key: widget.formKey,
        child: CardWrapper(
          padding: widget.header != null
              ? const EdgeInsets.symmetric(vertical: 32, horizontal: 24)
              : const EdgeInsets.all(0),
          child: widget.header != null ? _buildContentWithHeader() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AmountInputCard(
      controller: widget.controller,
      focusNode: _focusNode,
      minAmount: widget.minAmount,
      maxAmount: widget.maxAmount,
      showUseAllFunds: widget.showUseAllFunds,
      validator: widget.validator,
      onPaymentLimitTapped: widget.onPaymentLimitTapped,
    );
  }

  Widget _buildContentWithHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        widget.header!,
        const Divider(height: 32.0, color: Color.fromRGBO(40, 59, 74, 0.5), indent: 0.0, endIndent: 0.0),
        _buildContent(),
      ],
    );
  }
}
