import 'package:json_annotation/json_annotation.dart';
part 'token_pair_response.g.dart';

@JsonSerializable()
class TokenPairResponse {
  @JsonKey(name: 'Access_token')
  final String accessToken;

  @JsonKey(name: 'Refresh_token')
  final String refreshToken;

  @JsonKey(name: 'expires_in')
  final int expiresIn;

  TokenPairResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory TokenPairResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenPairResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TokenPairResponseToJson(this);
}