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
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ContactPage extends StatefulWidget {
  static const String routePath = '/contacts';
  
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  List<Contact> _contacts = [];
  final Set<int> _selectedIndexes = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeContacts();
  }

  Future<void> _initializeContacts() async {
    await _loadContacts();
    await _loadSaved();
    setState(() => _isLoading = false);
  }

  Future<void> _loadContacts() async {
    try {
      final permission = await Permission.contacts.request();
      if (permission.isGranted) {
        final all = await ContactsService.getContacts(withThumbnails: false);
        // Filtra apenas contatos com telefone
        final validContacts = all.where((c) => 
          c.phones!.isNotEmpty && 
          (c.displayName?.isNotEmpty ?? false)
        ).toList();
        
        setState(() => _contacts = validContacts);
      } else {
        _showSnackBar("Permissão para acessar contatos negada");
      }
    } catch (e) {
      _showSnackBar("Erro ao carregar contatos: $e");
    }
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString("emergency_contacts");
      if (saved != null) {
        final list = json.decode(saved) as List;
        setState(() {
          _selectedIndexes.clear();
          for (var phone in list) {
            final index = _contacts.indexWhere((c) =>
                c.phones!.isNotEmpty && c.phones!.first.value == phone);
            if (index >= 0) _selectedIndexes.add(index);
          }
        });
      }
    } catch (e) {
      _showSnackBar("Erro ao carregar contatos salvos: $e");
    }
  }

  Future<void> _saveSelection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedPhones = _selectedIndexes.map((i) {
        return _contacts[i].phones!.isNotEmpty ? _contacts[i].phones!.first.value ?? "" : "";
      }).where((p) => p.isNotEmpty).toList();

      await prefs.setString("emergency_contacts", json.encode(selectedPhones));
      _showSnackBar("Contatos de emergência salvos (${selectedPhones.length})");
    } catch (e) {
      _showSnackBar("Erro ao salvar contatos: $e");
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        if (_selectedIndexes.length < 5) {
          _selectedIndexes.add(index);
        } else {
          _showSnackBar("Máximo de 5 contatos permitidos");
        }
      }
    });
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Contatos de Emergência"),
            if (_selectedIndexes.isNotEmpty)
              Text(
                "${_selectedIndexes.length}/5 selecionados",
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _selectedIndexes.isNotEmpty ? _saveSelection : null,
            tooltip: "Salvar seleção",
          )
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Carregando contatos..."),
                ],
              ),
            )
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.contacts, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("Nenhum contato encontrado"),
                      TextButton(
                        onPressed: _loadContacts,
                        child: Text("Tentar novamente"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final c = _contacts[index];
                    final phone = c.phones!.first.value ?? "Sem número";
                    final isSelected = _selectedIndexes.contains(index);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? Colors.green : null,
                        child: Text(
                          c.displayName!.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      ),
                      title: Text(c.displayName!),
                      subtitle: Text(phone),
                      trailing: Icon(
                        isSelected ? Icons.check_circle : Icons.check_circle_outline,
                        color: isSelected ? Colors.green : Colors.grey,
                      ),
                      onTap: () => _toggleSelection(index),
                      selected: isSelected,
                      selectedTileColor: Colors.green.withOpacity(0.1),
                    );
                  },
                ),
    );
  }
}