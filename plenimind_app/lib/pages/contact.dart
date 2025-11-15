import 'package:flutter/material.dart';
import 'package:plenimind_app/pages/terms_conditions.dart';
import 'package:plenimind_app/pages/login.dart';
import 'package:plenimind_app/service/contact_service.dart';
import 'package:plenimind_app/components/contact/contact_item.dart';
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:plenimind_app/pages/status_page.dart';
import 'package:plenimind_app/service/user_service.dart';
import 'package:plenimind_app/schemas/request/personal_data.dart';
import 'package:plenimind_app/core/auth/auth_service.dart';
import 'package:plenimind_app/core/auth/permission_manager.dart';

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

  late String _email;
  late String _password;
  late String _username;
  late String _detectionTime;

  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _restorePermissionsIfAccepted();
    _loadData();
    _checkTermsStatus();
  }

  Future<void> _restorePermissionsIfAccepted() async {
    // ✅ CORREÇÃO: Se o usuário já tinha aceito as permissões, restaurá-las automaticamente
    final permissionsStatus = await PermissionManager.getAllPermissionsStatus();

    if (permissionsStatus['contacts_permission'] == true) {
      debugPrint('✅ Restaurando permissão de contatos aceita anteriormente');
      // A permissão será pedida normalmente quando necessário em getDeviceContacts()
    }

    if (permissionsStatus['notification_permission'] == true) {
      debugPrint('✅ Notificações já foram permitidas anteriormente');
    }

    if (permissionsStatus['phone_permission'] == true) {
      debugPrint('✅ Chamadas telefônicas já foram permitidas anteriormente');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _email = args['email'] ?? '';
      _password = args['password'] ?? '';
      _username = args['username'] ?? '';
      _detectionTime = args['detectionTime'] ?? '00:30:00';
    }
  }

  Future<void> _checkTermsStatus() async {
    // ✅ CORREÇÃO: Verificar se os termos foram aceitos (persistente mesmo após deletar conta)
    final termsAccepted = await PermissionManager.getTermsAccepted();
    setState(() {
      _termsAccepted = termsAccepted;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carrega contatos salvos como emergência
      final emergencyContacts = await ContactService.getEmergencyContacts(
        _email,
      );

      // Carrega contatos do celular
      final deviceContacts = await ContactService.getDeviceContacts();

      final emergencyPhones = emergencyContacts.map((c) => c.phone).toSet();

      setState(() {
        _emergencyContacts = emergencyContacts;
        _deviceContacts = deviceContacts;
        _selectedContactIds.clear();

        for (final deviceContact in _deviceContacts) {
          if (emergencyPhones.contains(deviceContact.phone)) {
            _selectedContactIds.add(deviceContact.id);
          }
        }

        _permissionDenied = false;
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
        _showSnackBar('Erro: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToTerms() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const TermsConditionsScreen()),
    );

    if (result == true) {
      setState(() {
        _termsAccepted = true;
      });
      await _saveSelection();
    } else {
      // 📌 Quando volta da tela de Termos sem aceitar, limpar seleção de contatos
      debugPrint(
        '⚠️ Usuário voltou da tela de Termos sem aceitar. Limpando seleção.',
      );
      setState(() {
        _selectedContactIds.clear();
      });
    }
  }

  Future<void> _saveSelection() async {
    if (!_termsAccepted) {
      _showSnackBar('Aceite os termos e condições primeiro');
      await _navigateToTerms();
      return;
    }

    try {
      final selected =
          _deviceContacts
              .where((c) => _selectedContactIds.contains(c.id))
              .toList();

      if (selected.isEmpty) {
        _showSnackBar('Selecione pelo menos um contato');
        return;
      }

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

      // Converter para DTO para envio à API
      final emergencyContactsDTO =
          contactsWithPriority.map((contact) => contact.toDTO()).toList();

      // Criar usuário com todos os dados
      final userData = UserPersonalData(
        username: _username,
        email: _email,
        password: _password,
        detectionTime: _detectionTime,
        emergencyContacts: emergencyContactsDTO,
      );

      // Registrar usuário no backend
      final userResponse = await _userService.createUser(userData);

      if (userResponse != null) {
        // Salvar contatos localmente também
        await ContactService.saveEmergencyContacts(
          contactsWithPriority,
          _email,
        );

        // 📌 OPÇÃO A: Verificar se tokens foram retornados na resposta de criação
        // (Por enquanto, o backend não retorna tokens, então fazemos login automático)

        // 📌 OPÇÃO B: Fazer login automático com tratamento de erro
        try {
          debugPrint('🔐 Tentando autenticação automática após cadastro...');
          final loginResult = await _authService.login(_email, _password);

          if (loginResult != null) {
            debugPrint('✅ Usuário autenticado automaticamente após cadastro');
            _showSnackBar('Conta criada com sucesso!');

            if (mounted) {
              Navigator.pushReplacementNamed(context, StatusPage.routePath);
            }
          } else {
            // ⚠️ OPÇÃO B: Feedback UX - Login automático falhou
            debugPrint('❌ Autenticação automática falhou após cadastro');
            _showSnackBar(
              'Conta criada, mas login automático falhou. Faça login manualmente.',
            );

            if (mounted) {
              // Redirecionar para tela de login com mensagem
              Navigator.pushReplacementNamed(
                context,
                LoginPage.routePath,
                arguments: {'email': _email, 'autoLoginFailed': true},
              );
            }
          }
        } catch (e) {
          // ⚠️ OPÇÃO B: Erro durante login automático
          debugPrint('❌ Erro na autenticação automática: $e');
          _showSnackBar(
            'Conta criada, mas houve erro ao autenticar. Tente fazer login.',
          );

          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              LoginPage.routePath,
              arguments: {'email': _email, 'autoLoginFailed': true},
            );
          }
        }
      } else {
        _showSnackBar('Erro ao criar conta. Tente novamente.');
      }
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
              color: colorScheme.onSurface.withValues(alpha: 0.6),
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
            onPressed: _selectedContactIds.isNotEmpty ? _saveSelection : null,
            tooltip: 'Salvar contatos',
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
                          }),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                  ],

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
