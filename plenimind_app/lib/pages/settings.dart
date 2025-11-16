import 'package:flutter/material.dart';
import 'package:plenimind_app/components/settings/settings_profile_form.dart';
import 'package:plenimind_app/components/settings/settings_contact_management.dart';
import 'package:plenimind_app/components/settings/settings_detection_time.dart';
import 'package:plenimind_app/core/auth/auth_manager.dart';
import 'package:plenimind_app/service/user_service.dart';
import 'package:plenimind_app/schemas/response/user_personal_request.dart';
import 'package:plenimind_app/schemas/request/personal_data.dart';
import 'package:plenimind_app/service/contact_service.dart';
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';

class SettingsPage extends StatefulWidget {
  static const String routePath = '/settings';

  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final UserService _userService = UserService();
  final AuthManager _authManager = AuthManager();

  UserPersonalDataResponse? _userData;
  List<EmergencyContact> _emergencyContacts = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await _authManager.reloadTokens();
      final userId = _authManager.userId;

      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final userResponse = await _userService.getCurrentUser();
      if (userResponse != null) {
        setState(() {
          _userData = userResponse;
        });

        final contacts = await ContactService.getEmergencyContacts(userId);
        setState(() {
          _emergencyContacts = contacts;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar dados: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile(UserPersonalData updatedData) async {
    try {
      if (_userData == null) return;

      final token = _authManager.token;
      if (token == null) {
        throw Exception('Token de autenticação não encontrado');
      }

      final result = await _userService.updateUser(_userData!.uid, updatedData);

      if (result != null) {
        setState(() {
          _userData = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar perfil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateContacts(List<EmergencyContact> newContacts) async {
    try {
      final userId = _authManager.userId;
      if (userId == null) return;

      await ContactService.saveEmergencyContacts(newContacts, userId);

      setState(() {
        _emergencyContacts = newContacts;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contatos atualizados com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar contatos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Recarregar dados',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: screenWidth * 0.15,
                        color: Colors.red,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              )
              : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Seção de Perfil
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        size: screenWidth * 0.06,
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Text(
                                        'Perfil do Usuário',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.05,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  SettingsProfileForm(
                                    userData: _userData!,
                                    onProfileUpdated: _updateProfile,
                                    screenWidth: screenWidth,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.03),

                          // Seção de Tempo de Detecção
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        size: screenWidth * 0.06,
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Text(
                                        'Tempo de Detecção',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.05,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  SettingsDetectionTime(
                                    initialDetectionTime:
                                        _userData!.detectionTime,
                                    onDetectionTimeUpdated: (newTime) {
                                      final updatedData = UserPersonalData(
                                        username: _userData!.username,
                                        email: _userData!.email,
                                        password: '', // Não alterar senha
                                        detectionTime: newTime,
                                        emergencyContacts:
                                            _userData!.emergencyContacts,
                                      );
                                      _updateProfile(updatedData);
                                    },
                                    screenWidth: screenWidth,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.03),

                          // Seção de Contatos de Emergência
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.emergency,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        size: screenWidth * 0.06,
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Text(
                                        'Contatos de Emergência',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.05,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  SettingsContactManagement(
                                    currentContacts: _emergencyContacts,
                                    onContactsUpdated: _updateContacts,
                                    screenWidth: screenWidth,
                                    screenHeight: screenHeight,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.03),

                          // Informações do Sistema
                          Card(
                            elevation: 2,
                            color: Colors.grey[50],
                            child: Padding(
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Informações do Sistema',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Text(
                                    'UID: ${_userData!.uid}',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.005),
                                  Text(
                                    'Contatos configurados: ${_emergencyContacts.length}',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
