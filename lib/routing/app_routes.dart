import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/receive/receive_screen.dart';
import 'package:glow/features/developers/developers_screen.dart';
import 'package:glow/features/qr_scan/qr_scan_view.dart';
import 'package:glow/features/payment_details/payment_details_screen.dart';
import 'package:glow/features/send/send_screen.dart';
import 'package:glow/features/deposits/unclaimed_deposits_screen.dart';
import 'package:glow/features/wallet/create_screen.dart';
import 'package:glow/features/wallet/import_screen.dart';
import 'package:glow/features/wallet/list_screen.dart';
import 'package:glow/features/wallet/setup_screen.dart';
import 'package:glow/features/wallet/verify_screen.dart';

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
          builder: (_) => _PlaceholderScreen(
            title: 'Bitcoin Address Payment',
            content: _BitcoinAddressWidget(details: args),
          ),
          settings: settings,
        );

      case sendBolt11:
        final args = settings.arguments as Bolt11InvoiceDetails;
        return MaterialPageRoute(
          builder: (_) => _PlaceholderScreen(
            title: 'BOLT11 Invoice',
            content: _Bolt11Widget(details: args),
          ),
          settings: settings,
        );

      case sendBolt12Invoice:
        final args = settings.arguments as Bolt12InvoiceDetails;
        return MaterialPageRoute(
          builder: (_) => _PlaceholderScreen(
            title: 'BOLT12 Invoice',
            content: _Bolt12InvoiceWidget(details: args),
          ),
          settings: settings,
        );

      case sendBolt12Offer:
        final args = settings.arguments as Bolt12OfferDetails;
        return MaterialPageRoute(
          builder: (_) => _PlaceholderScreen(
            title: 'BOLT12 Offer',
            content: _Bolt12OfferWidget(details: args),
          ),
          settings: settings,
        );

      case sendLightningAddress:
        final args = settings.arguments as LightningAddressDetails;
        return MaterialPageRoute(
          builder: (_) => _PlaceholderScreen(
            title: 'Lightning Address',
            content: _LightningAddressWidget(details: args),
          ),
          settings: settings,
        );

      case sendLnurlPay:
        final args = settings.arguments as LnurlPayRequestDetails;
        return MaterialPageRoute(
          builder: (_) => _PlaceholderScreen(
            title: 'LNURL-Pay',
            content: _LnurlPayWidget(details: args),
          ),
          settings: settings,
        );

      case sendSilentPayment:
        final args = settings.arguments as SilentPaymentAddressDetails;
        return MaterialPageRoute(
          builder: (_) => _PlaceholderScreen(
            title: 'Silent Payment',
            content: _SilentPaymentWidget(details: args),
          ),
          settings: settings,
        );

      case sendBip21:
        final args = settings.arguments as Bip21Details;
        return MaterialPageRoute(
          builder: (_) => _PlaceholderScreen(
            title: 'BIP21 Payment',
            content: _Bip21Widget(details: args),
          ),
          settings: settings,
        );

      case sendBolt12InvoiceRequest:
        // final args = settings.arguments as Bolt12InvoiceRequestDetails;
        return MaterialPageRoute(
          builder: (_) => _PlaceholderScreen(
            title: 'BOLT12 Invoice Request',
            content: const _Bolt12InvoiceRequestWidget(),
          ),
          settings: settings,
        );

      case sendSparkAddress:
        final args = settings.arguments as SparkAddressDetails;
        return MaterialPageRoute(
          builder: (_) => _PlaceholderScreen(
            title: 'Spark Address Payment',
            content: _SparkAddressWidget(details: args),
          ),
          settings: settings,
        );

      case sendSparkInvoice:
        final args = settings.arguments as SparkInvoiceDetails;
        return MaterialPageRoute(
          builder: (_) => _PlaceholderScreen(
            title: 'Spark Invoice Payment',
            content: _SparkInvoiceWidget(details: args),
          ),
          settings: settings,
        );

      // Deposit claim routes
      case AppRoutes.unclaimedDeposits:
        return MaterialPageRoute(builder: (_) => const UnclaimedDepositsScreen(), settings: settings);

      // Receive routes
      case receiveLnurlWithdraw:
        final args = settings.arguments as LnurlWithdrawRequestDetails;
        return MaterialPageRoute(
          builder: (_) => _PlaceholderScreen(
            title: 'LNURL Withdraw',
            content: _LnurlWithdrawWidget(details: args),
          ),
          settings: settings,
        );

      case AppRoutes.receiveScreen:
        return MaterialPageRoute(builder: (_) => const ReceiveScreen(), settings: settings);

      // Auth routes
      case lnurlAuth:
        final args = settings.arguments as LnurlAuthRequestDetails;
        return MaterialPageRoute(
          builder: (_) => _PlaceholderScreen(
            title: 'LNURL Auth',
            content: _LnurlAuthWidget(details: args),
          ),
          settings: settings,
        );

      // App Settings routes
      case appSettings:
        return MaterialPageRoute(
          builder: (_) => _PlaceholderScreen(
            title: 'Settings',
            content: const _InfoField(label: 'Status', value: 'App configuration coming soon'),
          ),
          settings: settings,
        );

      case walletSettings:
        return MaterialPageRoute(
          builder: (_) => _PlaceholderScreen(
            title: 'Wallet Settings',
            content: const _InfoField(label: 'Status', value: 'Manage your wallet settings'),
          ),
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

// ============================================================================
// Payment Detail Widgets
// ============================================================================

class _BitcoinAddressWidget extends StatelessWidget {
  final BitcoinAddressDetails details;

  const _BitcoinAddressWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

class _Bolt11Widget extends StatelessWidget {
  final Bolt11InvoiceDetails details;

  const _Bolt11Widget({required this.details});

  @override
  Widget build(BuildContext context) {
    final expiry = DateTime.fromMillisecondsSinceEpoch((details.timestamp + details.expiry).toInt() * 1000);
    final created = DateTime.fromMillisecondsSinceEpoch(details.timestamp.toInt() * 1000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      children: [
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
      children: [
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

class _LightningAddressWidget extends StatelessWidget {
  final LightningAddressDetails details;

  const _LightningAddressWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoField(label: 'Lightning Address', value: details.address),
        _InfoField(label: 'Domain', value: details.payRequest.domain),
        _InfoField(
          label: 'Send Range',
          value:
              '${_formatAmount(details.payRequest.minSendable)} - ${_formatAmount(details.payRequest.maxSendable)}',
        ),
        if (details.payRequest.commentAllowed > 0)
          _InfoField(label: 'Comment Allowed', value: '${details.payRequest.commentAllowed} characters'),
        if (details.payRequest.allowsNostr == true) const _InfoField(label: 'Nostr', value: 'Supported'),
        const Divider(height: 24),
        _InfoField(label: 'Callback URL', value: details.payRequest.callback, monospace: true),
      ],
    );
  }
}

class _LnurlPayWidget extends StatelessWidget {
  final LnurlPayRequestDetails details;

  const _LnurlPayWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoField(label: 'Domain', value: details.domain),
        _InfoField(
          label: 'Amount Range',
          value: '${_formatAmount(details.minSendable)} - ${_formatAmount(details.maxSendable)}',
        ),
        if (details.commentAllowed > 0)
          _InfoField(label: 'Comment Allowed', value: '${details.commentAllowed} characters'),
        if (details.address != null) _InfoField(label: 'Address', value: details.address!),
        if (details.allowsNostr == true) const _InfoField(label: 'Nostr', value: 'Supported'),
        if (details.nostrPubkey != null)
          _InfoField(label: 'Nostr Pubkey', value: details.nostrPubkey!, monospace: true),
        const Divider(height: 24),
        _InfoField(label: 'Callback URL', value: details.callback, monospace: true),
        _InfoField(label: 'LNURL', value: details.url, monospace: true),
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
      children: [
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

class _Bip21Widget extends StatelessWidget {
  final Bip21Details details;

  const _Bip21Widget({required this.details});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoField(label: 'URI', value: details.uri, monospace: true),
        if (details.amountSat != null) _InfoField(label: 'Amount', value: '${details.amountSat} sats'),
        if (details.label != null) _InfoField(label: 'Label', value: details.label!),
        if (details.message != null) _InfoField(label: 'Message', value: details.message!),
        if (details.assetId != null) _InfoField(label: 'Asset ID', value: details.assetId!),
        const Divider(height: 24),
        _InfoField(label: 'Payment Methods', value: '${details.paymentMethods.length} available'),
        ...details.paymentMethods.map(
          (method) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text('• ${_getInputTypeName(method)}', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
        if (details.extras.isNotEmpty) ...[
          const Divider(height: 24),
          const _InfoField(label: 'Extra Parameters', value: ''),
          ...details.extras.map(
            (extra) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                '${extra.key}: ${extra.value}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Bolt12InvoiceRequestWidget extends StatelessWidget {
  const _Bolt12InvoiceRequestWidget();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoField(label: 'Status', value: 'Ready to create invoice from BOLT12 offer'),
        _InfoField(label: 'Description', value: 'This flow will fetch an invoice from a BOLT12 offer'),
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
      children: [
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
    final expiry = details.expiryTime != null
        ? DateTime.fromMillisecondsSinceEpoch(details.expiryTime!.toInt() * 1000)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

class _LnurlWithdrawWidget extends StatelessWidget {
  final LnurlWithdrawRequestDetails details;

  const _LnurlWithdrawWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoField(label: 'Description', value: details.defaultDescription),
        _InfoField(
          label: 'Amount Range',
          value: '${_formatAmount(details.minWithdrawable)} - ${_formatAmount(details.maxWithdrawable)}',
        ),
        const Divider(height: 24),
        _InfoField(label: 'Callback URL', value: details.callback, monospace: true),
        _InfoField(label: 'K1', value: details.k1, monospace: true),
      ],
    );
  }
}

class _LnurlAuthWidget extends StatelessWidget {
  final LnurlAuthRequestDetails details;

  const _LnurlAuthWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoField(label: 'Domain', value: details.domain),
        if (details.action != null) _InfoField(label: 'Action', value: details.action!),
        const Divider(height: 24),
        _InfoField(label: 'URL', value: details.url, monospace: true),
        _InfoField(label: 'K1', value: details.k1, monospace: true),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
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
                  children: [
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
            const SizedBox(height: 24),
            Center(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ),
          ],
        ),
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
        children: [
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
  if (amountMsat == null) return 'Any amount';
  final sats = (amountMsat ~/ BigInt.from(1000)).toString();
  return '$sats sats';
}

/// Format Amount type (handles both Bitcoin and Currency)
String _formatAmountType(Amount amount) {
  return amount.when(
    bitcoin: (amountMsat) => _formatAmount(amountMsat),
    currency: (iso4217Code, fractionalAmount) => '$iso4217Code $fractionalAmount',
  );
}

/// Get human-readable name for InputType
String _getInputTypeName(InputType inputType) {
  return inputType.when(
    bitcoinAddress: (_) => 'Bitcoin Address',
    bolt11Invoice: (_) => 'BOLT11 Invoice',
    bolt12Invoice: (_) => 'BOLT12 Invoice',
    bolt12Offer: (_) => 'BOLT12 Offer',
    lightningAddress: (_) => 'Lightning Address',
    lnurlPay: (_) => 'LNURL-Pay',
    silentPaymentAddress: (_) => 'Silent Payment',
    lnurlAuth: (_) => 'LNURL Auth',
    url: (_) => 'URL',
    bip21: (_) => 'BIP21',
    bolt12InvoiceRequest: (_) => 'BOLT12 Invoice Request',
    lnurlWithdraw: (_) => 'LNURL Withdraw',
    sparkAddress: (_) => 'Spark Address',
    sparkInvoice: (_) => 'Spark Invoice',
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
