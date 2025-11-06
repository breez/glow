// TODO(erdemyerebasmaz): Apply SoC principles w/ feature-first architecture to wallet feature
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/providers/theme_provider.dart';
import 'package:glow/features/wallet/widgets/animated_logo.dart';
import 'package:glow/features/wallet/widgets/breez_sdk_footer.dart';
import 'package:glow/features/wallet/widgets/setup_actions.dart';

class WalletSetupScreen extends ConsumerStatefulWidget {
  const WalletSetupScreen({super.key});

  @override
  WalletSetupScreenState createState() => WalletSetupScreenState();
}

class WalletSetupScreenState extends ConsumerState<WalletSetupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: <Widget>[
              Spacer(flex: 3),
              AnimatedLogo(),
              Spacer(flex: 3),
              SetupActions(),
              Spacer(),
              BreezSdkFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
