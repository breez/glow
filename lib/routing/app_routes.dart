import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/deposits/unclaimed_deposits_screen.dart';
import 'package:glow/features/developers/developers_screen.dart';
import 'package:glow/features/lnurl/screens/lnurl_auth_screen.dart';
import 'package:glow/features/lnurl/screens/lnurl_pay_screen.dart';
import 'package:glow/features/lnurl/screens/lnurl_withdraw_screen.dart';
import 'package:glow/features/payment_details/payment_details_screen.dart';
import 'package:glow/features/qr_scan/qr_scan_view.dart';
import 'package:glow/features/receive/receive_screen.dart';
import 'package:glow/features/send/send_screen.dart';
import 'package:glow/features/send_payment/screens/bip21_screen.dart';
import 'package:glow/features/send_payment/screens/bitcoin_address_screen.dart';
import 'package:glow/features/send_payment/screens/bolt12_invoice_request_screen.dart';
import 'package:glow/features/settings/providers/pin_provider.dart';
import 'package:glow/features/settings/security_backup_screen.dart';
import 'package:glow/features/settings/widgets/pin_lock_screen.dart';
import 'package:glow/features/settings/widgets/pin_setup_screen.dart';
import 'package:glow/features/wallet/create_screen.dart';
import 'package:glow/features/wallet/list_screen.dart';
import 'package:glow/features/wallet_onboarding/onboarding_screen.dart';
import 'package:glow/features/wallet_phrase/phrase_screen.dart';
import 'package:glow/widgets/bottom_nav_button.dart';
import 'package:glow/features/wallet_restore/restore_screen.dart';

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
  static const String walletPhrase = '/wallet/phrase';

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
  static const String sendSparkAddress = '/send/spark/address';
  static const String sendSparkInvoice = '/send/spark/invoice';

  // Deposit claim routes
  static const String unclaimedDeposits = '/deposit/list';

  // Receive payment routes
  static const String receiveScreen = '/receive';
  static const String receiveLnurlWithdraw = '/receive/lnurl_withdraw';

  // Auth routes
  static const String lnurlAuth = '/lnurl_auth';

  // Settings routes
  static const String appSettings = '/settings';
  static const String pinSetup = '/settings/pin_setup';

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
        final Payment args = settings.arguments as Payment;
        return MaterialPageRoute<PaymentDetailsScreen>(
          builder: (_) => PaymentDetailsScreen(payment: args),
          settings: settings,
        );

      // Wallet routes
      case walletSetup:
        return MaterialPageRoute<String>(builder: (_) => const WalletSetupScreen());

      case walletCreate:
        return MaterialPageRoute<String>(builder: (_) => const WalletCreateScreen());

      case walletImport:
        return MaterialPageRoute<String>(builder: (_) => const RestoreScreen());

      case walletList:
        return MaterialPageRoute<String>(builder: (_) => const WalletListScreen());

      case walletPhrase:
        final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute<PhraseScreen>(
          builder: (_) => PhraseScreen(wallet: args['wallet'], mnemonic: args['mnemonic']),
          settings: settings,
        );

      // Send payment routes
      case AppRoutes.sendScreen:
        return MaterialPageRoute<SendScreen>(builder: (_) => const SendScreen(), settings: settings);

      case sendBitcoinAddress:
        final BitcoinAddressDetails args = settings.arguments as BitcoinAddressDetails;
        return MaterialPageRoute<Widget>(
          builder: (_) => BitcoinAddressScreen(addressDetails: args),
          settings: settings,
        );

      case sendBolt11:
        final Bolt11InvoiceDetails args = settings.arguments as Bolt11InvoiceDetails;
        return MaterialPageRoute<_PlaceholderScreen>(
          builder: (_) => _PlaceholderScreen(
            title: 'BOLT11 Invoice',
            content: _Bolt11Widget(details: args),
          ),
          settings: settings,
        );

      case sendBolt12Invoice:
        final Bolt12InvoiceDetails args = settings.arguments as Bolt12InvoiceDetails;
        return MaterialPageRoute<_PlaceholderScreen>(
          builder: (_) => _PlaceholderScreen(
            title: 'BOLT12 Invoice',
            content: _Bolt12InvoiceWidget(details: args),
          ),
          settings: settings,
        );

      case sendBolt12Offer:
        final Bolt12OfferDetails args = settings.arguments as Bolt12OfferDetails;
        return MaterialPageRoute<_PlaceholderScreen>(
          builder: (_) => _PlaceholderScreen(
            title: 'BOLT12 Offer',
            content: _Bolt12OfferWidget(details: args),
          ),
          settings: settings,
        );

      case sendLightningAddress:
        final LightningAddressDetails args = settings.arguments as LightningAddressDetails;
        // Lightning Address uses LNURL-Pay under the hood
        return MaterialPageRoute<Widget>(
          builder: (_) => LnurlPayScreen(payRequestDetails: args.payRequest),
          settings: settings,
        );

      case sendLnurlPay:
        final LnurlPayRequestDetails args = settings.arguments as LnurlPayRequestDetails;
        return MaterialPageRoute<Widget>(
          builder: (_) => LnurlPayScreen(payRequestDetails: args),
          settings: settings,
        );

      case sendSilentPayment:
        final SilentPaymentAddressDetails args = settings.arguments as SilentPaymentAddressDetails;
        return MaterialPageRoute<_PlaceholderScreen>(
          builder: (_) => _PlaceholderScreen(
            title: 'Silent Payment',
            content: _SilentPaymentWidget(details: args),
          ),
          settings: settings,
        );

      case sendBip21:
        final Bip21Details args = settings.arguments as Bip21Details;
        return MaterialPageRoute<Widget>(
          builder: (_) => Bip21Screen(bip21Details: args),
          settings: settings,
        );

      case sendBolt12InvoiceRequest:
        final Bolt12InvoiceRequestDetails args = settings.arguments as Bolt12InvoiceRequestDetails;
        return MaterialPageRoute<Widget>(
          builder: (_) => Bolt12InvoiceRequestScreen(requestDetails: args),
          settings: settings,
        );

      case sendSparkAddress:
        final SparkAddressDetails args = settings.arguments as SparkAddressDetails;
        return MaterialPageRoute<_PlaceholderScreen>(
          builder: (_) => _PlaceholderScreen(
            title: 'Spark Address Payment',
            content: _SparkAddressWidget(details: args),
          ),
          settings: settings,
        );

      case sendSparkInvoice:
        final SparkInvoiceDetails args = settings.arguments as SparkInvoiceDetails;
        return MaterialPageRoute<_PlaceholderScreen>(
          builder: (_) => _PlaceholderScreen(
            title: 'Spark Invoice Payment',
            content: _SparkInvoiceWidget(details: args),
          ),
          settings: settings,
        );

      // Deposit claim routes
      case AppRoutes.unclaimedDeposits:
        return MaterialPageRoute<UnclaimedDepositsScreen>(
          builder: (_) => const UnclaimedDepositsScreen(),
          settings: settings,
        );

      // Receive routes
      case receiveLnurlWithdraw:
        final LnurlWithdrawRequestDetails args = settings.arguments as LnurlWithdrawRequestDetails;
        return MaterialPageRoute<Widget>(
          builder: (_) => LnurlWithdrawScreen(withdrawDetails: args),
          settings: settings,
        );

      case AppRoutes.receiveScreen:
        return MaterialPageRoute<ReceiveScreen>(builder: (_) => const ReceiveScreen(), settings: settings);

      // Auth routes
      case lnurlAuth:
        final LnurlAuthRequestDetails args = settings.arguments as LnurlAuthRequestDetails;
        return MaterialPageRoute<Widget>(
          builder: (_) => LnurlAuthScreen(authDetails: args),
          settings: settings,
        );

      // Security & Backup routes
      case appSettings:
        return MaterialPageRoute<Widget>(
          builder: (BuildContext context) {
            return Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                final bool isPinEnabled = ref.watch(pinStatusProvider).value ?? false;

                if (isPinEnabled) {
                  return PinLockScreen(
                    popOnSuccess: false,
                    onUnlocked: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute<SecurityBackupScreen>(builder: (_) => const SecurityBackupScreen()),
                      );
                    },
                  );
                }

                return const SecurityBackupScreen();
              },
            );
          },
          settings: settings,
        );

      case pinSetup:
        return MaterialPageRoute<PinSetupScreen>(builder: (_) => const PinSetupScreen(), settings: settings);

      // Developers routes
      case developersScreen:
        return MaterialPageRoute<DevelopersScreen>(
          builder: (_) => const DevelopersScreen(),
          settings: settings,
        );

      default:
        // Route not found
        return MaterialPageRoute<_RouteNotFoundScreen>(
          builder: (_) => _RouteNotFoundScreen(settings.name ?? 'unknown'),
          settings: settings,
        );
    }
  }
}

