import 'package:flutter/material.dart';
import 'package:plenimind_app/schemas/response/user_personal_request.dart';
import 'package:plenimind_app/schemas/request/personal_data.dart';

class SettingsProfileForm extends StatefulWidget {
  final UserPersonalDataResponse userData;
  final Function(UserPersonalData) onProfileUpdated;
  final double screenWidth;

  const SettingsProfileForm({
    super.key,
    required this.userData,
    required this.onProfileUpdated,
    required this.screenWidth,
  });

  @override
  State<SettingsProfileForm> createState() => _SettingsProfileFormState();
}

class _SettingsProfileFormState extends State<SettingsProfileForm> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.userData.username);
    _emailController = TextEditingController(text: widget.userData.email);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final updatedData = UserPersonalData(
      username: _usernameController.text,
      email: _emailController.text,
      password: '', // Não alterar senha
      detectionTime: widget.userData.detectionTime,
      emergencyContacts: widget.userData.emergencyContacts,
    );

    widget.onProfileUpdated(updatedData);
    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _usernameController.text = widget.userData.username;
      _emailController.text = widget.userData.email;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _usernameController,
          enabled: _isEditing,
          decoration: InputDecoration(
            labelText: 'Nome de Usuário',
            border: const OutlineInputBorder(),
            suffixIcon: Icon(Icons.person, size: widget.screenWidth * 0.05),
          ),
        ),
        SizedBox(height: widget.screenWidth * 0.04),
        TextField(
          controller: _emailController,
          enabled: _isEditing,
          decoration: InputDecoration(
            labelText: 'Email',
            border: const OutlineInputBorder(),
            suffixIcon: Icon(Icons.email, size: widget.screenWidth * 0.05),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: widget.screenWidth * 0.04),

        if (!_isEditing)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text('Editar Perfil'),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelEditing,
                  child: const Text('Cancelar'),
                ),
              ),
              SizedBox(width: widget.screenWidth * 0.03),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
