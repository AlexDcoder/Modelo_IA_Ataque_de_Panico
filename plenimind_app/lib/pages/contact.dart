// import 'package:flutter/material.dart';
// import 'package:plenimind_app/components/contact/contact_item.dart';
// import 'package:plenimind_app/schemas/contacts/contact.dart';

// class ContactPage extends StatefulWidget {
//   static String routeName = 'ContactPage';
//   static String routePath = '/contactPage';
//   const ContactPage({super.key});

//   @override
//   State<ContactPage> createState() => _ContactPageState();
// }

// class _ContactPageState extends State<ContactPage> {
//   final TextEditingController _searchController = TextEditingController();

//   // Lista encadeada para contatos selecionados (máximo 5)
//   final ContactLinkedList _selectedContacts = ContactLinkedList(maxSize: 5);

//   final List<Contact> contacts = [
//     Contact("Alice Silva", "(123) 456-7890", "https://via.placeholder.com/150"),
//     Contact("Bruno Costa", "(321) 654-0987", "https://via.placeholder.com/150"),
//     Contact("Carla Souza", "(987) 654-3210", "https://via.placeholder.com/150"),
//     Contact("Diego Lima", "(555) 123-4567", "https://via.placeholder.com/150"),
//     Contact(
//       "Fernanda Reis",
//       "(111) 222-3333",
//       "https://via.placeholder.com/150",
//     ),
//     Contact(
//       "Gustavo Rocha",
//       "(999) 888-7777",
//       "https://via.placeholder.com/150",
//     ),
//     Contact(
//       "Helena Santos",
//       "(444) 555-6666",
//       "https://via.placeholder.com/150",
//     ),
//     Contact(
//       "Igor Pereira",
//       "(777) 888-9999",
//       "https://via.placeholder.com/150",
//     ),
//   ];

//   List<Contact> filteredContacts = [];

//   @override
//   void initState() {
//     super.initState();
//     filteredContacts = contacts;
//   }

//   void _filterContacts(String query) {
//     setState(() {
//       filteredContacts =
//           contacts
//               .where(
//                 (c) =>
//                     c.name.toLowerCase().contains(query.toLowerCase()) ||
//                     c.phone
//                         .replaceAll(RegExp(r'[^0-9]'), '')
//                         .contains(query.replaceAll(RegExp(r'[^0-9]'), '')),
//               )
//               .toList();
//     });
//   }

//   void _onContactSelected(Contact contact, bool selected) {
//     setState(() {
//       if (selected) {
//         // Tenta adicionar no final da lista
//         bool added = _selectedContacts.addLast(contact);
//         if (!added) {
//           // Mostra mensagem se a lista estiver cheia
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 "Máximo de ${_selectedContacts.maxSize} contatos permitido!",
//               ),
//               backgroundColor: Colors.orange,
//             ),
//           );
//           return;
//         }
//         contact.isSelected = true;
//       } else {
//         // Remove da lista
//         _selectedContacts.remove(contact.name);
//         contact.isSelected = false;
//       }
//     });
//   }

//   void _onReorderSelectedContacts(int oldIndex, int newIndex) {
//     setState(() {
//       List<Contact> selectedList = _selectedContacts.toList();
//       if (newIndex > oldIndex) newIndex--;
//       final item = selectedList.removeAt(oldIndex);
//       selectedList.insert(newIndex, item);
//       _selectedContacts.reorder(selectedList);
//     });
//   }

//   void _saveContacts() {
//     final selectedList = _selectedContacts.toList();
//     final selectedNames = selectedList.map((c) => c.name).toList();

//     debugPrint("Ordem de emergência salva: $selectedNames");
//     debugPrint("Total de contatos: ${_selectedContacts.size}");

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("Ordem salva: ${selectedNames.join(" → ")}"),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _clearSelection() {
//     setState(() {
//       _selectedContacts.clear();
//       for (var contact in contacts) {
//         contact.isSelected = false;
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final selectedList = _selectedContacts.toList();

//     return Scaffold(
//       appBar: AppBar(
//         leading: const BackButton(color: Colors.black),
//         title: const Text("Contatos", style: TextStyle(color: Colors.black)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           if (_selectedContacts.size > 0)
//             TextButton(
//               onPressed: _clearSelection,
//               child: const Text("Limpar", style: TextStyle(color: Colors.red)),
//             ),
//         ],
//       ),
//       body: Column(
//         children: [
//           /// AVISO
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(12),
//             color: Colors.yellow[100],
//             child: Text(
//               "⚠️ Selecione até ${_selectedContacts.maxSize} contatos. A ordem será usada para ligações de emergência.",
//               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//             ),
//           ),

//           /// CONTADOR DE SELECIONADOS
//           if (_selectedContacts.size > 0)
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(8),
//               color: Colors.green[50],
//               child: Text(
//                 "📱 Selecionados: ${_selectedContacts.size}/${_selectedContacts.maxSize}",
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),

//           /// LISTA DE CONTATOS SELECIONADOS (REORDENÁVEL)
//           if (selectedList.isNotEmpty) ...[
//             const Padding(
//               padding: EdgeInsets.all(8.0),
//               child: Text(
//                 "Ordem de Emergência (arraste para reordenar):",
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ),
//             Container(
//               height: 120,
//               padding: const EdgeInsets.symmetric(horizontal: 8),
//               child: ReorderableListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: selectedList.length,
//                 onReorder: _onReorderSelectedContacts,
//                 itemBuilder: (context, index) {
//                   final contact = selectedList[index];
//                   return Container(
//                     key: ValueKey("selected_${contact.name}"),
//                     width: 80,
//                     margin: const EdgeInsets.symmetric(horizontal: 4),
//                     child: Column(
//                       children: [
//                         CircleAvatar(
//                           radius: 25,
//                           backgroundImage: NetworkImage(contact.imageUrl),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           "${index + 1}°",
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.green,
//                           ),
//                         ),
//                         Text(
//                           contact.name.split(' ').first,
//                           style: const TextStyle(fontSize: 10),
//                           textAlign: TextAlign.center,
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//             const Divider(),
//           ],

