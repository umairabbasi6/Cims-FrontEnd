import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:cims/features/auth/models/current_user.dart';
import 'package:cims/features/auth/models/login_response.dart';
import 'package:cims/features/auth/models/message_response.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AuthApi {
  factory AuthApi(
    Dio dio, {
    String? baseUrl,
  }) = _AuthApi;

  @POST('/auth/login')
  @Extra(<String, Object>{
    'skipAuthToken': true,
    'skipAuthRefresh': true,
  })
  Future<LoginResponse> login(
    @Body() Map<String, dynamic> body,
  );

  @GET('/auth/me')
  Future<CurrentUser> getMe();

  @POST('/auth/change-password')
  Future<MessageResponse> changePassword(
    @Body() Map<String, dynamic> body,
  );
}
