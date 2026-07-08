// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializable_user.dart';

SerializableUser _$SerializableUserFromJson(Map<String, dynamic> json) =>
    SerializableUser(
      name: json['name'] as String,
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SerializableUserToJson(SerializableUser instance) =>
    <String, dynamic>{
      'name': instance.name,
      'address': instance.address.toJson(),
    };
