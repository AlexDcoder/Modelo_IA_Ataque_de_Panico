import 'package:flutter/material.dart';
import '../pages/contact.dart';
import 'package:plenimind_app/components/profile/profie_form.dart';
import 'package:plenimind_app/pages/login.dart';
import 'package:plenimind_app/schemas/profile/profile_model.dart';
import '../components/profile/profile_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:plenimind_app/core/auth/register_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  static String routePath = '/createProfile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late CreateProfileModel _model;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _model = CreateProfileModel();
    _model.yourNameTextController ??= TextEditingController();
    _model.yourNameFocusNode ??= FocusNode();
    _model.cityTextController ??= TextEditingController();
    _model.cityFocusNode ??= FocusNode();
    _model.selectedDuration = Duration.zero;

    // Listener para validação em tempo real do nome
    _model.yourNameTextController!.addListener(_validateName);
  }

  void _validateName() {
    final name = _model.yourNameTextController?.text ?? '';
    if (name.isNotEmpty && name.length < 3) {
      setState(() {
        _nameError = 'O nome deve ter pelo menos 3 caracteres';
      });
    } else {
      setState(() {
        _nameError = null;
      });
    }
  }

  @override
  void dispose() {
    _model.yourNameTextController?.removeListener(_validateName);
    _model.dispose();
    super.dispose();
  }

  void _handleNext() {
    final name = _model.yourNameTextController?.text ?? '';

    if (name.isEmpty) {
      _showSnackBar('Por favor, insira seu nome');
      return;
    }

    // Validação do nome - mínimo 3 caracteres
    if (name.length < 3) {
      _showSnackBar('O nome deve ter pelo menos 3 caracteres');
      return;
    }

    if (_model.cityTextController?.text.isEmpty ?? true) {
      _showSnackBar('Por favor, defina o tempo de detecção');
      return;
    }

    final registerProvider = Provider.of<RegisterProvider>(
      context,
      listen: false,
    );
    registerProvider.setProfileInfo(name, _model.cityTextController!.text);

    Navigator.pushNamed(context, ContactPage.routePath);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: ProfileAppBar(routeToNavigate: LoginPage.routePath),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ProfileForm(
            model: _model,
            onNext: _handleNext,
            nameError: _nameError,
          ),
        ),
      ),
    );
  }
}
