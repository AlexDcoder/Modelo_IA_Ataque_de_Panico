import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plenimind_app/schemas/request/vital_data.dart';
import 'package:plenimind_app/service/user_service.dart';
import 'package:plenimind_app/service/ai_notification_service.dart';
import 'package:plenimind_app/service/security_logger_service.dart';
import 'package:plenimind_app/service/call_service.dart';
import 'package:plenimind_app/service/vital_data_generation_service.dart';
import 'package:plenimind_app/utils/data_validator.dart';

class StatusPage extends StatefulWidget {
  static const String routePath = '/status';
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  final UserService _userService = UserService();
  final SecurityLoggerService _securityLogger = SecurityLoggerService();
  final CallService _callService = CallService();
  late VitalDataGeneratorService _vitalGenerator;
  late AINotificationService _aiNotifier;

  UserVitalData _vitalData = UserVitalData(
    heartRate: 72.0,
    respirationRate: 16.0,
    accelStd: 0.5,
    spo2: 98.0,
    stressLevel: 25.0,
  );

  bool _isLoading = true;
  bool _isGeneratingData = false;
  String _errorMessage = '';
  String _userEmail = 'usuario@exemplo.com';
  String _userId = 'user_123'; // TODO: Substituir por ID real do usuário
  String _detectionTime = '00:00:30'; // TODO: Buscar do usuário real

