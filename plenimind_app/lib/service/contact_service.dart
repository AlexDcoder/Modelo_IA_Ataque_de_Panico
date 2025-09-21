// lib/services/contact_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart' as ContactsLib;
import 'package:plenimind_app/schemas/contacts/contact.dart';

class ContactService {
  static const String _storageKey = 'user_emergency_contacts';

  // Busca contatos salvos do usuário
  static Future<List<Contact>> getEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_storageKey);
      
      if (savedData != null) {
        final List<dynamic> jsonList = json.decode(savedData);
        return jsonList.map((json) => Contact.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Erro ao carregar contatos: $e');
    }
  }

  // Salva contatos de emergência
  static Future<void> saveEmergencyContacts(List<Contact> contacts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = contacts.map((c) => c.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      throw Exception('Erro ao salvar contatos: $e');
    }
  }

  // Busca contatos do celular e converte para nosso modelo
  static Future<List<Contact>> getDeviceContacts() async {
    try {
      final permission = await Permission.contacts.request();
      if (!permission.isGranted) {
        throw Exception('Permissão negada');
      }

      // Agora usando ContactsLib.ContactsService (da biblioteca)
      final deviceContacts = await ContactsLib.ContactsService.getContacts(withThumbnails: false);
      
      // Converte contatos do celular para nosso modelo Contact
      return deviceContacts
          .where((c) => 
              c.phones?.isNotEmpty == true && 
              c.displayName?.isNotEmpty == true)
          .map((deviceContact) => Contact( // ← Este é SEU modelo
                id: deviceContact.identifier ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: deviceContact.displayName!,
                phone: deviceContact.phones!.first.value ?? '',
                imageUrl: '', // Sem foto por enquanto
                priority: 0, // Será definido ao salvar
              ))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar contatos do dispositivo: $e');
    }
  }

  // Remove um contato de emergência específico
  static Future<void> removeEmergencyContact(String contactId) async {
    try {
      final contacts = await getEmergencyContacts();
      final updatedContacts = contacts.where((c) => c.id != contactId).toList();
      await saveEmergencyContacts(updatedContacts);
    } catch (e) {
      throw Exception('Erro ao remover contato: $e');
    }
  }

  // Verifica se um número já é contato de emergência
  static Future<bool> isEmergencyContact(String phone) async {
    try {
      final contacts = await getEmergencyContacts();
      return contacts.any((c) => c.phone == phone);
    } catch (e) {
      return false;
    }
  }
}