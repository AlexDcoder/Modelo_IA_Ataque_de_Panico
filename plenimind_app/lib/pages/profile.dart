import 'package:flutter/material.dart';
import '../pages/contact.dart';
import 'package:plenimind_app/components/profile/profie_form.dart';
import 'package:plenimind_app/pages/login.dart';
import 'package:plenimind_app/schemas/profile/profile_model.dart';
import '../components/profile/profile_app_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static String routeName = 'CreateProfile';
  static String routePath = '/createProfile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late CreateProfileModel _model;

  @override
  void initState() {
    super.initState();
    _model = CreateProfileModel();
    _model.yourNameTextController ??= TextEditingController();
    _model.yourNameFocusNode ??= FocusNode();
    _model.cityTextController ??= TextEditingController();
    _model.cityFocusNode ??= FocusNode();
    _model.selectedDuration = Duration.zero;
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_model.yourNameTextController?.text.isEmpty ?? true) {
      _showSnackBar('Please enter your name');
      return;
    }

    if (_model.cityTextController?.text.isEmpty ?? true) {
      _showSnackBar('Please set detection time');
      return;
    }

    Navigator.pushNamed(context, ContactPage.routePath);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
          child: ProfileForm(model: _model, onNext: _handleNext),
        ),
      ),
    );
  }
}
