import 'package:json_annotation/json_annotation.dart';
part 'me_response.g.dart';

@JsonSerializable()
class MeResponse {
  final String name;
  final String? username;
  @JsonKey(name: 'birth_place')
  final String? birthPlace;

  @JsonKey(name: 'birth_date')
  final String? birthDate;
  final String? domicile;
  final String email;
  final String? phone;

  final String role;
  @JsonKey(name: 'is_member')
  final bool isMember;
  @JsonKey(name: 'member_until')
  final String? memberUntil;
  @JsonKey(name: 'package_code')
  final String? packageCode;
  MeResponse({
    required this.name,
    this.username,
    this.birthPlace,
    this.birthDate,
    this.domicile,
    required this.email,
    this.phone,
    required this.role,
    required this.isMember,
    this.memberUntil,
    this.packageCode,
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) =>
      _$MeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MeResponseToJson(this);
}
