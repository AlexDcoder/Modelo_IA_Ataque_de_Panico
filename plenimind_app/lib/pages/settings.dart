import 'package:flutter/material.dart';
import 'package:plenimind_app/components/settings/device_contacts_selector.dart';
import 'package:plenimind_app/components/profile/profile_time_field.dart';
import 'package:plenimind_app/core/auth/auth_manager.dart';
import 'package:plenimind_app/pages/login.dart';
import 'package:plenimind_app/service/account_service.dart';
import 'package:plenimind_app/service/contact_service.dart';
import 'package:plenimind_app/service/user_service.dart';
import 'package:plenimind_app/components/utils/loading_overlay.dart';
import 'package:plenimind_app/schemas/response/user_personal_request.dart';
import 'package:plenimind_app/schemas/dto/emergency_contact_dto.dart';
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';
import 'package:plenimind_app/utils/email_validator.dart';

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
  bool _isSavingProfile = false;
  bool _isSavingDetectionTime = false;
  UserPersonalDataResponse? _userData;
  bool _isEmailValid = true;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _detectionTimeController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // CONTROLADORES PARA ALTERAÇÃO DE SENHA
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    setState(() {
      _isEmailValid = EmailValidator.isValid(_emailController.text);
    });
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 [SETTINGS] Carregando dados do usuário...');
      await _authManager.reloadTokens();
      final token = _authManager.token;

      if (token != null) {
        final userResponse = await _userService.getCurrentUser();
        if (userResponse != null) {
          setState(() {
            _userData = userResponse;
            _usernameController.text = userResponse.username;
            _detectionTimeController.text = userResponse.detectionTime;
            _emailController.text = userResponse.email;
          });
          debugPrint('✅ [SETTINGS] Dados carregados com sucesso');
        } else {
          debugPrint('❌ [SETTINGS] Falha ao carregar dados do usuário');
        }
      } else {
        debugPrint('❌ [SETTINGS] Token não disponível para carregar dados');
      }
    } catch (e) {
      debugPrint('❌ [SETTINGS] Erro ao carregar dados do usuário: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ SALVAR APENAS PERFIL (username e email)
  Future<void> _saveProfile() async {
    if (_userData == null) return;

    // Validar email antes de salvar
    if (!EmailValidator.isValid(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            EmailValidator.getErrorMessage(_emailController.text) ??
                'Email inválido',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      debugPrint('🔄 [SETTINGS] Salvando perfil...');
      final userId = _authManager.userId;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final result = await _userService.updateUserProfile(
        uid: userId,
        username: _usernameController.text,
        email: _emailController.text,
      );

      if (result != null) {
        setState(() {
          _userData = result;
        });
        debugPrint('✅ [SETTINGS] Perfil salvo com sucesso');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perfil atualizado com sucesso!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Falha ao atualizar perfil');
      }
    } catch (e) {
      debugPrint('❌ [SETTINGS] Erro ao salvar perfil: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao salvar perfil: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isSavingProfile = false);
    }
  }

  // ✅ SALVAR APENAS TEMPO DE DETECÇÃO
  Future<void> _saveDetectionTime() async {
    if (_userData == null) return;

    setState(() => _isSavingDetectionTime = true);

    try {
      debugPrint('🔄 [SETTINGS] Salvando tempo de detecção...');
      final userId = _authManager.userId;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final result = await _userService.updateUserDetectionTime(
        uid: userId,
        detectionTime: _detectionTimeController.text,
      );

      if (result != null) {
        setState(() {
          _userData = result;
        });

        debugPrint('✅ [SETTINGS] Tempo de detecção salvo com sucesso');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tempo de detecção atualizado!'),
            duration: Duration(seconds: 2),
          ),
        );

        // ✅ O DETECTION TIME MANAGER JÁ FOI NOTIFICADO PELO USER SERVICE
      } else {
        throw Exception('Falha ao atualizar tempo de detecção');
      }
    } catch (e) {
      debugPrint('❌ [SETTINGS] Erro ao salvar tempo de detecção: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao salvar tempo: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isSavingDetectionTime = false);
    }
  }

  // ✅ NOVO: ALTERAR SENHA DO USUÁRIO
  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ As senhas não coincidem')),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ A senha deve ter pelo menos 6 caracteres'),
        ),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      debugPrint('🔄 [SETTINGS] Alterando senha...');
      final userId = _authManager.userId;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final result = await _userService.updateUserPassword(
        uid: userId,
        newPassword: _newPasswordController.text,
        currentPassword: _currentPasswordController.text,
      );

      if (result != null) {
        debugPrint('✅ [SETTINGS] Senha alterada com sucesso');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Senha alterada com sucesso!'),
            duration: Duration(seconds: 2),
          ),
        );

        // LIMPAR CAMPOS
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        throw Exception('Falha ao alterar senha');
      }
    } catch (e) {
      debugPrint('❌ [SETTINGS] Erro ao alterar senha: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao alterar senha: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isChangingPassword = false);
    }
  }

  // ✅ SALVAR CONTATOS DE EMERGÊNCIA
  Future<void> _saveEmergencyContacts(List<EmergencyContact> contacts) async {
    try {
      debugPrint(
        '🔄 [SETTINGS] Salvando ${contacts.length} contatos de emergência...',
      );

      final userId = _authManager.userId;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      // Salvar localmente
      await ContactService.saveEmergencyContacts(contacts, userId);

      // Converter para DTO e salvar no servidor
      final emergencyContactsDTO = _convertEmergencyContactsToDTOs(contacts);

      final result = await _userService.updateUserEmergencyContacts(
        uid: userId,
        emergencyContacts: emergencyContactsDTO,
      );

      if (result != null) {
        setState(() {
          _userData = result;
        });
        debugPrint('✅ [SETTINGS] Contatos salvos com sucesso');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contatos de emergência atualizados!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Falha ao atualizar contatos no servidor');
      }
    } catch (e) {
      debugPrint('❌ [SETTINGS] Erro ao salvar contatos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao salvar contatos: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

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
        imageUrl: '',
        priority: index + 1,
      );
    }).toList();
  }

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

  // ✅ MÉTODO PARA VERIFICAR STATUS DOS CONTATOS
  Widget _buildContactsStatus() {
    final contactCount = _userData?.emergencyContacts.length ?? 0;

    return ListTile(
      leading: Icon(
        contactCount > 0 ? Icons.check_circle : Icons.warning,
        color: contactCount > 0 ? Colors.green : Colors.orange,
      ),
      title: const Text('Contatos de Emergência'),
      subtitle: Text(
        contactCount > 0
            ? '$contactCount contatos configurados'
            : 'Nenhum contato configurado',
      ),
      trailing: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(Icons.arrow_forward_ios, size: 16)],
      ),
      onTap: _showEmergencyContactsManager,
    );
  }

  Future<void> _handleDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Deletar Conta'),
          content: const Text(
            'Esta ação é IRREVERSÍVEL. Todos os seus dados serão deletados permanentemente.',
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
                content: Text('✅ Conta deletada com sucesso.'),
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
        debugPrint('❌ [SETTINGS] Erro ao deletar conta: $e');
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
    final userId = _authManager.userId;
    if (userId == null) {
      debugPrint(
        '❌ [SETTINGS] Usuário não autenticado para gerenciar contatos',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Usuário não autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final initialContacts =
        _userData != null
            ? _convertDTOsToEmergencyContacts(_userData!.emergencyContacts)
            : <EmergencyContact>[];

    debugPrint(
      '🔄 [SETTINGS] Abrindo gerenciador de contatos com ${initialContacts.length} contatos',
    );

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
                  title: const Text('Adicionar Contatos de Emergência'),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        debugPrint(
                          '✅ [SETTINGS] Gerenciador de contatos fechado',
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: DeviceContactsSelector(
                    userId: userId,
                    initialContacts: initialContacts,
                    onContactsSelected: (List<EmergencyContact> contacts) {
                      debugPrint(
                        '✅ [SETTINGS] ${contacts.length} contatos selecionados',
                      );
                      _saveEmergencyContacts(contacts);
                    },
                    screenWidth: MediaQuery.of(context).size.width,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildUserInfoSection() {
    final emailError =
        _emailController.text.isNotEmpty && !_isEmailValid
            ? EmailValidator.getErrorMessage(_emailController.text)
            : null;

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
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color:
                        emailError != null
                            ? Colors.red
                            : _isEmailValid && _emailController.text.isNotEmpty
                            ? Colors.green
                            : Colors.grey,
                  ),
                ),
                prefixIcon: const Icon(Icons.email),
                errorText: emailError,
                suffixIcon:
                    _emailController.text.isNotEmpty
                        ? Icon(
                          _isEmailValid ? Icons.check_circle : Icons.error,
                          color: _isEmailValid ? Colors.green : Colors.red,
                        )
                        : null,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isSavingProfile || !_isEmailValid ? null : _saveProfile,
                child:
                    _isSavingProfile
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Salvar Perfil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionTimeSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final detectionTimeDuration = _parseDurationFromString(
      _detectionTimeController.text,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tempo de Detecção',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Intervalo entre verificações de sinais vitais (HH:MM:SS)',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            // ✅ REUTILIZAR ProfileTimeField (mesmo componente do Profile)
            ProfileTimeField(
              controller: _detectionTimeController,
              focusNode: FocusNode(),
              initialDuration: detectionTimeDuration,
              onDurationChanged: (Duration newDuration) {
                _detectionTimeController.text =
                    "${newDuration.inHours.toString().padLeft(2, '0')}:"
                    "${(newDuration.inMinutes % 60).toString().padLeft(2, '0')}:"
                    "${(newDuration.inSeconds % 60).toString().padLeft(2, '0')}";
              },
              screenWidth: screenWidth,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSavingDetectionTime ? null : _saveDetectionTime,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[50],
                  foregroundColor: Colors.blue[700],
                ),
                child:
                    _isSavingDetectionTime
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Salvar Intervalo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Duration _parseDurationFromString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 3) {
        return Duration(
          hours: int.parse(parts[0]),
          minutes: int.parse(parts[1]),
          seconds: int.parse(parts[2]),
        );
      }
      return const Duration(hours: 0, minutes: 30, seconds: 0);
    } catch (e) {
      return const Duration(hours: 0, minutes: 30, seconds: 0);
    }
  }

  // ✅ NOVA SEÇÃO: ALTERAÇÃO DE SENHA
  Widget _buildChangePasswordSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alterar Senha',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // CAMPO SENHA ATUAL
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha Atual',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 12),

            // CAMPO NOVA SENHA
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nova Senha',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),

            // CAMPO CONFIRMAR SENHA
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar Nova Senha',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_reset),
              ),
            ),
            const SizedBox(height: 16),

            // BOTÃO PARA ALTERAR SENHA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChangingPassword ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[50],
                  foregroundColor: Colors.orange[700],
                ),
                child:
                    _isChangingPassword
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Alterar Senha'),
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
            _buildContactsStatus(),
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
              _buildDetectionTimeSection(),
              const SizedBox(height: 16),
              _buildChangePasswordSection(), // NOVA SEÇÃO ADICIONADA
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
