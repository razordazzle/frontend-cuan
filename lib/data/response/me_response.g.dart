// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeResponse _$MeResponseFromJson(Map<String, dynamic> json) => MeResponse(
  name: json['name'] as String,
  username: json['username'] as String?,
  birthPlace: json['birth_place'] as String?,
  birthDate: json['birth_date'] as String?,
  domicile: json['domicile'] as String?,
  email: json['email'] as String,
  phone: json['phone'] as String?,
  role: json['role'] as String,
  isMember: json['is_member'] as bool,
  memberUntil: json['member_until'] as String?,
  packageCode: json['package_code'] as String?,
);

Map<String, dynamic> _$MeResponseToJson(MeResponse instance) =>
    <String, dynamic>{
      'name': instance.name,
      'username': instance.username,
      'birth_place': instance.birthPlace,
      'birth_date': instance.birthDate,
      'domicile': instance.domicile,
      'email': instance.email,
      'phone': instance.phone,
      'role': instance.role,
      'is_member': instance.isMember,
      'member_until': instance.memberUntil,
      'package_code': instance.packageCode,
    };
