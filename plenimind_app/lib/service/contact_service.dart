import 'dart:convert';
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';
import 'package:plenimind_app/schemas/dto/emergency_contact_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fast_contacts/fast_contacts.dart';

class ContactService {
  static String _getStorageKey(String userId) {
    return 'user_${userId}_emergency_contacts';
  }

  /// Recupera os contatos de emergência salvos (se houver)
  static Future<List<EmergencyContact>> getEmergencyContacts(
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_getStorageKey(userId));
    if (savedData != null) {
      try {
        final List jsonList = json.decode(savedData);
        return jsonList.map((json) => EmergencyContact.fromJson(json)).toList();
      } catch (e) {
        print('❌ Erro ao decodificar contatos salvos: $e');
        return [];
      }
    }
    return [];
  }

  /// Salva contatos de emergência localmente
  static Future<void> saveEmergencyContacts(
    List<EmergencyContact> contacts,
    String userId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = contacts.map((c) => c.toJson()).toList();
      await prefs.setString(_getStorageKey(userId), json.encode(jsonList));
      print('✅ ${contacts.length} contatos de emergência salvos');
    } catch (e) {
      print('❌ Erro ao salvar contatos: $e');
      throw Exception('Erro ao salvar contatos de emergência');
    }
  }

  /// Converte EmergencyContact para DTO (para envio à API)
  static List<EmergencyContactDTO> toDTOList(List<EmergencyContact> contacts) {
    return contacts.map((contact) => contact.toDTO()).toList();
  }

  /// Converte DTO para EmergencyContact (para uso interno)
  static List<EmergencyContact> fromDTOList(
    List<EmergencyContactDTO> dtos,
    String userId,
  ) {
    return dtos.asMap().entries.map((entry) {
      final index = entry.key;
      final dto = entry.value;
      return EmergencyContact(
        id: '${userId}_contact_$index',
        name: dto.name,
        phone: dto.phone,
        imageUrl: '', // Definir imagem padrão ou deixar vazio
        priority: index, // Prioridade baseada na ordem
      );
    }).toList();
  }

  /// Recupera contatos do dispositivo usando fast_contacts
  static Future<List<EmergencyContact>> getDeviceContacts() async {
    try {
      var status = await Permission.contacts.status;
      if (!status.isGranted) {
        status = await Permission.contacts.request();
        if (!status.isGranted) {
          throw Exception('Permissão de contatos negada');
        }
      }

      final fields = ContactField.values.toList();
      final fastContacts = await FastContacts.getAllContacts(fields: fields);

      final contacts =
          fastContacts
              .where((f) {
                return f.phones.isNotEmpty &&
                    f.displayName.isNotEmpty &&
                    _isValidPhoneNumber(f.phones.first.number);
              })
              .map((f) {
                return EmergencyContact(
                  id: f.id,
                  name: f.displayName,
                  phone: _formatPhoneNumber(f.phones.first.number),
                  imageUrl: '', // Contatos do dispositivo não têm imagem
                  priority: 0, // Prioridade será definida pelo usuário
                );
              })
              .toList();

      return contacts; // ✅ Explicit return
    } catch (e) {
      print('❌ Erro ao buscar contatos do dispositivo: $e');
      throw Exception('Erro ao acessar contatos do dispositivo');
    }
  }

  /// Remove um contato da lista de emergência
  static Future<void> removeEmergencyContact(
    String contactId,
    String userId,
  ) async {
    try {
      final contacts = await getEmergencyContacts(userId);
      final updated = contacts.where((c) => c.id != contactId).toList();
      await saveEmergencyContacts(updated, userId);
      print('✅ Contato removido com sucesso');
    } catch (e) {
      print('❌ Erro ao remover contato: $e');
      throw Exception('Erro ao remover contato de emergência');
    }
  }

  /// Verifica se um número já está na lista de emergência
  static Future<bool> isEmergencyContact(String phone, String userId) async {
    final contacts = await getEmergencyContacts(userId);
    return contacts.any((c) => c.phone == phone);
  }

  /// Atualiza a prioridade dos contatos
  static Future<void> updateContactPriority(
    String contactId,
    int newPriority,
    String userId,
  ) async {
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
    }
  }

  /// Ordena contatos por prioridade (para chamadas de emergência)
  static List<EmergencyContact> sortByPriority(
    List<EmergencyContact> contacts,
  ) {
    return List.from(contacts)
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Valida número de telefone
  static bool _isValidPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return cleaned.length >= 10;
  }

  /// Formata número de telefone
  static String _formatPhoneNumber(String phone) {
    // Remove caracteres não numéricos exceto +
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Se não começar com +, adiciona código do país padrão (Brasil)
    if (!cleaned.startsWith('+')) {
      return '+55$cleaned';
    }

    return cleaned;
  }

  /// Busca contato por ID
  static EmergencyContact? getContactById(
    List<EmergencyContact> contacts,
    String contactId,
  ) {
    try {
      return contacts.firstWhere((contact) => contact.id == contactId);
    } catch (e) {
      return null;
    }
  }

  /// Adiciona um novo contato de emergência
  static Future<void> addEmergencyContact(
    EmergencyContact contact,
    String userId,
  ) async {
    final contacts = await getEmergencyContacts(userId);

    // Verifica se o contato já existe
    if (contacts.any((c) => c.phone == contact.phone)) {
      throw Exception('Contato já existe na lista de emergência');
    }

    contacts.add(contact);
    await saveEmergencyContacts(contacts, userId);
  }
}
