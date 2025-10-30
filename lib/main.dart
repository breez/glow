import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/providers/wallet_provider.dart';
import 'package:glow/screens/home_screen.dart';
import 'package:glow/screens/wallet/setup_screen.dart';
import 'package:glow/services/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logging/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BreezSdkSparkLib.init();
  await AppLogger.initialize();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [configServiceProvider.overrideWithValue(ConfigService(prefs))],
      child: const MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Glow',
      // Use named routes for proper navigation
      initialRoute: '/',
      routes: {'/': (context) => const _AppRouter()},
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF0085fb),
          surface: const Color(0xFFf9f9f9),
          surfaceContainerLow: const Color(0xFFf9f9f9),
          brightness: Brightness.light,
          dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(height: 60, elevation: 0, color: Color(0xFF0085fb)),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00091c),
          surface: Color.fromRGBO(10, 20, 40, 1),
          surfaceContainerLow: Color.fromRGBO(10, 20, 40, 1.33),
          brightness: Brightness.dark,
          dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00091c),
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        scaffoldBackgroundColor: const Color(0xFF00091c),
        bottomAppBarTheme: const BottomAppBarThemeData(height: 60, elevation: 0, color: Color(0xFF0085fb)),
      ),
      themeMode: ThemeMode.dark,
    );
  }
}

/// Internal router that handles wallet state-based navigation
///
/// This widget watches wallet state and routes accordingly:
/// - No wallets → WalletSetupScreen (create or import)
/// - Has active wallet → WalletScreen (main app)
/// - Loading → Loading indicator
class _AppRouter extends ConsumerWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasWalletsAsync = ref.watch(hasWalletsProvider);
    final activeWallet = ref.watch(activeWalletProvider);

    // Show loading while checking if wallets exist
    if (hasWalletsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Error loading wallet list
    if (hasWalletsAsync.hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('Failed to load wallets', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  hasWalletsAsync.error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(walletListProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hasWallets = hasWalletsAsync.value ?? false;

    // No wallets exist - show setup screen
    if (!hasWallets) {
      return const WalletSetupScreen();
    }

    // Wallet loading
    if (activeWallet.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Wallet load error
    if (activeWallet.hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('Failed to load wallet', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  activeWallet.error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(activeWalletProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Has active wallet - show main app
    if (activeWallet.hasValue && activeWallet.value != null) {
      return const HomeScreen();
    }

    // Fallback: No active wallet but wallets exist - shouldn't happen
    return const WalletSetupScreen();
  }
}
