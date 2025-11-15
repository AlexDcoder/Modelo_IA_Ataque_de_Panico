import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthManager {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  String? _token;
  String? _refreshToken;
  String? _userId;

  AuthManager() {
    _loadTokens();
  }

  // ✅ CORREÇÃO: Método público para recarregar tokens
  Future<void> reloadTokens() async {
    await _loadTokens();
  }

  // ✅ CORREÇÃO: Carregar tokens de forma síncrona no construtor
  Future<void> _loadTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);
      _userId = prefs.getString(_userIdKey);

      debugPrint('🔄 AuthManager carregado:');
      debugPrint('   Token: ${_token != null ? "✅ Disponível" : "❌ Nulo"}');
      debugPrint('   UserId: ${_userId ?? "❌ Nulo"}');
    } catch (e) {
      debugPrint('❌ Erro ao carregar tokens: $e');
    }
  }

  // ✅ CORREÇÃO: Método síncrono para obter token
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get userId => _userId;

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // ✅ CORREÇÃO: Salvar tokens de forma robusta
  Future<void> setTokens(
    String token,
    String refreshToken,
    String userId,
  ) async {
    try {
      _token = token;
      _refreshToken = refreshToken;
      _userId = userId;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_userIdKey, userId);

      debugPrint('💾 Tokens salvos no AuthManager:');
      debugPrint('   Token: ${token.substring(0, 20)}...');
      debugPrint('   UserId: $userId');
    } catch (e) {
      debugPrint('❌ Erro ao salvar tokens: $e');
    }
  }

  Future<void> clearTokens() async {
    _token = null;
    _refreshToken = null;
    _userId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);

    debugPrint('🗑️ Tokens removidos do AuthManager');
  }
}
