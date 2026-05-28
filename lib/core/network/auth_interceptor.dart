import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cims/core/services/credential_store.dart';
import 'package:cims/core/services/token_storage.dart';
import 'package:cims/core/session/auth_session_controller.dart';
import 'package:cims/core/network/app_config.dart';

/// Bearer injection, queued 401 handling, token refresh, and session reset.
final class AuthDioInterceptor {
  AuthDioInterceptor(this._dio);

  final Dio _dio;

  static final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {
        'Content-Type': 'application/json',
      },
    ),
  );

  static const FlutterSecureStorage _secure =
      FlutterSecureStorage();

  static bool _skipRefresh(DioException err) {
    if (err.requestOptions.extra['skipAuthRefresh'] ==
        true) {
      return true;
    }
    final p = err.requestOptions.path;
    return p.contains('auth/login') ||
        p.contains('auth/refresh');
  }

  QueuedInterceptorsWrapper get queued =>
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['skipAuthToken'] == true) {
            return handler.next(options);
          }
          final token = await TokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] =
                'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (err, handler) async {
          if (err.response?.statusCode != 401) {
            return handler.next(err);
          }
          if (_skipRefresh(err)) {
            return handler.next(err);
          }
          if (err.requestOptions.extra['_authRetry'] ==
              true) {
            return handler.next(err);
          }

          try {
            final refresh = await _secure.read(
              key: 'refresh_token',
            );
            if (refresh == null || refresh.isEmpty) {
              await _onRefreshFailed();
              return handler.next(err);
            }

            final res =
                await _refreshDio.post<Map<String, dynamic>>(
              AppConfig.authRefreshPath,
              data: <String, dynamic>{
                AppConfig.refreshTokenBodyKey: refresh,
              },
            );

            final data = res.data;
            final access =
                data?['access_token'] as String? ??
                    data?['access'] as String?;
            if (access == null || access.isEmpty) {
              await _onRefreshFailed();
              return handler.next(err);
            }

            await TokenStorage.saveToken(access);
            final newRefresh =
                data?['refresh_token'] as String?;
            if (newRefresh != null &&
                newRefresh.isNotEmpty) {
              await _secure.write(
                key: 'refresh_token',
                value: newRefresh,
              );
            }

            final req = err.requestOptions;
            req.headers['Authorization'] =
                'Bearer $access';
            req.extra['_authRetry'] = true;

            final response = await _dio.fetch(req);
            return handler.resolve(response);
          } catch (_) {
            await _onRefreshFailed();
            return handler.next(err);
          }
        },
      );

  static Future<void> _onRefreshFailed() async {
    await CredentialStore.clearAll();
    await AuthSessionController.instance.signOut();
  }
}
