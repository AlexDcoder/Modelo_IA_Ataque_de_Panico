import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionManager {
  // Chaves que NÃO dependem do userId para persistir entre deleções
  static const String _contactsPermissionKey =
      'plenimind_contacts_permission_granted';
  static const String _notificationPermissionKey =
      'plenimind_notification_permission_granted';
  static const String _phonePermissionKey =
      'plenimind_phone_permission_granted';
  static const String _termsAcceptedKey = 'plenimind_terms_accepted';

  /// Salva que o usuário aceitou os termos
  static Future<void> setTermsAccepted(bool accepted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_termsAcceptedKey, accepted);
      debugPrint(
        '💾 Termos de uso: ${accepted ? "✅ Aceitos" : "❌ Rejeitados"}',
      );
    } catch (e) {
      debugPrint('❌ Erro ao salvar aceitar de termos: $e');
    }
  }

  /// Verifica se o usuário já aceitou os termos
  static Future<bool> getTermsAccepted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_termsAcceptedKey) ?? false;
    } catch (e) {
      debugPrint('❌ Erro ao obter status de termos: $e');
      return false;
    }
  }

  /// Salva que a permissão de contatos foi concedida
  static Future<void> setContactsPermissionGranted(bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_contactsPermissionKey, granted);
      debugPrint(
        '💾 Permissão de contatos: ${granted ? "✅ Concedida" : "❌ Negada"}',
      );
    } catch (e) {
      debugPrint('❌ Erro ao salvar permissão de contatos: $e');
    }
  }

  /// Verifica se a permissão de contatos foi concedida anteriormente
  static Future<bool> getContactsPermissionGranted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_contactsPermissionKey) ?? false;
    } catch (e) {
      debugPrint('❌ Erro ao obter permissão de contatos: $e');
      return false;
    }
  }

  /// Salva que a permissão de notificações foi concedida
  static Future<void> setNotificationPermissionGranted(bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationPermissionKey, granted);
      debugPrint(
        '💾 Permissão de notificações: ${granted ? "✅ Concedida" : "❌ Negada"}',
      );
    } catch (e) {
      debugPrint('❌ Erro ao salvar permissão de notificações: $e');
    }
  }

  /// Verifica se a permissão de notificações foi concedida anteriormente
  static Future<bool> getNotificationPermissionGranted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_notificationPermissionKey) ?? false;
    } catch (e) {
      debugPrint('❌ Erro ao obter permissão de notificações: $e');
      return false;
    }
  }

  /// Salva que a permissão de telefone foi concedida
  static Future<void> setPhonePermissionGranted(bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_phonePermissionKey, granted);
      debugPrint(
        '💾 Permissão de telefone: ${granted ? "✅ Concedida" : "❌ Negada"}',
      );
    } catch (e) {
      debugPrint('❌ Erro ao salvar permissão de telefone: $e');
    }
  }

  /// Verifica se a permissão de telefone foi concedida anteriormente
  static Future<bool> getPhonePermissionGranted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_phonePermissionKey) ?? false;
    } catch (e) {
      debugPrint('❌ Erro ao obter permissão de telefone: $e');
      return false;
    }
  }

  /// Obter todas as permissões que foram aceitas
  static Future<Map<String, bool>> getAllPermissionsStatus() async {
    return {
      'terms_accepted': await getTermsAccepted(),
      'contacts_permission': await getContactsPermissionGranted(),
      'notification_permission': await getNotificationPermissionGranted(),
      'phone_permission': await getPhonePermissionGranted(),
    };
  }

  /// Restaurar todas as permissões de uma vez
  static Future<void> restoreAllPermissions({
    required bool termsAccepted,
    required bool contactsPermission,
    required bool notificationPermission,
    required bool phonePermission,
  }) async {
    try {
      await setTermsAccepted(termsAccepted);
      await setContactsPermissionGranted(contactsPermission);
      await setNotificationPermissionGranted(notificationPermission);
      await setPhonePermissionGranted(phonePermission);
      debugPrint('✅ Todas as permissões foram restauradas');
    } catch (e) {
      debugPrint('❌ Erro ao restaurar permissões: $e');
    }
  }
}
