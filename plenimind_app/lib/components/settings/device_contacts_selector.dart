import 'package:flutter/material.dart';
import 'package:plenimind_app/service/contact_service.dart';
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';

class DeviceContactsSelector extends StatefulWidget {
  final String userId;
  final List<EmergencyContact> initialContacts;
  final Function(List<EmergencyContact>) onContactsSelected;
  final double screenWidth;

  const DeviceContactsSelector({
    super.key,
    required this.userId,
    required this.initialContacts,
    required this.onContactsSelected,
    required this.screenWidth,
  });

  @override
  State<DeviceContactsSelector> createState() => _DeviceContactsSelectorState();
}

class _DeviceContactsSelectorState extends State<DeviceContactsSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EmergencyContact> _deviceContacts = [];
  List<EmergencyContact> _selectedContacts = [];
  bool _isLoading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedContacts = List.from(widget.initialContacts);
    _loadDeviceContacts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceContacts() async {
    try {
      setState(() {
        _isLoading = true;
        _permissionDenied = false;
      });

      final deviceContacts = await ContactService.getDeviceContacts();
      final selectedPhones = _selectedContacts.map((c) => c.phone).toSet();

      // Marcar contatos do dispositivo que já estão selecionados
      for (var contact in deviceContacts) {
        if (selectedPhones.contains(contact.phone)) {
          // Já está em _selectedContacts
        }
      }

      setState(() {
        _deviceContacts = deviceContacts;
      });
    } catch (e) {
      final msg = e.toString();
      if (msg.toLowerCase().contains('permiss') ||
          msg.toLowerCase().contains('negada')) {
        setState(() {
          _permissionDenied = true;
          _deviceContacts = [];
        });
      } else {
        debugPrint('❌ Erro ao carregar contatos do dispositivo: $e');
        setState(() {
          _deviceContacts = [];
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleContact(EmergencyContact contact) {
    setState(() {
      final index = _selectedContacts.indexWhere(
        (c) => c.phone == contact.phone,
      );
      if (index >= 0) {
        _selectedContacts.removeAt(index);
      } else {
        final newContact = EmergencyContact(
          id: '${widget.userId}_contact_${DateTime.now().millisecondsSinceEpoch}',
          name: contact.name,
          phone: contact.phone,
          imageUrl: contact.imageUrl,
          priority: _selectedContacts.length + 1,
        );
        _selectedContacts.add(newContact);
      }
    });
    widget.onContactsSelected(_selectedContacts);
  }

  bool _isContactSelected(EmergencyContact contact) {
    return _selectedContacts.any((c) => c.phone == contact.phone);
  }

  void _updateContactPriority(String contactId, int newPriority) {
    setState(() {
      final contactIndex = _selectedContacts.indexWhere(
        (c) => c.id == contactId,
      );
      if (contactIndex != -1) {
        _selectedContacts[contactIndex] = EmergencyContact(
          id: _selectedContacts[contactIndex].id,
          name: _selectedContacts[contactIndex].name,
          phone: _selectedContacts[contactIndex].phone,
          imageUrl: _selectedContacts[contactIndex].imageUrl,
          priority: newPriority,
        );
        _sortSelectedContactsByPriority();
      }
    });
    widget.onContactsSelected(_selectedContacts);
  }

  void _removeSelectedContact(String contactId) {
    setState(() {
      _selectedContacts.removeWhere((contact) => contact.id == contactId);
      _recalculatePriorities();
    });
    widget.onContactsSelected(_selectedContacts);
  }

  void _sortSelectedContactsByPriority() {
    _selectedContacts.sort((a, b) => a.priority.compareTo(b.priority));
  }

  void _recalculatePriorities() {
    for (int i = 0; i < _selectedContacts.length; i++) {
      _selectedContacts[i] = EmergencyContact(
        id: _selectedContacts[i].id,
        name: _selectedContacts[i].name,
        phone: _selectedContacts[i].phone,
        imageUrl: _selectedContacts[i].imageUrl,
        priority: i + 1,
      );
    }
  }

  Widget _buildDeviceContactsList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.no_accounts, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Permissão de Contatos Negada',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Habilite o acesso aos contatos para adicionar contatos de emergência do seu dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_deviceContacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Nenhum contato encontrado no dispositivo',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _deviceContacts.length,
      itemBuilder: (context, index) {
        final contact = _deviceContacts[index];
        final isSelected = _isContactSelected(contact);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, color: Colors.blue),
            ),
            title: Text(contact.name),
            subtitle: Text(contact.phone),
            trailing: Checkbox(
              value: isSelected,
              onChanged: (value) {
                _toggleContact(contact);
              },
            ),
            onTap: () {
              _toggleContact(contact);
            },
          ),
        );
      },
    );
  }

  Widget _buildSelectedContactsList() {
    if (_selectedContacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.contacts, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Nenhum contato selecionado',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Selecione contatos na aba "Contatos do Dispositivo" para vê-los aqui com suas prioridades.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _selectedContacts.length,
      itemBuilder: (context, index) {
        final contact = _selectedContacts[index];

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green[100],
              child: Text(
                contact.priority.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ),
            title: Text(contact.name),
            subtitle: Text(contact.phone),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botão para aumentar prioridade
                if (contact.priority > 1)
                  IconButton(
                    icon: Icon(Icons.arrow_upward, color: Colors.green),
                    onPressed: () {
                      _updateContactPriority(contact.id, contact.priority - 1);
                    },
                  ),
                // Botão para diminuir prioridade
                if (contact.priority < _selectedContacts.length)
                  IconButton(
                    icon: Icon(Icons.arrow_downward, color: Colors.orange),
                    onPressed: () {
                      _updateContactPriority(contact.id, contact.priority + 1);
                    },
                  ),
                // Botão para remover
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _removeSelectedContact(contact.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Contatos do Dispositivo'),
            Tab(text: 'Contatos Selecionados (${_selectedContacts.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDeviceContactsList(),
              _buildSelectedContactsList(),
            ],
          ),
        ),
      ],
    );
  }
}
