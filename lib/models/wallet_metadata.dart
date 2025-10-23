/// Minimal wallet metadata stored in secure storage.
///
/// SECURITY CRITICAL:
/// - Mnemonic is NEVER stored in this model
/// - Wallet ID is derived from mnemonic hash (first 8 chars of SHA-256)
/// - Mnemonic itself is stored separately in secure storage with key: 'wallet_mnemonic_{id}'
class WalletMetadata {
  final String id;
  final String name;

  const WalletMetadata({required this.id, required this.name});

  WalletMetadata copyWith({String? id, String? name}) =>
      WalletMetadata(id: id ?? this.id, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory WalletMetadata.fromJson(Map<String, dynamic> json) =>
      WalletMetadata(id: json['id'] as String, name: json['name'] as String);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WalletMetadata && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'WalletMetadata(id: $id, name: $name)';
}
