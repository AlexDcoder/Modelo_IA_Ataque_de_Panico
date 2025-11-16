import 'package:flutter/material.dart'; // ✅ Adicionar esta importação
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';
import 'package:plenimind_app/service/contact_service.dart';
import 'package:plenimind_app/components/settings/settings_contact_item.dart';

class SettingsContactManagement extends StatefulWidget {
  final List<EmergencyContact> currentContacts;
  final Function(List<EmergencyContact>) onContactsUpdated;
  final double screenWidth;
  final double screenHeight;

  const SettingsContactManagement({
    super.key,
    required this.currentContacts,
    required this.onContactsUpdated,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<SettingsContactManagement> createState() =>
      _SettingsContactManagementState();
}

class _SettingsContactManagementState extends State<SettingsContactManagement> {
  List<EmergencyContact> _contacts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contacts = List.from(widget.currentContacts);
  }

  Future<void> _loadDeviceContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final deviceContacts = await ContactService.getDeviceContacts();

      // Mostrar apenas contatos que não estão já selecionados
      final currentPhones = _contacts.map((c) => c.phone).toSet();
      final availableContacts =
          deviceContacts
              .where((contact) => !currentPhones.contains(contact.phone))
              .toList();

      if (availableContacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todos os contatos disponíveis já foram adicionados'),
            backgroundColor: Colors.orange, // ✅ Agora Colors está disponível
          ),
        );
        return;
      }

      await _showAddContactDialog(availableContacts);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar contatos: $e'),
          backgroundColor: Colors.red, // ✅ Agora Colors está disponível
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddContactDialog(
    List<EmergencyContact> availableContacts,
  ) async {
    final selectedContact = await showDialog<EmergencyContact>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Adicionar Contato'),
            content: SizedBox(
              width: double.maxFinite,
              height: widget.screenHeight * 0.5,
              child: ListView.builder(
                itemCount: availableContacts.length,
                itemBuilder: (context, index) {
                  final contact = availableContacts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        contact.name.isNotEmpty
                            ? contact.name[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(contact.name),
                    subtitle: Text(contact.phone),
                    onTap: () => Navigator.pop(context, contact),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );

    if (selectedContact != null && mounted) {
      _addContact(selectedContact);
    }
  }

  void _addContact(EmergencyContact contact) {
    if (_contacts.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo de 5 contatos atingido'),
          backgroundColor: Colors.orange, // ✅ Agora Colors está disponível
        ),
      );
      return;
    }

    final newContact = EmergencyContact(
      id: contact.id,
      name: contact.name,
      phone: contact.phone,
      imageUrl: contact.imageUrl,
      priority: _contacts.length + 1,
    );

    setState(() {
      _contacts.add(newContact);
    });

    _saveContacts();
  }

  void _removeContact(String contactId) {
    setState(() {
      _contacts.removeWhere((contact) => contact.id == contactId);
      // Reorganizar prioridades
      for (int i = 0; i < _contacts.length; i++) {
        _contacts[i] = EmergencyContact(
          id: _contacts[i].id,
          name: _contacts[i].name,
          phone: _contacts[i].phone,
          imageUrl: _contacts[i].imageUrl,
          priority: i + 1,
        );
      }
    });
    _saveContacts();
  }

  void _updatePriority(String contactId, int newPriority) {
    if (newPriority < 1 || newPriority > _contacts.length) return;

    final contactIndex = _contacts.indexWhere((c) => c.id == contactId);
    if (contactIndex == -1) return;

    final currentPriority = _contacts[contactIndex].priority;

    setState(() {
      if (newPriority > currentPriority) {
        for (int i = 0; i < _contacts.length; i++) {
          if (_contacts[i].priority > currentPriority &&
              _contacts[i].priority <= newPriority) {
            _contacts[i] = EmergencyContact(
              id: _contacts[i].id,
              name: _contacts[i].name,
              phone: _contacts[i].phone,
              imageUrl: _contacts[i].imageUrl,
              priority: _contacts[i].priority - 1,
            );
          }
        }
      } else {
        for (int i = 0; i < _contacts.length; i++) {
          if (_contacts[i].priority >= newPriority &&
              _contacts[i].priority < currentPriority) {
            _contacts[i] = EmergencyContact(
              id: _contacts[i].id,
              name: _contacts[i].name,
              phone: _contacts[i].phone,
              imageUrl: _contacts[i].imageUrl,
              priority: _contacts[i].priority + 1,
            );
          }
        }
      }

      _contacts[contactIndex] = EmergencyContact(
        id: _contacts[contactIndex].id,
        name: _contacts[contactIndex].name,
        phone: _contacts[contactIndex].phone,
        imageUrl: _contacts[contactIndex].imageUrl,
        priority: newPriority,
      );

      // Ordenar por prioridade
      _contacts.sort((a, b) => a.priority.compareTo(b.priority));
    });

    _saveContacts();
  }

  void _saveContacts() {
    widget.onContactsUpdated(_contacts);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Contatos de Emergência (${_contacts.length}/5)',
              style: TextStyle(
                fontSize: widget.screenWidth * 0.045,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (_contacts.length < 5)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadDeviceContacts,
                icon:
                    _isLoading
                        ? SizedBox(
                          width: widget.screenWidth * 0.04,
                          height: widget.screenWidth * 0.04,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.add),
                label: const Text('Adicionar'),
              ),
          ],
        ),
        SizedBox(height: widget.screenWidth * 0.02),
        Text(
          'Os contatos serão contactados em ordem de prioridade (1 = primeiro)',
          style: TextStyle(
            fontSize: widget.screenWidth * 0.035,
            color: Colors.grey[600], // ✅ Agora Colors está disponível
          ),
        ),
        SizedBox(height: widget.screenWidth * 0.03),

        if (_contacts.isEmpty)
          Container(
            padding: EdgeInsets.all(widget.screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.grey[50], // ✅ Agora Colors está disponível
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color.fromARGB(255, 59, 57, 57),
              ), // ✅ Agora Colors está disponível
            ),
            child: Column(
              children: [
                Icon(
                  Icons.contacts,
                  size: widget.screenWidth * 0.1,
                  color: Colors.grey[400], // ✅ Agora Colors está disponível
                ),
                SizedBox(height: widget.screenWidth * 0.02),
                Text(
                  'Nenhum contato de emergência configurado',
                  style: TextStyle(
                    fontSize: widget.screenWidth * 0.04,
                    color: Colors.grey[600], // ✅ Agora Colors está disponível
                  ),
                ),
                SizedBox(height: widget.screenWidth * 0.02),
                Text(
                  'Adicione contatos para que possam ser acionados em caso de emergência',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: widget.screenWidth * 0.035,
                    color: Colors.grey[500], // ✅ Agora Colors está disponível
                  ),
                ),
              ],
            ),
          )
        else
          ..._contacts.map(
            (contact) => SettingsContactItem(
              contact: contact,
              onRemove: _removeContact,
              onPriorityChange: _updatePriority,
              maxPriority: _contacts.length,
              screenWidth: widget.screenWidth,
            ),
          ),
      ],
    );
  }
}
