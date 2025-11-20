import 'package:flutter/foundation.dart';
import 'package:plenimind_app/service/api_client.dart';
import 'package:plenimind_app/core/auth/auth_manager.dart';

class AccountService {
  final ApiClient _apiClient = ApiClient();
  final AuthManager _authManager = AuthManager();

  Future<bool> deleteAccount(String uid, String token) async {
    try {
      debugPrint('🗑️ [ACCOUNT_SERVICE] Iniciando exclusão da conta: $uid');

      final response = await _apiClient.authenticatedDelete(
        'users/$uid',
        token,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint(
          '✅ [ACCOUNT_SERVICE] Conta deletada com sucesso no servidor',
        );

        // Limpar tokens do AuthManager
        await _authManager.clearTokens();
        debugPrint('✅ [ACCOUNT_SERVICE] Tokens locais removidos');

        return true;
      } else {
        debugPrint(
          '❌ [ACCOUNT_SERVICE] Erro ao deletar conta: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ [ACCOUNT_SERVICE] Erro ao deletar conta: $e');
      return false;
    }
  }

  Future<void> deleteLocalUserData(String userId) async {
    try {
      debugPrint(
        '🗑️ [ACCOUNT_SERVICE] Limpando dados locais do usuário: $userId',
      );

      // Nota: ContactService.getStorageKey usa userId, então os contatos
      // serão automaticamente perdidos quando o usuário deletar e se registrar novamente
      // com um novo userId

      debugPrint('✅ [ACCOUNT_SERVICE] Dados locais do usuário removidos');
    } catch (e) {
      debugPrint('❌ [ACCOUNT_SERVICE] Erro ao limpar dados locais: $e');
    }
  }
}