// ============================================================================
// Payment Detail Widgets
// ============================================================================

class _Bolt11Widget extends StatelessWidget {
  final Bolt11InvoiceDetails details;

  const _Bolt11Widget({required this.details});

  @override
  Widget build(BuildContext context) {
    final DateTime expiry = DateTime.fromMillisecondsSinceEpoch(
      (details.timestamp + details.expiry).toInt() * 1000,
    );
    final DateTime created = DateTime.fromMillisecondsSinceEpoch(details.timestamp.toInt() * 1000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _InfoField(label: 'Amount', value: _formatAmount(details.amountMsat)),
        if (details.description != null) _InfoField(label: 'Description', value: details.description!),
        _InfoField(label: 'Payment Hash', value: details.paymentHash, monospace: true),
        _InfoField(label: 'Payee', value: details.payeePubkey, monospace: true),
        _InfoField(label: 'Network', value: details.network.name),
        _InfoField(label: 'Created', value: created.toLocal().toString()),
        _InfoField(label: 'Expires', value: expiry.toLocal().toString()),
        if (details.routingHints.isNotEmpty)
          _InfoField(label: 'Routing Hints', value: '${details.routingHints.length} hint(s)'),
        const Divider(height: 24),
        _InfoField(label: 'Invoice', value: details.invoice.bolt11, monospace: true),
      ],
    );
  }
}

