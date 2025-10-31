import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/screens/developers_screen.dart';
import 'package:glow/screens/home/qr_scan_view.dart';
import 'package:glow/screens/payment_details_screen.dart';
import 'package:glow/screens/receive/receive_screen.dart';
import 'package:glow/screens/send/send_screen.dart';
import 'package:glow/screens/unclaimed_deposits_screen.dart';
import 'package:glow/screens/wallet/create_screen.dart';
import 'package:glow/screens/wallet/import_screen.dart';
import 'package:glow/screens/wallet/list_screen.dart';
import 'package:glow/screens/wallet/setup_screen.dart';
import 'package:glow/screens/wallet/verify_screen.dart';

// Import your payment screens here when they're created
// import 'package:glow/screens/send/bitcoin_address_screen.dart';
// import 'package:glow/screens/send/bolt11_screen.dart';
// etc.

/// Handles navigation for payment flows and feature screens
///
/// This works alongside _AppRouter which handles initial wallet-state-based routing.
/// _AppRouter determines if user sees WalletSetupScreen or HomeScreen.
/// AppRoutes handles navigation WITHIN the app (QR scan, payments, settings, etc.)
class AppRoutes {
  // Core routes
  static const String homeScreen = '/';
  static const String qrScan = '/qr_scan';

  // Payment routes
  static const String paymentDetails = '/payment/details';

  // Wallet routes
  static const String walletSetup = '/wallet/setup';
  static const String walletCreate = '/wallet/create';
  static const String walletImport = '/wallet/import';
  static const String walletList = '/wallet/list';
  static const String walletVerify = '/wallet/verify';

  // Send payment routes
  static const String sendScreen = '/send';
  static const String sendBitcoinAddress = '/send/bitcoin_address';
  static const String sendBolt11 = '/send/bolt11';
  static const String sendBolt12Invoice = '/send/bolt12_invoice';
  static const String sendBolt12Offer = '/send/bolt12_offer';
  static const String sendLightningAddress = '/send/lightning_address';
  static const String sendLnurlPay = '/send/lnurl_pay';
  static const String sendSilentPayment = '/send/silent_payment';
  static const String sendBip21 = '/send/bip21';
  static const String sendBolt12InvoiceRequest = '/send/bolt12_invoice_request';
  static const String sendSparkAddress = '/send/spark_address';

  // Deposit claim routes
  static const String unclaimedDeposits = '/deposit/list';

  // Receive payment routes
  static const String receiveScreen = '/receive';
  static const String receiveLnurlWithdraw = '/receive/lnurl_withdraw';

  // Auth routes
  static const String lnurlAuth = '/lnurl_auth';

  // Settings routes
  static const String appSettings = '/settings';
  static const String walletSettings = '/settings/wallet';

  // Developers routes
  static const String developersScreen = '/developers';

  /// Generate routes for named navigation
  ///
  /// This is called by MaterialApp.onGenerateRoute when you use Navigator.pushNamed()
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // QR Scanner
      case qrScan:
        return MaterialPageRoute<String>(builder: (_) => const QRScanView());

      // Payment details
      case paymentDetails:
        final args = settings.arguments as Payment;
        return MaterialPageRoute(
          builder: (_) => PaymentDetailsScreen(payment: args),
          settings: settings,
        );

      // Wallet routes
      case walletSetup:
        return MaterialPageRoute<String>(builder: (_) => const WalletSetupScreen());

      case walletCreate:
        return MaterialPageRoute<String>(builder: (_) => const WalletCreateScreen());

      case walletImport:
        return MaterialPageRoute<String>(builder: (_) => const WalletImportScreen());

      case walletList:
        return MaterialPageRoute<String>(builder: (_) => const WalletListScreen());

