import 'package:dio/dio.dart';

import 'package:cims/core/network/dio_client.dart';
import 'package:cims/core/network/api/auth_api.dart';

/// Entry point for generated HTTP clients backed by [DioClient.dio].
abstract final class ApiClient {
  static final Dio dio = DioClient.dio;

  static AuthApi? _auth;

  static AuthApi get auth =>
      _auth ??= AuthApi(dio);
}