class _Bolt12InvoiceWidget extends StatelessWidget {
  final Bolt12InvoiceDetails details;

  const _Bolt12InvoiceWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _InfoField(label: 'Amount', value: _formatAmount(details.amountMsat)),
        const Divider(height: 24),
        _InfoField(label: 'Invoice', value: details.invoice.invoice, monospace: true),
      ],
    );
  }
}

class _Bolt12OfferWidget extends StatelessWidget {
  final Bolt12OfferDetails details;

  const _Bolt12OfferWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (details.description != null) _InfoField(label: 'Description', value: details.description!),
        if (details.issuer != null) _InfoField(label: 'Issuer', value: details.issuer!),
        if (details.minAmount != null)
          _InfoField(label: 'Minimum Amount', value: _formatAmountType(details.minAmount!)),
        _InfoField(label: 'Chains', value: details.chains.join(', ')),
        _InfoField(label: 'Paths', value: '${details.paths.length} blinded path(s)'),
        if (details.signingPubkey != null)
          _InfoField(label: 'Signing Key', value: details.signingPubkey!, monospace: true),
        if (details.absoluteExpiry != null)
          _InfoField(
            label: 'Expires',
            value: DateTime.fromMillisecondsSinceEpoch(
              details.absoluteExpiry!.toInt() * 1000,
            ).toLocal().toString(),
          ),
        const Divider(height: 24),
        _InfoField(label: 'Offer', value: details.offer.offer, monospace: true),
      ],
    );
  }
}

