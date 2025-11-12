import 'package:glow/features/home/widgets/balance/theme/balance_text_styles.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';

class BalanceDisplayShimmer extends StatelessWidget {
  const BalanceDisplayShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: themeData.colorScheme.onSecondary,
      highlightColor: themeData.colorScheme.surface.withValues(alpha: .5),
      child: TextButton(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
            if (<WidgetState>{WidgetState.focused, WidgetState.hovered}.any(states.contains)) {
              return themeData.colorScheme.surface;
            }
            return null;
          }),
        ),
        onPressed: () {},
        child: RichText(
          text: TextSpan(
            style: BalanceTextStyles.amount,
            text: 0.toString(),
            children: <InlineSpan>[const TextSpan(text: ' sats', style: BalanceTextStyles.unit)],
          ),
        ),
      ),
    );
  }
}
