import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glow/routing/app_routes.dart';
import 'package:glow/core/providers/theme_provider.dart';
import 'package:glow/core/providers/wallet_provider.dart';
import 'package:glow/features/home/home_screen.dart';
import 'package:glow/features/wallet/setup_screen.dart';
import 'package:glow/core/services/config_service.dart';
import 'package:glow/core/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/logging/app_logger.dart';

Future<void> _precacheSvgImages() async {
  final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final List<String> assets = assetManifest.listAssets();

  final Iterable<String> svgPaths = assets.where((String path) => path.endsWith('.svg'));
  for (final String svgPath in svgPaths) {
    final SvgAssetLoader loader = SvgAssetLoader(svgPath);
    await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _precacheSvgImages();
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
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
    final themeMode = ref.watch(themeModeProvider);
    final ThemeData themeData = themeMode == ThemeMode.dark ? buildDarkTheme() : buildLightTheme();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeData.appBarTheme.systemOverlayStyle!,
      child: MaterialApp(
        title: 'Glow',
        initialRoute: AppRoutes.homeScreen,
        routes: {AppRoutes.homeScreen: (context) => const _AppRouter()},
        onGenerateRoute: AppRoutes.generateRoute,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: themeMode,
      ),
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
