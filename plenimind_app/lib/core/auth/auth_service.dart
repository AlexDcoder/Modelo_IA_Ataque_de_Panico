import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:plenimind_app/core/auth/auth_manager.dart';
import 'package:plenimind_app/service/api_client.dart';
import 'dart:math';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final AuthManager _authManager = AuthManager();

  // ✅ DEBUG: Estado do AuthManager
  void _debugAuthState() {
    debugPrint('🔍 [AUTH_SERVICE] Estado do AuthManager:');
    debugPrint(
      '   Token: ${_authManager.token != null ? "✅ ${_authManager.token!.substring(0, 20)}..." : "❌ NULO"}',
    );
    debugPrint('   UserId: ${_authManager.userId ?? "❌ NULO"}');
    debugPrint('   isLoggedIn: ${_authManager.isLoggedIn}');
  }

  // ✅ LOGIN: Autenticação do usuário
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      debugPrint('🔐 [AUTH_SERVICE] Iniciando login para: $email');
      _debugAuthState();

      final response = await _apiClient.post('auth/login', {
        'email': email,
        'password': password,
      });

      debugPrint('📡 [AUTH_SERVICE] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String accessToken = data['access_token'];
        final String refreshToken = data['refresh_token'] ?? '';

        debugPrint(
          '✅ [AUTH_SERVICE] Token recebido: ${accessToken.substring(0, 30)}...',
        );

        // ✅ Extrair userId do token JWT
        final Map<String, dynamic>? tokenPayload = _decodeJwt(accessToken);
        final String? userId = tokenPayload?['sub'];

        debugPrint('🐤 [AUTH_SERVICE] UserId extraído do token: $userId');

        if (userId == null) {
          debugPrint(
            '⚠️ [AUTH_SERVICE] UserId não encontrado no token, gerando um aleatório',
          );
          final random = Random();
          final tempUserId = 'temp_${random.nextInt(10000)}';
          await _authManager.setTokens(accessToken, refreshToken, tempUserId);
        } else {
          await _authManager.setTokens(accessToken, refreshToken, userId);
        }

        // ✅ VERIFICAÇÃO: Confirmar que tokens foram salvos
        _debugAuthState();

        debugPrint('✅ [AUTH_SERVICE] Login realizado com sucesso para: $email');
        return data;
      } else {
        debugPrint(
          '❌ [AUTH_SERVICE] Login failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ [AUTH_SERVICE] Login error: $e');
      return null;
    }
  }

  // ✅ DECODE JWT: Decodificar token JWT
  Map<String, dynamic>? _decodeJwt(String token) {
    try {
      debugPrint('🔐 [AUTH_SERVICE] Decodificando JWT token...');
      final parts = token.split('.');
      if (parts.length != 3) {
        debugPrint(
          '❌ [AUTH_SERVICE] JWT inválido - número de partes incorreto',
        );
        return null;
      }

      final payload = _decodeBase64(parts[1]);
      final payloadMap = json.decode(payload);

      debugPrint('✅ [AUTH_SERVICE] JWT decodificado com sucesso');
      return payloadMap is Map<String, dynamic> ? payloadMap : null;
    } catch (e) {
      debugPrint('❌ [AUTH_SERVICE] Erro ao decodificar JWT: $e');
      return null;
    }
  }

  String _decodeBase64(String str) {
    try {
      String output = str.replaceAll('-', '+').replaceAll('_', '/');

      switch (output.length % 4) {
        case 0:
          break;
        case 2:
          output += '==';
          break;
        case 3:
          output += '=';
          break;
        default:
          throw Exception('Illegal base64url string!"');
      }

      return utf8.decode(base64Url.decode(output));
    } catch (e) {
      debugPrint('❌ [AUTH_SERVICE] Erro ao decodificar base64: $e');
      rethrow;
    }
  }

  // ✅ GETTERS: Estado de autenticação
  String? get token {
    final token = _authManager.token;
    if (token == null) {
      debugPrint('⚠️ [AUTH_SERVICE] Token NULO no AuthManager');
    } else {
      debugPrint(
        '✅ [AUTH_SERVICE] Token disponível (${token.substring(0, 20)}...)',
      );
    }
    return token;
  }

  String? get userId {
    final userId = _authManager.userId;
    if (userId == null || userId.isEmpty) {
      debugPrint('⚠️ [AUTH_SERVICE] UserId NULO no AuthManager');
    } else {
      debugPrint('✅ [AUTH_SERVICE] UserId: $userId');
    }
    return userId;
  }

  bool get isLoggedIn {
    final loggedIn = _authManager.isLoggedIn;
    debugPrint('🔐 [AUTH_SERVICE] isLoggedIn: $loggedIn');
    return loggedIn;
  }

  // ✅ LOGOUT: Encerrar sessão
  Future<void> logout() async {
    debugPrint('🚪 [AUTH_SERVICE] Iniciando logout...');
    await _authManager.clearTokens();
    debugPrint('✅ [AUTH_SERVICE] Logout realizado com sucesso');
  }

  // ✅ UPDATE USER ID: Atualizar userId
  Future<void> updateUserId(String newUserId) async {
    debugPrint('🔄 [AUTH_SERVICE] Atualizando UserId para: $newUserId');
    final currentToken = _authManager.token;
    if (currentToken != null) {
      await _authManager.setTokens(
        currentToken,
        _authManager.refreshToken ?? '',
        newUserId,
      );
      debugPrint(
        '✅ [AUTH_SERVICE] UserId atualizado no AuthManager: $newUserId',
      );
      _debugAuthState();
    } else {
      debugPrint(
        '❌ [AUTH_SERVICE] Não é possível atualizar userId: token nulo',
      );
    }
  }

  // ✅ REFRESH TOKEN: Renovar token de acesso
  Future<Map<String, dynamic>?> refreshToken() async {
    try {
      debugPrint('🔄 [AUTH_SERVICE] Renovando token...');
      final refreshToken = _authManager.refreshToken;
      if (refreshToken == null) {
        debugPrint('❌ [AUTH_SERVICE] Nenhum refresh token disponível');
        return null;
      }

      final response = await _apiClient.post('auth/refresh', {
        'refresh_token': refreshToken,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String newAccessToken = data['access_token'];
        final String newRefreshToken = data['refresh_token'] ?? refreshToken;

        await _authManager.setTokens(
          newAccessToken,
          newRefreshToken,
          _authManager.userId ?? '',
        );

        debugPrint('✅ [AUTH_SERVICE] Token renovado com sucesso');
        return data;
      } else {
        debugPrint(
          '❌ [AUTH_SERVICE] Token refresh failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ [AUTH_SERVICE] Token refresh error: $e');
      return null;
    }
  }
}