class _SilentPaymentWidget extends StatelessWidget {
  final SilentPaymentAddressDetails details;

  const _SilentPaymentWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _InfoField(label: 'Address', value: details.address, monospace: true),
        _InfoField(label: 'Network', value: details.network.name),
        if (details.source.bip21Uri != null)
          _InfoField(label: 'BIP21 URI', value: details.source.bip21Uri!, monospace: true),
        if (details.source.bip353Address != null)
          _InfoField(label: 'BIP353 Address', value: details.source.bip353Address!),
      ],
    );
  }
}

class _SparkAddressWidget extends StatelessWidget {
  final SparkAddressDetails details;

  const _SparkAddressWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _InfoField(label: 'Spark Address', value: details.address, monospace: true),
        _InfoField(label: 'Identity Key', value: details.identityPublicKey, monospace: true),
        _InfoField(label: 'Network', value: details.network.name),
        if (details.source.bip21Uri != null)
          _InfoField(label: 'BIP21 URI', value: details.source.bip21Uri!, monospace: true),
        if (details.source.bip353Address != null)
          _InfoField(label: 'BIP353 Address', value: details.source.bip353Address!),
      ],
    );
  }
}

class _SparkInvoiceWidget extends StatelessWidget {
  final SparkInvoiceDetails details;

  const _SparkInvoiceWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    final DateTime? expiry = details.expiryTime != null
        ? DateTime.fromMillisecondsSinceEpoch(details.expiryTime!.toInt() * 1000)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _InfoField(label: 'Invoice', value: details.invoice, monospace: true),
        _InfoField(label: 'Identity Key', value: details.identityPublicKey, monospace: true),
        _InfoField(label: 'Network', value: details.network.name),
        if (details.amount != null) _InfoField(label: 'Amount', value: _formatAmount(details.amount)),
        if (details.description != null) _InfoField(label: 'Description', value: details.description!),
        if (details.tokenIdentifier != null)
          _InfoField(label: 'Token ID', value: details.tokenIdentifier!, monospace: true),
        if (details.senderPublicKey != null)
          _InfoField(label: 'Sender Key', value: details.senderPublicKey!, monospace: true),
        if (expiry != null) _InfoField(label: 'Expires', value: expiry.toLocal().toString()),
      ],
    );
  }
}

// ============================================================================
// Helper Widgets and Functions
// ============================================================================

/// Placeholder screen for UI flows that haven't been implemented yet
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final Widget content;

  const _PlaceholderScreen({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Column(
                  children: <Widget>[
                    Icon(Icons.construction, size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('Coming Soon', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'This screen is under development.\nShowing any available metadata.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Payment Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      content,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavButton(
        stickToBottom: true,
        text: 'CLOSE',
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// Helper widget to display a labeled field
class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;

  const _InfoField({required this.label, required this.value, this.monospace = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontFamily: monospace ? 'monospace' : null),
          ),
        ],
      ),
    );
  }
}

/// Format amounts from millisatoshis
String _formatAmount(BigInt? amountMsat) {
  if (amountMsat == null) {
    return 'Any amount';
  }
  final String sats = (amountMsat ~/ BigInt.from(1000)).toString();
  return '$sats sats';
}

/// Format Amount type (handles both Bitcoin and Currency)
String _formatAmountType(Amount amount) {
  return amount.when(
    bitcoin: (BigInt amountMsat) => _formatAmount(amountMsat),
    currency: (String iso4217Code, BigInt fractionalAmount) => '$iso4217Code $fractionalAmount',
  );
}

/// Screen shown when route is not found
class _RouteNotFoundScreen extends StatelessWidget {
  final String routeName;

  const _RouteNotFoundScreen(this.routeName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Not Found')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
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
      ),
    );
  }
}
