import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import 'package:smartwatch_app/models/request/user_personal_data.dart';
import 'package:smartwatch_app/models/request/user_vital_data.dart';
import 'package:smartwatch_app/models/response/user_feedback.dart';
import 'package:smartwatch_app/services/user_service.dart';

class UserFormPage extends StatefulWidget {
  const UserFormPage({super.key});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  final userService = UserService();
  final Random _random = Random();

  String email = '';
  String password = '';
  int detectionTime = 0;

  String? uid;
  Timer? _timer;
  bool _isWaitingResponse = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final user = UserPersonalData(
        email: email,
        password: password,
        detectionTime: detectionTime,
      );

      try {
        final response = await userService.createUser(user);

        if (response != null) {
          setState(() {
            uid = response.uid;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conectado ao servidor com sucesso!')),
          );

          await _sendVitalData(); // Envia primeira vez imediatamente
          _startSendingVitals(); // Inicia timer
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Falha ao criar usuário no servidor.'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro de conexão: $e')));
      }
    }
  }

  void _startSendingVitals() {
    final duration = Duration(minutes: detectionTime);
    _timer?.cancel();
    _timer = Timer.periodic(duration, (_) async {
      if (!_isWaitingResponse) {
        await _sendVitalData();
      }
    });
  }

  Future<void> _sendVitalData() async {
    if (uid == null) return;

    final generatedVitals = UserVitalData(
      heartRate: 60 + _random.nextDouble() * 40,
      respirationRate: 12 + _random.nextDouble() * 8,
      accelStd: _random.nextDouble() * 0.5,
      spo2: 92 + _random.nextDouble() * 6,
      stressLevel: _random.nextDouble() * 5,
    );

    await userService.createVitalData(uid!, generatedVitals);

    final prediction = await userService.getAiPrediction(uid!);

    if (prediction != null && mounted) {
      setState(() {
        _isWaitingResponse = true;
      });

      final features = {
        'heart_rate': generatedVitals.heartRate,
        'respiration_rate': generatedVitals.respirationRate,
        'accel_std': generatedVitals.accelStd,
        'spo2': generatedVitals.spo2,
        'stress_level': generatedVitals.stressLevel,
      };

      await _showNotification(prediction['ai_prediction'].toString(), features);

      setState(() {
        _isWaitingResponse = false;
      });
    }
  }

  Future<void> _showNotification(
    String prediction,
    Map<String, double> features,
  ) async {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      title: 'Resposta da IA',
      desc: 'Predição: $prediction\nDeseja confirmar esse resultado?',
      btnOkText: 'Confirmar',
      btnCancelText: 'Negar',
      btnCancelOnPress: () async {
        if (uid != null) {
          final feedback = FeedbackInput(
            uid: uid!,
            features: features,
            userFeedback: 0,
          );
          await userService.sendFeedback(uid!, feedback);
        }
      },
      btnOkOnPress: () async {
        if (uid != null) {
          final feedback = FeedbackInput(
            uid: uid!,
            features: features,
            userFeedback: 1,
          );
          await userService.sendFeedback(uid!, feedback);
        }
      },
    ).show();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formulário do Usuário')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Dados Pessoais',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe um email.';
                  }
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Email inválido.';
                  }
                  return null;
                },
                onSaved: (value) => email = value!.trim(),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe uma senha.';
                  }
                  if (value.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres.';
                  }
                  return null;
                },
                onSaved: (value) => password = value!.trim(),
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Detection Time (em minutos)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o tempo de detecção.';
                  }
                  final number = int.tryParse(value.trim());
                  if (number == null || number <= 1) {
                    return 'Digite um número inteiro maior que 1.';
                  }
                  return null;
                },
                onSaved: (value) => detectionTime = int.parse(value!.trim()),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Iniciar Simulação'),
              ),
              if (_isWaitingResponse)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
