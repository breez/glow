import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_metadata.freezed.dart';
part 'wallet_metadata.g.dart';

/// Represents wallet metadata stored in secure storage.
///
/// SECURITY CRITICAL:
/// - Mnemonic is NEVER stored in this model
/// - Wallet ID is derived from mnemonic hash (first 8 chars of SHA-256)
/// - Mnemonic itself is stored separately in secure storage with key: 'wallet_mnemonic_{id}'
///
/// Usage:
/// ```dart
/// final wallet = WalletMetadata(
///   id: '3a4b5c6d',  // Derived from mnemonic
///   name: 'My Wallet',
///   network: Network.mainnet,
///   createdAt: DateTime.now(),
///   isBackedUp: false,
/// );
/// ```
@freezed
abstract class WalletMetadata with _$WalletMetadata {
  const factory WalletMetadata({
    /// Unique wallet identifier (derived from mnemonic hash)
    required String id,

    /// User-friendly wallet name
    required String name,

    /// Network this wallet operates on (mainnet/regtest)
    required String network, // Stored as string for JSON serialization
    /// When the wallet was created
    required DateTime createdAt,

    /// Whether user has confirmed they backed up the mnemonic
    /// This flag is set to true only after user completes backup verification
    @Default(false) bool isBackedUp,

    /// Last time this wallet was used
    DateTime? lastUsedAt,
  }) = _WalletMetadata;

  factory WalletMetadata.fromJson(Map<String, dynamic> json) => _$WalletMetadataFromJson(json);
}

/// Extension to convert between Network enum and string
extension WalletMetadataExtension on WalletMetadata {
  /// Get the network as an enum value
  /// This is a helper since we store network as string in JSON
  String get networkName => network;
}
