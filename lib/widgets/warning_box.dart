import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';
import 'package:glow/theme/dark_theme.dart';

class WarningBox extends StatelessWidget {
  const WarningBox({
    required this.child,
    super.key,
    this.boxPadding = EdgeInsets.zero,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    this.backgroundColor,
    this.borderColor,
  });

  /// Factory constructor for simple text-only warning messages.
  factory WarningBox.text({
    required String message,
    Key? key,
    EdgeInsets boxPadding = EdgeInsets.zero,
    EdgeInsets contentPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    Color? backgroundColor,
    Color? borderColor,
    Color? textColor,
    TextStyle? textStyle,
  }) {
    return WarningBox(
      key: key,
      boxPadding: boxPadding,
      contentPadding: contentPadding,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      child: _WarningBoxText(message: message, textColor: textColor, textStyle: textStyle),
    );
  }

  final EdgeInsets boxPadding;
  final EdgeInsets contentPadding;
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final WarningBoxTheme? warningBoxTheme = Theme.of(context).extension<WarningBoxTheme>();
    final Color effectiveBackgroundColor =
        backgroundColor ??
        warningBoxTheme?.backgroundColor ??
        Theme.of(context).colorScheme.error.withAlpha(25);
    final Color effectiveBorderColor =
        borderColor ?? warningBoxTheme?.borderColor ?? Theme.of(context).colorScheme.error;

    return Padding(
      padding: boxPadding,
      child: Container(
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Container(
          padding: contentPadding,
          width: MediaQuery.of(context).size.width,
          decoration: DottedDecoration(
            shape: Shape.box,
            dash: const <int>[3, 2],
            color: effectiveBorderColor,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _WarningBoxText extends StatelessWidget {
  const _WarningBoxText({required this.message, this.textColor, this.textStyle});

  final String message;
  final Color? textColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final WarningBoxTheme? warningBoxTheme = Theme.of(context).extension<WarningBoxTheme>();
    final Color effectiveTextColor =
        textColor ?? warningBoxTheme?.textColor ?? Theme.of(context).colorScheme.error;
    return Text(
      message,
      style:
          textStyle?.copyWith(color: effectiveTextColor) ??
          TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
            height: 1.182,
            color: effectiveTextColor,
          ),
    );
  }
}
