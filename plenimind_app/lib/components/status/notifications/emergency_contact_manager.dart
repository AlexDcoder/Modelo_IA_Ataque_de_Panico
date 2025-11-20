// emergency_contact_manager.dart - Adicionar suporte para callback de atualização
import 'package:flutter/material.dart';
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';

class EmergencyContactManager extends StatefulWidget {
  final List<EmergencyContact> initialContacts;
  final Function(List<EmergencyContact>) onContactsUpdated;
  final double screenWidth;
  final String userId;

  const EmergencyContactManager({
    Key? key,
    required this.initialContacts,
    required this.onContactsUpdated,
    required this.screenWidth,
    required this.userId,
  }) : super(key: key);

  @override
  State<EmergencyContactManager> createState() =>
      _EmergencyContactManagerState();
}

class _EmergencyContactManagerState extends State<EmergencyContactManager> {
  late List<EmergencyContact> _contacts;

  @override
  void initState() {
    super.initState();
    _contacts = List.from(widget.initialContacts);
  }

  void _updateContacts() {
    widget.onContactsUpdated(List.from(_contacts));
  }

  void _removeContact(int index) {
    setState(() {
      _contacts.removeAt(index);
      _updatePriorities();
      _updateContacts();
    });
  }

  void _updatePriorities() {
    for (int i = 0; i < _contacts.length; i++) {
      _contacts[i] = EmergencyContact(
        id: _contacts[i].id,
        name: _contacts[i].name,
        phone: _contacts[i].phone,
        imageUrl: _contacts[i].imageUrl,
        priority: i + 1,
      );
    }
  }

  void _reorderContacts(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final EmergencyContact item = _contacts.removeAt(oldIndex);
      _contacts.insert(newIndex, item);
      _updatePriorities();
      _updateContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_contacts.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contacts,
                    size: widget.screenWidth * 0.15,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum contato de emergência',
                    style: TextStyle(
                      fontSize: widget.screenWidth * 0.04,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Adicione contatos para serem notificados em emergências',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: widget.screenWidth * 0.035,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ReorderableListView(
              onReorder: _reorderContacts,
              children: [
                for (int index = 0; index < _contacts.length; index++)
                  ListTile(
                    key: Key(_contacts[index].id),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        '${_contacts[index].priority}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      _contacts[index].name,
                      style: TextStyle(
                        fontSize: widget.screenWidth * 0.04,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      _contacts[index].phone,
                      style: TextStyle(fontSize: widget.screenWidth * 0.035),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: widget.screenWidth * 0.05,
                      ),
                      onPressed: () => _removeContact(index),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
