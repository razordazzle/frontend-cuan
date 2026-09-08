// import 'package:json_annotation/json_annotation.dart';

// @JsonSerializable()
// class LoginRequest {
// final String email;
// final String password;
// LoginRequest({required this.email, required this.password});
// Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
// }

// @JsonSerializable()
// class RegisterRequest {
// final String name;
// final String email;
// final String password;
// final String? username;
// final String? birth_place;
// final String? birth_date; // YYYY-MM-DD
// final String? domicile;
// final String? phone;
// RegisterRequest({
// required this.name,
// required this.email,
// required this.password,
// this.username,
// this.birth_place,
// this.birth_date,
// this.domicile,
// this.phone,
// });
// Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
// }

// @JsonSerializable()
// class TokenPairResponse {
// @JsonKey(name: 'Access_token')
// final String accessToken;
// @JsonKey(name: 'Refresh_token')
// final String refreshToken;
// final int expires_in;


// TokenPairResponse({
// required this.accessToken,
// required this.refreshToken,
// required this.expires_in,
// });


// factory TokenPairResponse.fromJson(Map<String, dynamic> json) =>
// _$TokenPairResponseFromJson(json);
// }


// @JsonSerializable()
// class RefreshResponse {
// @JsonKey(name: 'Access_token')
// final String accessToken;
// final int expires_in;
// RefreshResponse({required this.accessToken, required this.expires_in});
// factory RefreshResponse.fromJson(Map<String, dynamic> json) =>
// _$RefreshResponseFromJson(json);
// }


// @JsonSerializable()
// class MeResponse {
// final String name;
// final String? username;
// final String? birth_place;
// final String? birth_date; // ISO date
// final String? domicile;
// final String email;
// final String? phone;
// MeResponse({
// required this.name,
// this.username,
// this.birth_place,
// this.birth_date,
// this.domicile,
// required this.email,
// this.phone,
// });
// factory MeResponse.fromJson(Map<String, dynamic> json) =>
// _$MeResponseFromJson(json);
// }