  // Controles para simulação
  Timer? _simulationTimer;
  bool _simulationRunning = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadUserData();
  }

  @override
  void dispose() {
    _vitalGenerator.stopGeneration();
    _simulationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    _vitalGenerator = VitalDataGeneratorService(_userService, _userId);
    _aiNotifier = AINotificationService(
      _callService,
      _userService,
      _securityLogger,
    );
    await _aiNotifier.initialize();

    _securityLogger.logDataValidation('service_initialization', true, {
      'vitalGenerator': 'initialized',
      'aiNotifier': 'initialized',
      'securityLogger': 'initialized',
    });
  }

  Future<void> _loadUserData() async {
    try {
      // TODO: Buscar dados reais da API quando estiver integrado
      // Por enquanto, usamos dados simulados
      await Future.delayed(const Duration(seconds: 2));

      final userData = await _userService.getUserById(_userId);

      setState(() {
        _isLoading = false;
        if (userData != null) {
          _userEmail = userData.email;
          // TODO: Buscar detectionTime do usuário real
        }
      });

      _securityLogger.logDataValidation('user_data_loaded', true, {
        'userId': _userId,
        'email': _userEmail,
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar dados: $e';
      });

      _securityLogger.logDataValidation('user_data_loaded', false, {
        'error': e.toString(),
      });
    }
  }

  void _startDataGeneration() {
    if (DataValidator.validateDetectionTime(_detectionTime)) {
      _vitalGenerator.startGeneration(_detectionTime);
      setState(() {
        _isGeneratingData = true;
      });

      _securityLogger.logDataValidation('data_generation_started', true, {
        'detectionTime': _detectionTime,
        'userId': _userId,
      });
    } else {
      _showSnackBar('Tempo de detecção inválido');
    }
  }

  void _stopDataGeneration() {
    _vitalGenerator.stopGeneration();
    setState(() {
      _isGeneratingData = false;
    });

    _securityLogger.logDataValidation('data_generation_stopped', true, {
      'userId': _userId,
    });
  }

  void _startAISimulation() {
    if (_simulationRunning) return;

    _simulationRunning = true;
    int simulationCount = 0;

    _simulationTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      simulationCount++;

      // Simular predições alternadas (50% chance de pânico)
      final isPanicDetected = simulationCount % 2 == 0;
      final predictionId =
          'simulation_${simulationCount}_${DateTime.now().millisecondsSinceEpoch}';

      final simulatedFeatures = {
        'heart_rate': _vitalData.heartRate,
        'respiration_rate': _vitalData.respirationRate,
        'accel_std': _vitalData.accelStd,
        'spo2': _vitalData.spo2,
        'stress_level': _vitalData.stressLevel,
      };

      // Atualizar dados visuais
      setState(() {
        _vitalData = UserVitalData(
          heartRate:
              60.0 + (isPanicDetected ? 40.0 : 20.0) + (simulationCount % 10),
          respirationRate:
              12.0 + (isPanicDetected ? 10.0 : 5.0) + (simulationCount % 5),
          accelStd: isPanicDetected ? 1.5 + (simulationCount % 10) * 0.1 : 0.5,
          spo2: isPanicDetected ? 92.0 - (simulationCount % 5) : 98.0,
          stressLevel: isPanicDetected ? 70.0 + (simulationCount % 30) : 25.0,
        );
      });

      // Processar predição
      _aiNotifier.handlePrediction(
        predictionId,
        isPanicDetected,
        simulatedFeatures,
        _userId,
      );

      _securityLogger.logAIPrediction(
        predictionId,
        isPanicDetected,
        simulatedFeatures,
      );

      _showSnackBar(
        isPanicDetected ? '🚨 Possível ataque detectado!' : '✅ Status normal',
      );

      // Parar simulação após 10 ciclos para demonstração
      if (simulationCount >= 10) {
        _stopAISimulation();
        _showSnackBar('Simulação concluída');
      }
    });
  }

  void _stopAISimulation() {
    _simulationTimer?.cancel();
    _simulationRunning = false;
    setState(() {});
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PleniMind - Status'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(_isGeneratingData ? Icons.stop : Icons.play_arrow),
              onPressed:
                  _isGeneratingData
                      ? _stopDataGeneration
                      : _startDataGeneration,
              tooltip: _isGeneratingData ? 'Parar geração' : 'Iniciar geração',
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : _buildStatusContent(),
      ),
    );
  }

  Widget _buildStatusContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do usuário
          _buildUserHeader(),
          const SizedBox(height: 20),

          // Controles de simulação
          _buildSimulationControls(),
          const SizedBox(height: 20),

          // Grid de status
          Expanded(child: _buildStatusGrid()),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bem-vindo, $_userEmail!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ID: $_userId',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        Text(
          'Geração de dados: ${_isGeneratingData ? 'ATIVA' : 'INATIVA'}',
          style: TextStyle(
            color: _isGeneratingData ? Colors.green : Colors.orange,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationControls() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simulação do Sistema',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(
                      _simulationRunning ? Icons.stop : Icons.play_arrow,
                    ),
                    label: Text(
                      _simulationRunning
                          ? 'Parar Simulação'
                          : 'Iniciar Simulação',
                    ),
                    onPressed:
                        _simulationRunning
                            ? _stopAISimulation
                            : _startAISimulation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _simulationRunning
                              ? Colors.orange
                              : Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'A simulação enviará predições alternadas a cada 15 segundos',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _buildStatCard(
          value: '${_vitalData.heartRate.toStringAsFixed(1)} bpm',
          label: 'Frequência Cardíaca',
          icon: Icons.favorite,
          color: _vitalData.heartRate > 100 ? Colors.red : Colors.green,
          status: _vitalData.heartRate > 100 ? 'ALTA' : 'NORMAL',
        ),
        _buildStatCard(
          value: '${_vitalData.respirationRate.toStringAsFixed(1)} rpm',
          label: 'Respiração',
          icon: Icons.air,
          color: _vitalData.respirationRate > 20 ? Colors.orange : Colors.blue,
          status: _vitalData.respirationRate > 20 ? 'RÁPIDA' : 'NORMAL',
        ),
        _buildStatCard(
          value: _vitalData.accelStd.toStringAsFixed(2),
          label: 'Movimento',
          icon: Icons.directions_run,
          color: _vitalData.accelStd > 1.0 ? Colors.orange : Colors.blue,
          status: _vitalData.accelStd > 1.0 ? 'AGITADO' : 'NORMAL',
        ),
        _buildStatCard(
          value: '${_vitalData.spo2.toStringAsFixed(1)} %',
          label: 'Saturação O₂',
          icon: Icons.bloodtype,
          color: _vitalData.spo2 < 95 ? Colors.red : Colors.purple,
          status: _vitalData.spo2 < 95 ? 'BAIXA' : 'NORMAL',
        ),
        _buildStatCard(
          value: '${_vitalData.stressLevel.toStringAsFixed(1)} %',
          label: 'Estresse',
          icon: Icons.trending_up,
          color: _vitalData.stressLevel > 50 ? Colors.orange : Colors.green,
          status: _vitalData.stressLevel > 50 ? 'ELEVADO' : 'NORMAL',
        ),
        _buildServiceStatusCard(),
      ],
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required String status,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Serviços',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildServiceStatus('Geração de Dados', _isGeneratingData),
            _buildServiceStatus('Monitoramento IA', true),
            _buildServiceStatus('Notificações', true),
            _buildServiceStatus('Chamadas Emergência', true),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatus(String service, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.error,
            size: 16,
            color: active ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              service,
              style: TextStyle(
                fontSize: 12,
                color: active ? Colors.grey[800] : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
