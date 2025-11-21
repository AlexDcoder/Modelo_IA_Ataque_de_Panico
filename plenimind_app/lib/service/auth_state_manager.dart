import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:plenimind_app/core/auth/auth_manager.dart';

/// Gerenciador centralizado do estado de autenticação
/// Coordena o lifecycle de serviços baseado na autenticação
class AuthStateManager {
  static final AuthStateManager _instance = AuthStateManager._internal();

  factory AuthStateManager() => _instance;

  AuthStateManager._internal() {
    _initializeFromAuthManager();
  }

  // Stream para notificar mudanças de estado de autenticação
  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();

  AuthState _currentState = AuthState.unauthenticated;

  /// Inicializar estado baseado no AuthManager
  void _initializeFromAuthManager() {
    final authManager = AuthManager();
    if (authManager.isLoggedIn) {
      debugPrint(
        '🔐 [AUTH_STATE_MANAGER] Inicializando como AUTENTICADO (tokens encontrados)',
      );
      _currentState = AuthState.authenticated;
    } else {
      debugPrint(
        '❌ [AUTH_STATE_MANAGER] Inicializando como NÃO AUTENTICADO (sem tokens)',
      );
      _currentState = AuthState.unauthenticated;
    }
  }

  Stream<AuthState> get authStateStream => _authStateController.stream;
  AuthState get currentState => _currentState;

  /// Notificar que o usuário fez login
  void notifyLoggedIn() {
    debugPrint('🔐 [AUTH_STATE_MANAGER] Usuário logado');
    _updateState(AuthState.authenticated);
  }

  /// Notificar que o usuário fez logout
  void notifyLoggedOut() {
    debugPrint('🔓 [AUTH_STATE_MANAGER] Usuário deslogado');
    _updateState(AuthState.unauthenticated);
  }

  /// Notificar que a conta foi deletada
  void notifyAccountDeleted() {
    debugPrint('🗑️ [AUTH_STATE_MANAGER] Conta deletada');
    _updateState(AuthState.accountDeleted);
  }

  /// Notificar que há um erro de autenticação
  void notifyAuthError(String message) {
    debugPrint('❌ [AUTH_STATE_MANAGER] Erro de autenticação: $message');
    _updateState(AuthState.error);
  }

  void _updateState(AuthState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _authStateController.add(newState);
      debugPrint('   📢 Estado atualizado: $_currentState');
    }
  }

  void dispose() {
    _authStateController.close();
    debugPrint('♻️ [AUTH_STATE_MANAGER] Dispose executado');
  }
}

/// Estados de autenticação possíveis
enum AuthState { authenticated, unauthenticated, accountDeleted, error }