//           /// Barra de busca
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: SearchBar(
//               controller: _searchController,
//               onChanged: _filterContacts,
//             ),
//           ),

//           /// Lista de todos os contatos
//           Expanded(
//             child: ListView.builder(
//               itemCount: filteredContacts.length,
//               itemBuilder: (context, index) {
//                 final contact = filteredContacts[index];
//                 final isSelected = _selectedContacts.contains(contact.name);

//                 return ContactItem(
//                   contact: contact,
//                   isSelected: isSelected,
//                   onChanged:
//                       (selected) =>
//                           _onContactSelected(contact, selected ?? false),
//                   isDisabled: !isSelected && _selectedContacts.isFull,
//                 );
//               },
//             ),
//           ),

//           /// Botão inferior
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: SizedBox(
//               width: double.infinity,
//               height: 48,
//               child: ElevatedButton(
//                 onPressed: _selectedContacts.size > 0 ? _saveContacts : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: Text(
//                   "Salvar Ordem de Contatos (${_selectedContacts.size})",
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:plenimind_app/service/contact_service.dart';
import 'package:plenimind_app/components/contact/contact_item.dart';
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactPage extends StatefulWidget {
  static const String routePath = '/contacts';
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  List<EmergencyContact> _deviceContacts = [];
  List<EmergencyContact> _emergencyContacts = [];
  final Set<String> _selectedContactIds = {};
  bool _isLoading = true;
  bool _permissionDenied = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Carrega contatos salvos como emergência
      final emergencyContacts = await ContactService.getEmergencyContacts();

      // Carrega contatos do celular (ContactService já pede permissão)
      final deviceContacts = await ContactService.getDeviceContacts();

      final emergencyPhones = emergencyContacts.map((c) => c.phone).toSet();

      setState(() {
        _emergencyContacts = emergencyContacts;
        _deviceContacts = deviceContacts;
        _selectedContactIds.clear();

        // Seleciona automaticamente os que são emergência
        for (final deviceContact in _deviceContacts) {
          if (emergencyPhones.contains(deviceContact.phone)) {
            _selectedContactIds.add(deviceContact.id);
          }
        }

        _permissionDenied = false;
      });
    } catch (e) {
      final msg = e.toString();
      // Detecta permissão negada (mensagem do seu service usa "Permissão")
      if (msg.toLowerCase().contains('permiss') || msg.toLowerCase().contains('negada')) {
        setState(() {
          _permissionDenied = true;
          _deviceContacts = [];
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar contatos: $e';
        });
        _showSnackBar('Erro: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSelection() async {
    try {
      final selected = _deviceContacts.where((c) => _selectedContactIds.contains(c.id)).toList();

      // Atribui prioridades (1 = mais importante)
      final contactsWithPriority = selected.asMap().entries.map((entry) {
        final index = entry.key;
        final contact = entry.value;
        return EmergencyContact(
          id: contact.id,
          name: contact.name,
          phone: contact.phone,
          imageUrl: contact.imageUrl,
          priority: index + 1,
        );
      }).toList();

      await ContactService.saveEmergencyContacts(contactsWithPriority);
      _showSnackBar('${contactsWithPriority.length} contatos de emergência salvos!');
      await _loadData();
    } catch (e) {
      _showSnackBar('Erro ao salvar: $e');
    }
  }

  void _toggleContact(String contactId, bool? selected) {
    setState(() {
      if (selected == true) {
        if (_selectedContactIds.length < 5) {
          _selectedContactIds.add(contactId);
        } else {
          _showSnackBar('Máximo 5 contatos de emergência');
        }
      } else {
        _selectedContactIds.remove(contactId);
      }
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_person, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Permissão de contatos negada.'),
            const SizedBox(height: 8),
            Text(
              'Ative a permissão em Configurações para permitir que o app leia seus contatos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => openAppSettings(),
                  child: const Text('Abrir configurações'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _loadData,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contatos de Emergência'),
            Text(
              '${_selectedContactIds.length}/5 selecionados',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _selectedContactIds.isNotEmpty ? _saveSelection : null,
            tooltip: 'Salvar contatos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _permissionDenied
              ? _buildPermissionDenied()
              : Column(
                  children: [
                    if (_emergencyContacts.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        color: Colors.green.shade50,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.emergency, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Seus Contatos de Emergência:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._emergencyContacts.map((contact) {
                              return ContactItem(
                                contact: contact,
                                isSelected: true,
                                onChanged: (value) {},
                                isDisabled: true,
                                showPriority: true,
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                    ],

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: const [
                          Icon(Icons.contacts),
                          SizedBox(width: 8),
                          Text(
                            'Escolha contatos do seu celular:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _deviceContacts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.contacts, size: 64, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  const Text('Nenhum contato encontrado'),
                                  TextButton(
                                    onPressed: _loadData,
                                    child: const Text('Tentar novamente'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _deviceContacts.length,
                              itemBuilder: (context, index) {
                                final contact = _deviceContacts[index];
                                final isSelected = _selectedContactIds.contains(contact.id);

                                return ContactItem(
                                  contact: contact,
                                  isSelected: isSelected,
                                  onChanged: (selected) => _toggleContact(contact.id, selected),
                                  // opcional: desabilitar seleção quando estiver cheio
                                  isDisabled: !isSelected && _selectedContactIds.length >= 5,
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
