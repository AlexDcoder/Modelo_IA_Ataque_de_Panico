import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'components/sensor_data.dart';
import 'components/sensor_observer.dart';
import 'components/ai_response_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smartwatch App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SensorPage(),
    );
  }
}

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  final String baseUrl = 'http://127.0.0.1:8000';
  final String uid = '-OR2tQK6KPZnMN5Al28T';

  final _formKey = GlobalKey<FormState>();
  final _intervalController = TextEditingController();

  late final SensorObserver sensorObserver;
  late final AIResponseHandler aiHandler;

  Timer? _timer;
  bool _isSending = false;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    sensorObserver = SensorObserver(baseUrl: baseUrl, uid: uid);
    aiHandler = AIResponseHandler(baseUrl: baseUrl, uid: uid);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intervalController.dispose();
    super.dispose();
  }

  SensorData _generateRandomSensorData() {
    return SensorData(
      heartRate: 60 + _random.nextInt(40).toDouble(), // 60-100
      respirationRate: 12 + _random.nextDouble() * 8, // 12-20
      accelStd: 0.1 + _random.nextDouble() * 0.2, // 0.1-0.3
      spo2: 95 + _random.nextDouble() * 5, // 95-100
      stressLevel: _random.nextDouble(), // 0.0-1.0
    );
  }

  void _startPeriodicSending(int intervalMinutes) {
    _timer?.cancel(); // Cancelar se já estiver rodando

    _timer = Timer.periodic(Duration(minutes: intervalMinutes), (_) async {
      final randomData = _generateRandomSensorData();
      final sent = await sensorObserver.sendData(randomData);

      if (sent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados aleatórios enviados!')),
        );

        final prediction = await aiHandler.fetchAIPrediction();
        if (prediction != null) {
          _showFeedbackDialog(randomData, prediction);
        }
      }
    });

    setState(() => _isSending = true);
  }

  void _stopSending() {
    _timer?.cancel();
    setState(() => _isSending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Envio automático interrompido.')),
    );
  }

  void _showFeedbackDialog(SensorData dadosSensor, String prediction) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Resposta da IA"),
            content: Text("Predição: $prediction"),
            actions: [
              TextButton(
                onPressed: () async {
                  await aiHandler.sendFeedback(dadosSensor.toJson(), 1);
                  Navigator.of(context).pop();
                },
                child: const Text("Confirmar"),
              ),
              TextButton(
                onPressed: () async {
                  await aiHandler.sendFeedback(dadosSensor.toJson(), 0);
                  Navigator.of(context).pop();
                },
                child: const Text("Negar"),
              ),
            ],
          ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final interval = int.parse(_intervalController.text);
      _startPeriodicSending(interval);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Envio Automático de Dados")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _intervalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Intervalo de envio (minutos)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o intervalo';
                  }
                  final numValue = int.tryParse(value);
                  if (numValue == null || numValue <= 0) {
                    return 'Intervalo inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSending ? _stopSending : _handleSubmit,
                child: Text(
                  _isSending ? 'Parar Envio' : 'Iniciar Envio Automático',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
