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
    final permissionsStatus = await PermissionManager.getAllPermissionsStatus();

    if (permissionsStatus['contacts_permission'] == true) {
      debugPrint('✅ Restaurando permissão de contatos aceita anteriormente');
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
      final emergencyContacts = await ContactService.getEmergencyContacts(
        _email,
      );

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

      final emergencyContactsDTO =
          contactsWithPriority.map((contact) => contact.toDTO()).toList();

      final userData = UserPersonalData(
        username: _username,
        email: _email,
        password: _password,
        detectionTime: _detectionTime,
        emergencyContacts: emergencyContactsDTO,
      );

      final userResponse = await _userService.createUser(userData);

      if (userResponse != null) {
        await ContactService.saveEmergencyContacts(
          contactsWithPriority,
          _email,
        );

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
            debugPrint('❌ Autenticação automática falhou após cadastro');
            _showSnackBar(
              'Conta criada, mas login automático falhou. Faça login manualmente.',
            );

            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                LoginPage.routePath,
                arguments: {'email': _email, 'autoLoginFailed': true},
              );
            }
          }
        } catch (e) {
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

  Widget _buildPermissionDeniedUI(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_person,
              size: screenWidth * 0.14,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'Permissão de contatos negada.',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              'Ative a permissão em Configurações para permitir que o app leia seus contatos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: screenWidth * 0.035,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => openAppSettings(),
                  child: Text(
                    'Abrir configurações',
                    style: TextStyle(fontSize: screenWidth * 0.035),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                OutlinedButton(
                  onPressed: _loadData,
                  child: Text(
                    'Tentar novamente',
                    style: TextStyle(fontSize: screenWidth * 0.035),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsPromptUI(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.security,
              size: screenWidth * 0.16,
              color: colorScheme.primary,
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              'Termos e Condições',
              style: TextStyle(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'Para salvar contatos de emergência, você precisa aceitar nossos termos de uso e autorizar o tratamento dos dados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            SizedBox(
              width: double.infinity,
              height: screenHeight * 0.07,
              child: ElevatedButton(
                onPressed: _navigateToTerms,
                child: Text(
                  'Ver Termos e Condições',
                  style: TextStyle(fontSize: screenWidth * 0.04),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contatos de Emergência',
              style: TextStyle(fontSize: screenWidth * 0.045),
            ),
            Text(
              '${_selectedContactIds.length}/5 selecionados',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: screenWidth * 0.035,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save, size: screenWidth * 0.06),
            onPressed: _selectedContactIds.isNotEmpty ? _saveSelection : null,
            tooltip: 'Salvar contatos',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _permissionDenied
              ? _buildPermissionDeniedUI(context)
              : Column(
                children: [
                  if (_emergencyContacts.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.emergency,
                                color: colorScheme.error,
                                size: screenWidth * 0.06,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Seus Contatos de Emergência:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                  fontSize: screenWidth * 0.04,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          ..._emergencyContacts.map((contact) {
                            return ContactItem(
                              contact: contact,
                              isSelected: true,
                              onChanged: (value) {},
                              isDisabled: true,
                              showPriority: true,
                              screenWidth: screenWidth,
                            );
                          }),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                  ],

                  if (_selectedContactIds.isNotEmpty && !_termsAccepted) ...[
                    Expanded(child: _buildTermsPromptUI(context)),
                  ] else ...[
                    Padding(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Row(
                        children: [
                          Icon(
                            Icons.contacts,
                            color: colorScheme.onSurface,
                            size: screenWidth * 0.06,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Escolha contatos do seu celular:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              fontSize: screenWidth * 0.04,
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
                                      size: screenWidth * 0.15,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.02),
                                    Text(
                                      'Nenhum contato encontrado',
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: screenWidth * 0.04,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.02),
                                    TextButton(
                                      onPressed: _loadData,
                                      child: Text(
                                        'Tentar novamente',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.04,
                                        ),
                                      ),
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
                                    screenWidth: screenWidth,
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
