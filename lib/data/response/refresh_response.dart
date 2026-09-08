import 'package:json_annotation/json_annotation.dart';
part 'refresh_response.g.dart';

@JsonSerializable()
class RefreshResponse {
  @JsonKey(name: 'Access_token')
  final String accessToken;

  @JsonKey(name: 'expires_in')
  final int expiresIn;

  RefreshResponse({required this.accessToken, required this.expiresIn});

  factory RefreshResponse.fromJson(Map<String, dynamic> json) =>
      _$RefreshResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshResponseToJson(this);
}
