import 'package:flutter/material.dart';
import 'package:plenimind_app/pages/terms_conditions.dart';
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
  bool _termsAccepted = false;
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
        // Se já tem contatos de emergência, considera que os termos já foram aceitos
        _termsAccepted = emergencyContacts.isNotEmpty;
      });
    } catch (e) {
      final msg = e.toString();
      // Detecta permissão negada (mensagem do seu service usa "Permissão")
      if (msg.toLowerCase().contains('permiss') ||
          msg.toLowerCase().contains('negada')) {
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

  Future<void> _navigateToTerms() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => TermsConditionsScreen()),
    );

    // Se os termos foram aceitos, salva a seleção
    if (result == true) {
      setState(() {
        _termsAccepted = true;
      });
      await _saveSelection();
    }
  }

  Future<void> _saveSelection() async {
    try {
      final selected =
          _deviceContacts
              .where((c) => _selectedContactIds.contains(c.id))
              .toList();

      // Atribui prioridades (1 = mais importante)
      final contactsWithPriority =
          selected.asMap().entries.map((entry) {
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
      _showSnackBar(
        '${contactsWithPriority.length} contatos de emergência salvos!',
      );
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildPermissionDenied() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_person,
              size: 56,
              color: colorScheme.onSurface.withValues(alpha: .6),
            ),
            const SizedBox(height: 12),
            Text(
              'Permissão de contatos negada.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ative a permissão em Configurações para permitir que o app leia seus contatos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
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

  Widget _buildTermsPrompt() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security, size: 64, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Termos e Condições',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Para salvar contatos de emergência, você precisa aceitar nossos termos de uso e autorizar o tratamento dos dados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _navigateToTerms,
                child: const Text('Ver Termos e Condições'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contatos de Emergência'),
            Text(
              '${_selectedContactIds.length}/5 selecionados',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed:
                _selectedContactIds.isNotEmpty && _termsAccepted
                    ? _saveSelection
                    : _selectedContactIds.isNotEmpty
                    ? _navigateToTerms
                    : null,
            tooltip:
                _termsAccepted
                    ? 'Salvar contatos'
                    : 'Aceitar termos para salvar',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _permissionDenied
              ? _buildPermissionDenied()
              : Column(
                children: [
                  if (_emergencyContacts.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.emergency, color: colorScheme.error),
                              const SizedBox(width: 8),
                              Text(
                                'Seus Contatos de Emergência:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
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

                  // Se tem contatos selecionados mas não aceitou os termos, mostra prompt
                  if (_selectedContactIds.isNotEmpty && !_termsAccepted) ...[
                    Expanded(child: _buildTermsPrompt()),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.contacts, color: colorScheme.onSurface),
                          const SizedBox(width: 8),
                          Text(
                            'Escolha contatos do seu celular:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child:
                          _deviceContacts.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.contacts,
                                      size: 64,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Nenhum contato encontrado',
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
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
                                  final isSelected = _selectedContactIds
                                      .contains(contact.id);

                                  return ContactItem(
                                    contact: contact,
                                    isSelected: isSelected,
                                    onChanged:
                                        (selected) => _toggleContact(
                                          contact.id,
                                          selected,
                                        ),
                                    // opcional: desabilitar seleção quando estiver cheio
                                    isDisabled:
                                        !isSelected &&
                                        _selectedContactIds.length >= 5,
                                  );
                                },
                              ),
                    ),
                  ],
                ],
              ),
    );
  }
}
