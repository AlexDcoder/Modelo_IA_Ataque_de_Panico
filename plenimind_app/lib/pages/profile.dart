import 'package:flutter/material.dart';
import 'package:plenimind_app/components/profile/profie_form.dart';
import 'package:plenimind_app/components/profile/profile_app_bar.dart';
import 'package:plenimind_app/schemas/profile/profile_model.dart';
import 'package:plenimind_app/pages/contact.dart';
import 'package:plenimind_app/pages/login.dart';
import 'package:provider/provider.dart';
import 'package:plenimind_app/core/auth/register_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static String routePath = '/profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final CreateProfileModel _model = CreateProfileModel();
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _model.yourNameTextController = TextEditingController();
    _model.yourNameFocusNode = FocusNode();
    _model.cityTextController = TextEditingController();
    _model.cityFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _handleNext() {
    final name = _model.yourNameTextController!.text.trim();

    if (name.isEmpty) {
      setState(() => _nameError = 'Por favor, informe seu nome');
      return;
    }

    final detectionTime = _model.selectedDuration;
    final timeString =
        "${detectionTime.inHours.toString().padLeft(2, '0')}:"
        "${(detectionTime.inMinutes % 60).toString().padLeft(2, '0')}:"
        "${(detectionTime.inSeconds % 60).toString().padLeft(2, '0')}";

    // Salvar no RegisterProvider
    final registerProvider = Provider.of<RegisterProvider>(
      context,
      listen: false,
    );
    registerProvider.setProfileInfo(name, timeString);

    Navigator.pushReplacementNamed(context, ContactPage.routePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProfileAppBar(
        onBackPressed: () {
          Navigator.pushReplacementNamed(context, LoginPage.routePath);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: ProfileForm(
                  model: _model,
                  onNext: _handleNext,
                  nameError: _nameError,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