      case walletVerify:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => WalletVerifyScreen(wallet: args['wallet'], mnemonic: args['mnemonic']),
          settings: settings,
        );

      // Send payment routes
      case AppRoutes.sendScreen:
        return MaterialPageRoute(builder: (_) => const SendScreen(), settings: settings);

      case sendBitcoinAddress:
        final args = settings.arguments as BitcoinAddressDetails;
        return MaterialPageRoute(
          builder: (_) => _PaymentScreenPlaceholder(title: 'Bitcoin Address Payment', subtitle: args.address),
          settings: settings,
        );

      case sendBolt11:
        final args = settings.arguments as Bolt11InvoiceDetails;
        return MaterialPageRoute(
          builder: (_) => _PaymentScreenPlaceholder(
            title: 'BOLT11 Invoice',
            subtitle:
                'Amount: ${args.amountMsat != null ? '${((args.amountMsat!) ~/ BigInt.from(1000))} sats' : 'Any amount'}',
          ),
          settings: settings,
        );

      case sendBolt12Invoice:
        final args = settings.arguments as Bolt12InvoiceDetails;
        return MaterialPageRoute(
          builder: (_) => _PaymentScreenPlaceholder(
            title: 'BOLT12 Invoice',
            subtitle: 'Amount: ${((args.amountMsat) ~/ BigInt.from(1000))} sats',
          ),
          settings: settings,
        );

      case sendBolt12Offer:
        final args = settings.arguments as Bolt12OfferDetails;
        return MaterialPageRoute(
          builder: (_) => _PaymentScreenPlaceholder(
            title: 'BOLT12 Offer',
            subtitle: args.description ?? 'No description',
          ),
          settings: settings,
        );

      case sendLightningAddress:
        final args = settings.arguments as LightningAddressDetails;
        return MaterialPageRoute(
          builder: (_) => _PaymentScreenPlaceholder(title: 'Lightning Address', subtitle: args.address),
          settings: settings,
        );

      case sendLnurlPay:
        final args = settings.arguments as LnurlPayRequestDetails;
        return MaterialPageRoute(
          builder: (_) => _PaymentScreenPlaceholder(title: 'LNURL-Pay', subtitle: args.domain),
          settings: settings,
        );

      case sendSilentPayment:
        final args = settings.arguments as SilentPaymentAddressDetails;
        return MaterialPageRoute(
          builder: (_) => _PaymentScreenPlaceholder(title: 'Silent Payment', subtitle: args.address),
          settings: settings,
        );

      case sendBip21:
        final args = settings.arguments as Bip21Details;
        return MaterialPageRoute(
          builder: (_) => _PaymentScreenPlaceholder(
            title: 'BIP21 Payment',
            subtitle: '${args.paymentMethods.length} payment methods available',
          ),
          settings: settings,
        );

      case sendBolt12InvoiceRequest:
        final args = settings.arguments as Bolt12InvoiceRequestDetails;
        return MaterialPageRoute(
          builder: (_) => _PaymentScreenPlaceholder(
            title: 'BOLT12 Invoice Request',
            subtitle: 'Creating invoice... $args',
          ),
          settings: settings,
        );

      case sendSparkAddress:
        final args = settings.arguments as SparkAddressDetails;
        return MaterialPageRoute(
          builder: (_) => _PaymentScreenPlaceholder(title: 'Spark Address Payment', subtitle: args.address),
          settings: settings,
        );

      // Deposit claim routes
      case AppRoutes.unclaimedDeposits:
        return MaterialPageRoute(builder: (_) => const UnclaimedDepositsScreen(), settings: settings);

      // Receive routes
      case receiveLnurlWithdraw:
        final args = settings.arguments as LnurlWithdrawRequestDetails;
        return MaterialPageRoute(
          builder: (_) => _PaymentScreenPlaceholder(
            title: 'LNURL Withdraw',
            subtitle: 'Receive from ${args.defaultDescription}',
          ),
          settings: settings,
        );

      case AppRoutes.receiveScreen:
        return MaterialPageRoute(builder: (_) => const ReceiveScreen(), settings: settings);

      // Auth routes
      case lnurlAuth:
        final args = settings.arguments as LnurlAuthRequestDetails;
        return MaterialPageRoute(
          builder: (_) => _PaymentScreenPlaceholder(title: 'LNURL Auth', subtitle: 'Login to ${args.domain}'),
          settings: settings,
        );

      // App Settings routes
      case appSettings:
        return MaterialPageRoute(
          builder: (_) => _PaymentScreenPlaceholder(title: 'Settings', subtitle: 'App configuration'),
          settings: settings,
        );

      case walletSettings:
        return MaterialPageRoute(
          builder: (_) => _PaymentScreenPlaceholder(title: 'Wallet Settings', subtitle: 'Manage your wallet'),
          settings: settings,
        );

      // Developers routes
      case developersScreen:
        return MaterialPageRoute(builder: (_) => const DevelopersScreen(), settings: settings);

      default:
        // Route not found
        return MaterialPageRoute(
          builder: (_) => _RouteNotFoundScreen(settings.name ?? 'unknown'),
          settings: settings,
        );
    }
  }
}

/// Placeholder screen for payment flows that haven't been implemented yet
class _PaymentScreenPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PaymentScreenPlaceholder({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('Coming Soon', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              Text(
                'This payment screen is being built.\nThe routing system is ready!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen shown when route is not found
class _RouteNotFoundScreen extends StatelessWidget {
  final String routeName;

  const _RouteNotFoundScreen(this.routeName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Not Found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Route Not Found', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'No route defined for: $routeName',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
