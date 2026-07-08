import 'package:json_annotation/json_annotation.dart';

import 'address.dart';

part 'serializable_user.g.dart';

@JsonSerializable(explicitToJson: true)
class SerializableUser {
  const SerializableUser({required this.name, required this.address});

  final String name;
  final Address address;

  factory SerializableUser.fromJson(Map<String, dynamic> json) =>
      _$SerializableUserFromJson(json);

  Map<String, dynamic> toJson() => _$SerializableUserToJson(this);
}
