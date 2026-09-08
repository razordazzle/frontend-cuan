// lib/data/model/user_me.dart
import 'package:json_annotation/json_annotation.dart';

part 'user_me.g.dart';

@JsonSerializable()
class UserMe {
  final String name;
  final String? username;

  @JsonKey(name: 'birth_place')
  final String? birthPlace;

  // backend kirim "YYYY-MM-DD" → json_serializable akan otomatis DateTime.parse
  @JsonKey(name: 'birth_date')
  final DateTime? birthDate;

  final String? domicile;
  final String email;
  final String? phone;

  const UserMe({
    required this.name,
    this.username,
    this.birthPlace,
    this.birthDate,
    this.domicile,
    required this.email,
    this.phone,
  });

  factory UserMe.fromJson(Map<String, dynamic> json) => _$UserMeFromJson(json);
  Map<String, dynamic> toJson() => _$UserMeToJson(this);
}
