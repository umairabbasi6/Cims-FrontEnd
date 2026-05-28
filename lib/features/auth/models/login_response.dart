import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_response.freezed.dart';
part 'login_response.g.dart';

@freezed
abstract class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    @JsonKey(name: 'access_token')
    required String accessToken,
    @JsonKey(name: 'refresh_token')
    required String refreshToken,
    @JsonKey(name: 'token_type')
    required String tokenType,
    required String role,
    @JsonKey(name: 'user_id', fromJson: _userIdToString)
    required String userId,
    required String username,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}

String _userIdToString(Object? value) =>
    value?.toString() ?? '';
