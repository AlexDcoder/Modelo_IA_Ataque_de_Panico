import 'package:flutter/material.dart';
import '../pages/contact.dart';
import 'package:plenimind_app/components/profile/profie_form.dart';
import 'package:plenimind_app/pages/login.dart';
import 'package:plenimind_app/schemas/profile/profile_model.dart';
import '../components/profile/profile_app_bar.dart';
import '../components/utils/loading_overlay.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  static String routePath = '/createProfile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late CreateProfileModel _model;
  late String _email;
  late String _password;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _model = CreateProfileModel();
    _model.yourNameTextController ??= TextEditingController();
    _model.yourNameFocusNode ??= FocusNode();
    _model.cityTextController ??= TextEditingController();
    _model.cityFocusNode ??= FocusNode();
    _model.selectedDuration = Duration.zero;

    // Inicializar o controller do tempo com valor padrão
    _model.cityTextController!.text = "00:00:00"; // Valor padrão de 30 minutos
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _email = args['email'] ?? '';
      _password = args['password'] ?? '';
      debugPrint('📧 Email recebido: $_email');
    } else {
      debugPrint('⚠️ Nenhum argumento recebido na ProfilePage');
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (_model.yourNameTextController?.text.isEmpty ?? true) {
      debugPrint('❌ [PROFILE_PAGE] Nome não informado');
      _showSnackBar('Por favor, informe seu nome');
      return;
    }

    if (_model.selectedDuration == Duration.zero) {
      debugPrint('❌ [PROFILE_PAGE] Tempo de detecção não selecionado');
      _showSnackBar('Por favor, selecione o tempo de detecção');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final detectionTime = _formatDuration(_model.selectedDuration);

      debugPrint('🚀 [PROFILE_PAGE] Navegando para ContactPage com dados:');
      debugPrint('   👤 Nome: ${_model.yourNameTextController!.text}');
      debugPrint('   📧 Email: $_email');
      debugPrint('   ⏰ Tempo de detecção: $detectionTime');
      debugPrint('   🔐 Senha: [PROTEGIDA]');

      // Simular um pequeno delay para mostrar o loading
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushNamed(
          context,
          ContactPage.routePath,
          arguments: {
            'email': _email,
            'password': _password,
            'username': _model.yourNameTextController!.text,
            'detectionTime': detectionTime,
          },
        );
        debugPrint('✅ [PROFILE_PAGE] Navegação para ContactPage iniciada');
      }
    } catch (e) {
      debugPrint('❌ [PROFILE_PAGE] Erro na navegação: $e');
      _showSnackBar('Erro: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatDuration(Duration duration) {
    try {
      final hours = duration.inHours.toString().padLeft(2, '0');
      final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      final formatted = '$hours:$minutes:$seconds';

      debugPrint('⏰ [PROFILE_PAGE] Duração formatada: $duration → $formatted');
      return formatted;
    } catch (e) {
      debugPrint('❌ [PROFILE_PAGE] Erro ao formatar duração: $e');
      return '00:00:00'; // Fallback
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: ProfileAppBar(
        routeToNavigate: LoginPage.routePath,
        onBackPressed: () {
          Navigator.pushReplacementNamed(context, LoginPage.routePath);
        },
        screenWidth: screenWidth,
      ),
      body: LoadingOverlay(
        isLoading: _isSaving,
        message: 'Salvando seu perfil...',
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: screenWidth * 0.05,
                  right: screenWidth * 0.05,
                  top: screenHeight * 0.02,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header informativo
                        Padding(
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Complete seu Perfil',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: screenWidth * 0.06,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                'Preencha suas informações para personalizar sua experiência',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: screenWidth * 0.04,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Formulário
                        Flexible(
                          child: ProfileForm(
                            model: _model,
                            onNext: _handleNext,
                            screenWidth: screenWidth,
                          ),
                        ),

                        // Informações adicionais
                        Padding(
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: screenWidth * 0.05,
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Text(
                                      'Por que precisamos dessas informações?',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        fontSize: screenWidth * 0.04,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Text(
                                  '• Seu nome: Para personalizar suas notificações\n'
                                  '• Tempo de detecção: Para configurar a frequência de monitoramento dos seus sinais vitais',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                    fontSize: screenWidth * 0.035,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
