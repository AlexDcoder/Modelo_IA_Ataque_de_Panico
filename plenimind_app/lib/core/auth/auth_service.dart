import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:plenimind_app/core/auth/auth_manager.dart';
import 'package:plenimind_app/service/api_client.dart';
import 'dart:math';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final AuthManager _authManager = AuthManager();

  // ✅ CORREÇÃO: Método para debug do estado do AuthManager
  void _debugAuthState() {
    debugPrint('🔍 Estado do AuthManager:');
    debugPrint(
      '   Token: ${_authManager.token != null ? "✅ ${_authManager.token!.substring(0, 20)}..." : "❌ Nulo"}',
    );
    debugPrint('   UserId: ${_authManager.userId ?? "❌ Nulo"}');
    debugPrint('   isLoggedIn: ${_authManager.isLoggedIn}');
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      debugPrint('🔐 Iniciando login para: $email');
      _debugAuthState();

      final response = await _apiClient.post('auth/login', {
        'email': email,
        'password': password,
      });

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String accessToken = data['access_token'];
        final String refreshToken = data['refresh_token'] ?? '';

        debugPrint('✅ Token recebido: ${accessToken.substring(0, 30)}...');

        // ✅ CORREÇÃO: Extrair userId do token JWT
        final Map<String, dynamic>? tokenPayload = _decodeJwt(accessToken);
        final String? userId = tokenPayload?['sub'];

        debugPrint('🐤 UserId extraído do token: $userId');

        if (userId == null) {
          debugPrint('⚠️ UserId não encontrado no token, gerando um aleatório');
          // Gerar um userId temporário se não estiver no token
          final random = Random();
          final tempUserId = 'temp_${random.nextInt(10000)}';
          await _authManager.setTokens(accessToken, refreshToken, tempUserId);
        } else {
          await _authManager.setTokens(accessToken, refreshToken, userId);
        }

        // ✅ VERIFICAÇÃO: Confirmar que tokens foram salvos
        _debugAuthState();

        return data;
      } else {
        debugPrint('❌ Login failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      return null;
    }
  }

  // ✅ NOVO: Decodificar JWT de forma robusta
  Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final payload = _decodeBase64(parts[1]);
      final payloadMap = json.decode(payload);

      return payloadMap is Map<String, dynamic> ? payloadMap : null;
    } catch (e) {
      debugPrint('❌ Erro ao decodificar JWT: $e');
      return null;
    }
  }

  String _decodeBase64(String str) {
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
  }

  // ✅ CORREÇÃO: Getters que verificam o AuthManager diretamente
  String? get token {
    final token = _authManager.token;
    if (token == null) {
      debugPrint('⚠️ AuthService.token: Token NULO no AuthManager');
    } else {
      debugPrint(
        '✅ AuthService.token: Token disponível (${token.substring(0, 20)}...)',
      );
    }
    return token;
  }

  String? get userId {
    final userId = _authManager.userId;
    if (userId == null || userId.isEmpty) {
      debugPrint('⚠️ AuthService.userId: UserId NULO no AuthManager');
    } else {
      debugPrint('✅ AuthService.userId: $userId');
    }
    return userId;
  }

  bool get isLoggedIn {
    final loggedIn = _authManager.isLoggedIn;
    debugPrint('🔐 AuthService.isLoggedIn: $loggedIn');
    return loggedIn;
  }

  Future<void> logout() async {
    await _authManager.clearTokens();
    debugPrint('✅ Logout realizado');
  }

  // ✅ CORREÇÃO: Método para forçar atualização do userId
  Future<void> updateUserId(String newUserId) async {
    final currentToken = _authManager.token;
    if (currentToken != null) {
      await _authManager.setTokens(
        currentToken,
        _authManager.refreshToken ?? '',
        newUserId,
      );
      debugPrint('✅ UserId atualizado no AuthManager: $newUserId');
      _debugAuthState();
    } else {
      debugPrint('❌ Não é possível atualizar userId: token nulo');
    }
  }

  Future<Map<String, dynamic>?> refreshToken() async {
    try {
      final refreshToken = _authManager.refreshToken;
      if (refreshToken == null) {
        debugPrint('❌ Nenhum refresh token disponível');
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

        debugPrint('✅ Token renovado com sucesso');
        return data;
      } else {
        debugPrint(
          '❌ Token refresh failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
      return null;
    }
  }
}
