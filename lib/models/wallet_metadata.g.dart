// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WalletMetadata _$WalletMetadataFromJson(Map<String, dynamic> json) => _WalletMetadata(
  id: json['id'] as String,
  name: json['name'] as String,
  network: json['network'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  isBackedUp: json['isBackedUp'] as bool? ?? false,
  lastUsedAt: json['lastUsedAt'] == null ? null : DateTime.parse(json['lastUsedAt'] as String),
);

Map<String, dynamic> _$WalletMetadataToJson(_WalletMetadata instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'network': instance.network,
  'createdAt': instance.createdAt.toIso8601String(),
  'isBackedUp': instance.isBackedUp,
  'lastUsedAt': instance.lastUsedAt?.toIso8601String(),
};
