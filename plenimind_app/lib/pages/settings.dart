import 'package:flutter/material.dart';
import 'package:plenimind_app/components/status/notifications/emergency_contact_manager.dart';
import 'package:plenimind_app/core/auth/auth_manager.dart';
import 'package:plenimind_app/pages/login.dart';
import 'package:plenimind_app/service/account_service.dart';
import 'package:plenimind_app/service/user_service.dart';
import 'package:plenimind_app/components/utils/loading_overlay.dart';
import 'package:plenimind_app/schemas/request/personal_data.dart';
import 'package:plenimind_app/schemas/response/user_personal_request.dart';
import 'package:plenimind_app/schemas/dto/emergency_contact_dto.dart';
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';

class SettingsPage extends StatefulWidget {
  static const String routePath = '/settings';
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthManager _authManager = AuthManager();
  final AccountService _accountService = AccountService();
  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _isSaving = false;
  String _userEmail = '';
  UserPersonalDataResponse? _userData;

  // Controladores para edição
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _detectionTimeController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      await _authManager.reloadTokens();
      final token = _authManager.token;

      if (token != null) {
        final userResponse = await _userService.getCurrentUser();
        if (userResponse != null) {
          setState(() {
            _userData = userResponse;
            _userEmail = userResponse.email;
            _usernameController.text = userResponse.username;
            _detectionTimeController.text = userResponse.detectionTime;
            _emailController.text = userResponse.email;
          });
          debugPrint('✅ Dados do usuário carregados: ${userResponse.username}');
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar dados do usuário: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ NOVO MÉTODO: Converter EmergencyContactDTO para EmergencyContact
  List<EmergencyContact> _convertDTOsToEmergencyContacts(
    List<EmergencyContactDTO> dtos,
  ) {
    final userId = _authManager.userId ?? '';
    return dtos.asMap().entries.map((entry) {
      final index = entry.key;
      final dto = entry.value;
      return EmergencyContact(
        id: '${userId}_contact_$index',
        name: dto.name,
        phone: dto.phone,
        imageUrl: '', // Definir imagem padrão ou deixar vazio
        priority: index + 1, // Prioridade baseada na ordem (1-based)
      );
    }).toList();
  }

  // ✅ NOVO MÉTODO: Converter EmergencyContact para EmergencyContactDTO
  List<EmergencyContactDTO> _convertEmergencyContactsToDTOs(
    List<EmergencyContact> contacts,
  ) {
    return contacts
        .map(
          (contact) =>
              EmergencyContactDTO(name: contact.name, phone: contact.phone),
        )
        .toList();
  }

  Future<void> _saveUserData() async {
    if (_userData == null) return;

    setState(() => _isSaving = true);

    try {
      // Converter contatos de emergência de volta para DTO
      final emergencyContactsDTO =
          _userData!.emergencyContacts
              .map(
                (contact) => EmergencyContactDTO(
                  name: contact.name,
                  phone: contact.phone,
                ),
              )
              .toList();

      final updatedUser = UserPersonalData(
        username: _usernameController.text,
        email: _emailController.text,
        password: '', // Não alterar senha na edição
        detectionTime: _detectionTimeController.text,
        emergencyContacts: emergencyContactsDTO,
      );

      final token = _authManager.token;
      final userId = _authManager.userId;

      if (token == null || userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final result = await _userService.updateUser(userId, updatedUser);

      if (result != null) {
        // Atualizar dados locais
        setState(() {
          _userData = result;
          _userEmail = result.email;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dados atualizados com sucesso!'),
            duration: Duration(seconds: 2),
          ),
        );

        debugPrint('✅ Dados do usuário atualizados: ${result.username}');
      } else {
        throw Exception('Falha ao atualizar dados');
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar dados: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao salvar: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Deletar Conta'),
          content: const Text(
            'Esta ação é IRREVERSÍVEL. Todos os seus dados serão deletados permanentemente.\n\n'
            'Suas permissões (contatos, notificações) serão mantidas para facilitar '
            'o recadastramento, mas seus dados pessoais serão perdidos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Deletar Permanentemente'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      try {
        setState(() => _isLoading = true);

        await _authManager.reloadTokens();
        final token = _authManager.token;
        final userId = _authManager.userId;

        if (token == null || userId == null) {
          throw Exception('Dados de autenticação não encontrados');
        }

        final success = await _accountService.deleteAccount(userId, token);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '✅ Conta deletada com sucesso. Suas permissões foram mantidas para recadastramento.',
                ),
                duration: Duration(seconds: 3),
              ),
            );

            await Future.delayed(const Duration(seconds: 1));
            Navigator.pushReplacementNamed(context, LoginPage.routePath);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Erro ao deletar conta. Tente novamente.'),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Erro ao deletar conta: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao deletar conta: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showEmergencyContactsManager() {
    // ✅ CORREÇÃO: Converter EmergencyContactDTO para EmergencyContact
    final initialContacts =
        _userData != null
            ? _convertDTOsToEmergencyContacts(_userData!.emergencyContacts)
            : <EmergencyContact>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppBar(
                  title: const Text('Gerenciar Contatos de Emergência'),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: EmergencyContactManager(
                    initialContacts:
                        initialContacts, // ✅ Agora é List<EmergencyContact>
                    onContactsUpdated: (
                      List<EmergencyContact> updatedContacts,
                    ) async {
                      // ✅ CORREÇÃO: Converter EmergencyContact para EmergencyContactDTO
                      final emergencyContactsDTO =
                          _convertEmergencyContactsToDTOs(updatedContacts);

                      final token = _authManager.token;
                      final userId = _authManager.userId;

                      if (token != null && userId != null) {
                        final result = await _userService
                            .updateUserEmergencyContacts(
                              userId,
                              emergencyContactsDTO,
                            );

                        if (result != null) {
                          // Recarregar dados do usuário
                          await _loadUserData();
                          Navigator.pop(context); // Fechar o modal após sucesso
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('❌ Erro ao atualizar contatos'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    screenWidth: MediaQuery.of(context).size.width,
                    userId: _authManager.userId ?? '',
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildUserInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações Pessoais',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Nome de Usuário',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detectionTimeController,
              decoration: const InputDecoration(
                labelText: 'Tempo de Detecção (HH:MM:SS)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
                hintText: 'Ex: 00:30:00',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveUserData,
                child:
                    _isSaving
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Salvar Alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações da Conta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('ID do Usuário'),
              subtitle: Text(_authManager.userId ?? 'Não disponível'),
            ),
            ListTile(
              leading: const Icon(Icons.emergency),
              title: const Text('Contatos de Emergência'),
              subtitle: Text(
                '${_userData?.emergencyContacts.length ?? 0} contatos configurados',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showEmergencyContactsManager,
            ),
            if (_userData?.detectionTime != null)
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Intervalo de Monitoramento'),
                subtitle: Text(_userData!.detectionTime),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneSection() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zona de Perigo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essas ações não podem ser desfeitas. Proceda com cuidado.',
              style: TextStyle(color: Colors.red[600]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: _handleDeleteAccount,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[700],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_forever),
                    SizedBox(width: 8),
                    Text('Deletar Conta Permanentemente'),
                  ],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadUserData,
            tooltip: 'Recarregar dados',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Carregando suas informações...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildUserInfoSection(),
              const SizedBox(height: 16),
              _buildAccountInfoSection(),
              const SizedBox(height: 16),
              _buildDangerZoneSection(),
            ],
          ),
        ),
      ),
    );
  }
}
