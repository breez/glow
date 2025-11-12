/// Non-sensitive metadata for a wallet stored in secure storage.
///
/// SECURITY CRITICAL:
/// - Mnemonic is NEVER stored in this model
/// - Wallet ID is derived from mnemonic hash (first 8 chars of SHA-256)
/// - Mnemonic itself is stored separately in secure storage with key: 'wallet_mnemonic_{id}'
class WalletMetadata {
  final String id;
  final String name;
  final bool isVerified;

  const WalletMetadata({required this.id, required this.name, this.isVerified = false});

  WalletMetadata copyWith({String? id, String? name, bool? isVerified}) =>
      WalletMetadata(id: id ?? this.id, name: name ?? this.name, isVerified: isVerified ?? this.isVerified);

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'name': name, 'isVerified': isVerified};

  factory WalletMetadata.fromJson(Map<String, dynamic> json) => WalletMetadata(
    id: json['id'] as String,
    name: json['name'] as String,
    isVerified: json['isVerified'] as bool? ?? false,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletMetadata && other.id == id && other.name == name && other.isVerified == isVerified;

  @override
  int get hashCode => Object.hash(id, name, isVerified);

  @override
  String toString() => 'WalletMetadata(id: $id, name: $name, isVerified: $isVerified)';
}
