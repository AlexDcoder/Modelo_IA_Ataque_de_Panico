import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';
import 'package:plenimind_app/schemas/dto/emergency_contact_dto.dart';
import 'package:plenimind_app/service/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:plenimind_app/core/auth/permission_manager.dart';

class ContactService {
  static String _getStorageKey(String userId) {
    return 'user_${userId}_emergency_contacts';
  }

  static Future<List<EmergencyContact>> getEmergencyContacts(
    String userId,
  ) async {
    try {
      debugPrint(
        '🔄 [CONTACT_SERVICE] Buscando contatos para usuário: $userId',
      );
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_getStorageKey(userId));

      if (savedData != null) {
        final List jsonList = json.decode(savedData);
        final contacts =
            jsonList.map((json) => EmergencyContact.fromJson(json)).toList();
        debugPrint(
          '✅ [CONTACT_SERVICE] ${contacts.length} contatos carregados do storage',
        );
        return contacts;
      } else {
        debugPrint(
          'ℹ️ [CONTACT_SERVICE] Nenhum contato salvo encontrado para usuário: $userId',
        );
        return [];
      }
    } catch (e) {
      debugPrint('❌ [CONTACT_SERVICE] Erro ao carregar contatos salvos: $e');
      return [];
    }
  }

  static Future<bool> saveAndSyncEmergencyContacts(
    List<EmergencyContact> contacts,
    String userId,
  ) async {
    try {
      debugPrint(
        '🔄 [CONTACT_SERVICE] Salvando e sincronizando ${contacts.length} contatos para: $userId',
      );

      // Salvar localmente
      await saveEmergencyContacts(contacts, userId);

      debugPrint('✅ [CONTACT_SERVICE] Contatos salvos localmente com sucesso');
      return true;
    } catch (e) {
      debugPrint('❌ [CONTACT_SERVICE] Erro ao salvar contatos: $e');
      return false;
    }
  }

  static Future<void> saveEmergencyContacts(
    List<EmergencyContact> contacts,
    String userId,
  ) async {
    try {
      debugPrint(
        '🔄 [CONTACT_SERVICE] Salvando ${contacts.length} contatos para usuário: $userId',
      );

      for (var contact in contacts) {
        debugPrint(
          '   💾 Salvando: ${contact.name} - ${contact.phone} (Prioridade: ${contact.priority})',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final jsonList = contacts.map((c) => c.toJson()).toList();
      await prefs.setString(_getStorageKey(userId), json.encode(jsonList));
      debugPrint(
        '✅ [CONTACT_SERVICE] Contatos salvos com sucesso no storage local',
      );
    } catch (e) {
      debugPrint('❌ [CONTACT_SERVICE] Erro ao salvar contatos: $e');
      throw Exception('Erro ao salvar contatos de emergência: $e');
    }
  }

  static Future<bool> syncContactsWithServer({
    required String userId,
    required List<EmergencyContact> contacts,
    required UserService userService,
  }) async {
    try {
      debugPrint(
        '🔄 [CONTACT_SERVICE] Sincronizando ${contacts.length} contatos com servidor',
      );

      // Converter para DTO
      final emergencyContactsDTO =
          contacts.map((contact) => contact.toDTO()).toList();

      // Atualizar no servidor
      final result = await userService.updateUserEmergencyContacts(
        uid: userId,
        emergencyContacts: emergencyContactsDTO,
      );

      if (result != null) {
        debugPrint(
          '✅ [CONTACT_SERVICE] Contatos sincronizados com servidor com sucesso',
        );
        return true;
      } else {
        debugPrint('❌ [CONTACT_SERVICE] Falha na sincronização com servidor');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [CONTACT_SERVICE] Erro na sincronização: $e');
      return false;
    }
  }

  static List<EmergencyContactDTO> toDTOList(List<EmergencyContact> contacts) {
    debugPrint(
      '🔄 [CONTACT_SERVICE] Convertendo ${contacts.length} contatos para DTO',
    );
    return contacts.map((contact) => contact.toDTO()).toList();
  }

  static List<EmergencyContact> fromDTOList(
    List<EmergencyContactDTO> dtos,
    String userId,
  ) {
    debugPrint(
      '🔄 [CONTACT_SERVICE] Convertendo ${dtos.length} DTOs para EmergencyContact',
    );
    return dtos.asMap().entries.map((entry) {
      final index = entry.key;
      final dto = entry.value;
      return EmergencyContact(
        id: '${userId}_contact_$index',
        name: dto.name,
        phone: dto.phone,
        imageUrl: '',
        priority: index + 1,
      );
    }).toList();
  }

  static Future<List<EmergencyContact>> getDeviceContacts() async {
    try {
      debugPrint('🔄 [CONTACT_SERVICE] Buscando contatos do dispositivo...');

      final contactsPermission =
          await PermissionManager.getContactsPermissionGranted();
      if (!contactsPermission) {
        debugPrint(
          '❌ [CONTACT_SERVICE] Permissão de contatos não concedida nos termos',
        );
        throw Exception(
          'Permissão de contatos não concedida - Aceite nos termos de uso',
        );
      }

      var status = await Permission.contacts.status;
      if (!status.isGranted) {
        debugPrint(
          '❌ [CONTACT_SERVICE] Permissão de contatos revogada - solicitando...',
        );
        status = await Permission.contacts.request();
        if (!status.isGranted) {
          throw Exception('Permissão de contatos negada pelo usuário');
        }
      }

      debugPrint('✅ [CONTACT_SERVICE] Permissão de contatos concedida');
      final fields = ContactField.values.toList();
      final fastContacts = await FastContacts.getAllContacts(fields: fields);

      debugPrint(
        '📱 [CONTACT_SERVICE] ${fastContacts.length} contatos encontrados no dispositivo',
      );

      final contacts =
          fastContacts
              .where((f) {
                final isValid =
                    f.phones.isNotEmpty &&
                    f.displayName.isNotEmpty &&
                    _isValidPhoneNumber(f.phones.first.number);
                if (!isValid) {
                  debugPrint(
                    '   ⚠️ Contato inválido ignorado: ${f.displayName}',
                  );
                }
                return isValid;
              })
              .map((f) {
                final formattedPhone = _formatPhoneNumber(
                  f.phones.first.number,
                );
                debugPrint(
                  '   ✅ Contato válido: ${f.displayName} - $formattedPhone',
                );
                return EmergencyContact(
                  id: f.id,
                  name: f.displayName,
                  phone: formattedPhone,
                  imageUrl: '',
                  priority: 0,
                );
              })
              .toList();

      debugPrint(
        '✅ [CONTACT_SERVICE] ${contacts.length} contatos válidos processados',
      );
      return contacts;
    } catch (e) {
      debugPrint(
        '❌ [CONTACT_SERVICE] Erro ao buscar contatos do dispositivo: $e',
      );
      throw Exception(
        'Erro ao acessar contatos do dispositivo: ${e.toString()}',
      );
    }
  }

  static Future<void> removeEmergencyContact(
    String contactId,
    String userId,
  ) async {
    try {
      debugPrint(
        '🔄 [CONTACT_SERVICE] Removendo contato: $contactId do usuário: $userId',
      );
      final contacts = await getEmergencyContacts(userId);
      final updated = contacts.where((c) => c.id != contactId).toList();
      await saveEmergencyContacts(updated, userId);
      debugPrint('✅ [CONTACT_SERVICE] Contato removido com sucesso');
    } catch (e) {
      debugPrint('❌ [CONTACT_SERVICE] Erro ao remover contato: $e');
      throw Exception('Erro ao remover contato de emergência');
    }
  }

  static Future<bool> isEmergencyContact(String phone, String userId) async {
    debugPrint(
      '🔍 [CONTACT_SERVICE] Verificando se $phone é contato de emergência',
    );
    final contacts = await getEmergencyContacts(userId);
    final exists = contacts.any((c) => c.phone == phone);
    debugPrint('🔍 [CONTACT_SERVICE] Contato $phone existe: $exists');
    return exists;
  }

  static Future<void> updateContactPriority(
    String contactId,
    int newPriority,
    String userId,
  ) async {
    try {
      debugPrint(
        '🔄 [CONTACT_SERVICE] Atualizando prioridade do contato: $contactId para $newPriority',
      );
      final contacts = await getEmergencyContacts(userId);
      final contactIndex = contacts.indexWhere((c) => c.id == contactId);

      if (contactIndex != -1) {
        final updatedContact = EmergencyContact(
          id: contacts[contactIndex].id,
          name: contacts[contactIndex].name,
          phone: contacts[contactIndex].phone,
          imageUrl: contacts[contactIndex].imageUrl,
          priority: newPriority,
        );

        contacts[contactIndex] = updatedContact;
        await saveEmergencyContacts(contacts, userId);
        debugPrint('✅ [CONTACT_SERVICE] Prioridade atualizada com sucesso');
      } else {
        debugPrint('❌ [CONTACT_SERVICE] Contato não encontrado: $contactId');
      }
    } catch (e) {
      debugPrint('❌ [CONTACT_SERVICE] Erro ao atualizar prioridade: $e');
    }
  }

  static List<EmergencyContact> sortByPriority(
    List<EmergencyContact> contacts,
  ) {
    debugPrint(
      '🔄 [CONTACT_SERVICE] Ordenando ${contacts.length} contatos por prioridade',
    );

    List<EmergencyContact> sorted = List<EmergencyContact>.from(contacts);
    sorted.sort((a, b) => a.priority.compareTo(b.priority));

    debugPrint('✅ [CONTACT_SERVICE] Contatos ordenados por prioridade');
    return sorted;
  }

  static EmergencyContact? getContactById(
    List<EmergencyContact> contacts,
    String contactId,
  ) {
    try {
      debugPrint('🔍 [CONTACT_SERVICE] Buscando contato por ID: $contactId');
      final contact = contacts.firstWhere((contact) => contact.id == contactId);
      debugPrint('✅ [CONTACT_SERVICE] Contato encontrado: ${contact.name}');
      return contact;
    } catch (e) {
      debugPrint('❌ [CONTACT_SERVICE] Contato não encontrado: $contactId');
      return null;
    }
  }

  static Future<void> addEmergencyContact(
    EmergencyContact contact,
    String userId,
  ) async {
    try {
      debugPrint(
        '🔄 [CONTACT_SERVICE] Adicionando novo contato: ${contact.name}',
      );
      final contacts = await getEmergencyContacts(userId);

      if (contacts.any((c) => c.phone == contact.phone)) {
        debugPrint(
          '❌ [CONTACT_SERVICE] Contato já existe na lista: ${contact.phone}',
        );
        throw Exception('Contato já existe na lista de emergência');
      }

      contacts.add(contact);
      await saveEmergencyContacts(contacts, userId);
      debugPrint('✅ [CONTACT_SERVICE] Contato adicionado com sucesso');
    } catch (e) {
      debugPrint('❌ [CONTACT_SERVICE] Erro ao adicionar contato: $e');
      rethrow;
    }
  }

  static bool _isValidPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final isValid = cleaned.length >= 10;
    if (!isValid) {
      debugPrint('   📞 Número inválido: $phone (limpo: $cleaned)');
    }
    return isValid;
  }

  static String _formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    String formatted;

    if (!cleaned.startsWith('+')) {
      formatted = '+55$cleaned';
      debugPrint('   🔄 Número formatado: $phone → $formatted');
    } else {
      formatted = cleaned;
    }

    return formatted;
  }
}
