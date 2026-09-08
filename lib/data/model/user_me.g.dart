// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_me.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserMe _$UserMeFromJson(Map<String, dynamic> json) => UserMe(
  name: json['name'] as String,
  username: json['username'] as String?,
  birthPlace: json['birth_place'] as String?,
  birthDate: json['birth_date'] == null
      ? null
      : DateTime.parse(json['birth_date'] as String),
  domicile: json['domicile'] as String?,
  email: json['email'] as String,
  phone: json['phone'] as String?,
);

Map<String, dynamic> _$UserMeToJson(UserMe instance) => <String, dynamic>{
  'name': instance.name,
  'username': instance.username,
  'birth_place': instance.birthPlace,
  'birth_date': instance.birthDate?.toIso8601String(),
  'domicile': instance.domicile,
  'email': instance.email,
  'phone': instance.phone,
};
