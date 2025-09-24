// lib/services/contact_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fast_contacts/fast_contacts.dart' as fc;

import 'package:plenimind_app/schemas/contacts/contact.dart';

class ContactService {
  static const String _storageKey = 'user_emergency_contacts';

  /// Recupera os contatos de emergência salvos (se houver)
  static Future<List<Contact>> getEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_storageKey);
    if (savedData != null) {
      final List jsonList = json.decode(savedData);
      return jsonList.map((json) => Contact.fromJson(json)).toList();
    }
    return [];
  }

  /// Salva contatos de emergência localmente
  static Future<void> saveEmergencyContacts(List<Contact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = contacts.map((c) => c.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }

  /// Recupera contatos do dispositivo usando fast_contacts
  static Future<List<Contact>> getDeviceContacts() async {
    // pedir permissão
    var status = await Permission.contacts.status;
    if (!status.isGranted) {
      status = await Permission.contacts.request();
      if (!status.isGranted) {
        throw Exception('Permissão de contatos negada');
      }
    }

    // buscar contatos via fast_contacts
    final fields = fc.ContactField.values.toList();
    final fastContacts = await fc.FastContacts.getAllContacts(fields: fields);

    // converter para o seu modelo Contact
    return fastContacts.where((f) {
      return f.phones.isNotEmpty && f.displayName.isNotEmpty;
    }).map((f) {
      return Contact(
        id: f.id,
        name: f.displayName,
        phone: f.phones.isNotEmpty ? f.phones.first.number : '',
        imageUrl: '', // opcional: pode usar fc.FastContacts.getContactImage(f.id)
        priority: 0,
      );
    }).toList();
  }

  /// Remove um contato da lista de emergência
  static Future<void> removeEmergencyContact(String contactId) async {
    final contacts = await getEmergencyContacts();
    final updated = contacts.where((c) => c.id != contactId).toList();
    await saveEmergencyContacts(updated);
  }

  /// Verifica se um número já está na lista de emergência
  static Future<bool> isEmergencyContact(String phone) async {
    final contacts = await getEmergencyContacts();
    return contacts.any((c) => c.phone == phone);
  }
}
