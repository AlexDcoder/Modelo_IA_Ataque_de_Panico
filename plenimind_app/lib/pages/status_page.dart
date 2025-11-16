import 'package:flutter/material.dart';
import 'dart:async';
import 'package:plenimind_app/schemas/request/vital_data.dart';
import 'package:plenimind_app/core/auth/auth_manager.dart';
import 'package:plenimind_app/service/user_service.dart';
import 'package:plenimind_app/service/vital_data_service.dart';
import 'package:plenimind_app/service/notification_service.dart';
import 'package:plenimind_app/components/app_drawer.dart';
import 'package:plenimind_app/utils/fake_data_generator.dart';
import 'package:plenimind_app/schemas/response/user_personal_request.dart';

class StatusPage extends StatefulWidget {
  static const String routePath = '/status';
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  final UserService _userService = UserService();
  final VitalDataService _vitalDataService = VitalDataService();
  final NotificationService _notificationService = NotificationService();
  final AuthManager _authManager = AuthManager();

  UserVitalData _vitalData = UserVitalData(
    heartRate: 72.0,
    respirationRate: 16.0,
    accelStd: 0.5,
    spo2: 98.0,
    stressLevel: 25.0,
  );

  bool _isLoading = true;
  String _errorMessage = '';
  String _userEmail = 'Carregando...';
  UserPersonalDataResponse? _userData;
  Timer? _pollingTimer;
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Duration _parseDetectionTime(String detectionTime) {
    try {
      final parts = detectionTime.split(':');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    } catch (e) {
      debugPrint('❌ Erro ao parse detection_time: $e - usando fallback de 30s');
      return const Duration(seconds: 30);
    }
  }

  void _startPollingWithDetectionTime() {
    _pollingTimer?.cancel();

    Duration pollingInterval = const Duration(seconds: 30);

    if (_userData?.detectionTime != null) {
      pollingInterval = _parseDetectionTime(_userData!.detectionTime);
    }

    debugPrint('🔁 Iniciando polling com intervalo: $pollingInterval');

    _pollingTimer = Timer.periodic(pollingInterval, (Timer t) {
      _loadVitalDataAndProcess();
    });
  }

  // ✅ CORREÇÃO: Método para SEMPRE enviar dados vitais para o banco
  Future<void> _sendVitalDataToServer(UserVitalData vitalData) async {
    try {
      await _authManager.reloadTokens();
      final token = _authManager.token;
      final userId = _authManager.userId;

      if (token == null || userId == null) {
        throw Exception('Usuário não autenticado');
      }

      // ✅ SEMPRE enviar dados para o banco, independente de ter feedback ou não
      final result = await _vitalDataService.createOrUpdateVitalData(
        userId,
        vitalData,
        token,
      );

      if (result != null) {
        debugPrint(
          '💾 Dados vitais salvos no banco: '
          'HR: ${vitalData.heartRate}, '
          'RR: ${vitalData.respirationRate}, '
          'SPO2: ${vitalData.spo2}',
        );
      } else {
        debugPrint('⚠️ Dados vitais não foram salvos no banco');
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar dados vitais no banco: $e');
    }
  }

  Future<void> _loadVitalDataAndProcess() async {
    try {
      await _authManager.reloadTokens();
      final token = _authManager.token;
      final userId = _authManager.userId;

      if (token == null || userId == null) {
        throw Exception('Usuário não autenticado');
      }

      UserVitalData currentVitalData;

      // ✅ CORREÇÃO: Tentar buscar dados reais do servidor primeiro
      final vitalDataResponse = await _vitalDataService.getUserVitalData(
        userId,
        token,
      );

      if (vitalDataResponse != null) {
        // Usar dados reais do servidor
        currentVitalData = UserVitalData(
          heartRate: vitalDataResponse.heartRate,
          respirationRate: vitalDataResponse.respirationRate,
          accelStd: vitalDataResponse.accelStd,
          spo2: vitalDataResponse.spo2,
          stressLevel: vitalDataResponse.stressLevel,
        );
        debugPrint('✅ Dados vitais carregados do servidor');
      } else {
        // ✅ CORREÇÃO: Gerar novos dados fake e enviar para o servidor
        currentVitalData = FakeDataGenerator.generateFakeVitalData();
        debugPrint('🔄 Gerando novos dados vitais simulados');

        // ✅ IMPORTANTE: Salvar os dados gerados no servidor
        await _sendVitalDataToServer(currentVitalData);
      }

      // ✅ CORREÇÃO: Atualizar interface com novos dados
      if (mounted) {
        setState(() {
          _vitalData = currentVitalData;
          _lastUpdateTime = DateTime.now();
        });
      }

      // ✅ CORREÇÃO: Processar dados com IA para detecção de emergência
      await _notificationService.processVitalDataAndNotify(
        userId,
        currentVitalData,
        token,
      );

      debugPrint(
        '🔄 Dados vitais atualizados na interface: '
        'HR: ${_vitalData.heartRate.toStringAsFixed(1)}, '
        'RR: ${_vitalData.respirationRate.toStringAsFixed(1)}',
      );
    } catch (e) {
      debugPrint('❌ Erro no polling de dados vitais: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _errorMessage = '';
      });

      await _authManager.reloadTokens();

      final token = _authManager.token;
      final userId = _authManager.userId;

      if (token == null || userId == null) {
        throw Exception('Usuário não autenticado');
      }

      // Carregar dados do usuário para obter detection_time
      final userResponse = await _userService.getCurrentUser();
      if (userResponse != null) {
        setState(() {
          _userEmail = userResponse.email;
          _userData = userResponse;
        });
      }

      // ✅ CORREÇÃO: Carregar dados vitais iniciais e garantir que existam no servidor
      final vitalDataResponse = await _vitalDataService.getUserVitalData(
        userId,
        token,
      );

      if (vitalDataResponse != null) {
        setState(() {
          _vitalData = UserVitalData(
            heartRate: vitalDataResponse.heartRate,
            respirationRate: vitalDataResponse.respirationRate,
            accelStd: vitalDataResponse.accelStd,
            spo2: vitalDataResponse.spo2,
            stressLevel: vitalDataResponse.stressLevel,
          );
          _lastUpdateTime = DateTime.now();
        });
        debugPrint('✅ Dados vitais iniciais carregados do servidor');
      } else {
        // ✅ CORREÇÃO: Se não há dados, gerar e salvar no servidor
        final fakeVitalData = FakeDataGenerator.generateFakeVitalData();
        setState(() {
          _vitalData = fakeVitalData;
          _lastUpdateTime = DateTime.now();
        });

        debugPrint('🔄 Criando dados vitais iniciais no servidor');

        // ✅ IMPORTANTE: Salvar dados iniciais no servidor
        await _sendVitalDataToServer(fakeVitalData);
      }

      // Iniciar polling com detection_time após carregar userData
      _startPollingWithDetectionTime();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // ✅ CORREÇÃO: Mesmo em caso de erro, garantir que temos dados para mostrar
      final fakeVitalData = FakeDataGenerator.generateFakeVitalData();
      setState(() {
        _vitalData = fakeVitalData;
        _isLoading = false;
        _lastUpdateTime = DateTime.now();
        _errorMessage = 'Erro ao carregar dados: $e - Usando dados simulados';
      });

      debugPrint('⚠️ Erro ao carregar dados, usando fallback: $e');

      // Iniciar polling mesmo com erro
      _startPollingWithDetectionTime();
    }
  }

  // ✅ NOVO: Método para forçar atualização manual
  Future<void> _refreshData() async {
    await _loadVitalDataAndProcess();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dados atualizados!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PleniMind - Status'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // ✅ NOVO: Botão para atualização manual
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
            tooltip: 'Atualizar dados',
          ),
        ],
      ),
      drawer: AppDrawer(
        userEmail: _userEmail,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
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
                        Icons.warning,
                        size: screenWidth * 0.15,
                        color: Colors.orange,
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
                      SizedBox(
                        width: screenWidth * 0.6,
                        child: ElevatedButton(
                          onPressed: _loadUserData,
                          child: const Text('Tentar Novamente'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : _buildStatusGrid(context),
    );
  }

  Widget _buildStatusGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    int crossAxisCount;
    if (screenWidth < 600) {
      crossAxisCount = 2;
    } else if (screenWidth < 1200) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }

    double childAspectRatio = isPortrait ? 1.0 : 1.3;

    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bem-vindo, $_userEmail!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: screenWidth * 0.06,
                ),
              ),
              // ✅ NOVO: Indicador de última atualização
              if (_lastUpdateTime != null)
                Tooltip(
                  message: 'Última atualização: ${_lastUpdateTime!.toString()}',
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: screenWidth * 0.035,
                          color: Colors.green[600],
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          'Atualizado',
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),

          if (_userData?.detectionTime != null) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenHeight * 0.01,
              ),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: screenWidth * 0.04,
                    color: Colors.blue[600],
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    'Monitoramento a cada ${_userData!.detectionTime}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
          ],

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenHeight * 0.01,
            ),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info,
                  size: screenWidth * 0.04,
                  color: Colors.green[600],
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  'Sistema de monitoramento ativo',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          Expanded(
            child: GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: screenWidth * 0.03,
              mainAxisSpacing: screenHeight * 0.02,
              childAspectRatio: childAspectRatio,
              children: [
                _buildStatCard(
                  context: context,
                  value: '${_vitalData.heartRate.toStringAsFixed(1)} bpm',
                  label: 'Frequência Cardíaca',
                  icon: Icons.favorite,
                  color: Colors.red,
                  lastValue: _vitalData.heartRate,
                ),
                _buildStatCard(
                  context: context,
                  value: '${_vitalData.respirationRate.toStringAsFixed(1)} rpm',
                  label: 'Respiração',
                  icon: Icons.air,
                  color: Colors.blue,
                  lastValue: _vitalData.respirationRate,
                ),
                _buildStatCard(
                  context: context,
                  value: _vitalData.accelStd.toStringAsFixed(2),
                  label: 'Movimento',
                  icon: Icons.directions_run,
                  color: Colors.orange,
                  lastValue: _vitalData.accelStd,
                ),
                _buildStatCard(
                  context: context,
                  value: '${_vitalData.spo2.toStringAsFixed(1)} %',
                  label: 'Saturação O₂',
                  icon: Icons.bloodtype,
                  color: Colors.purple,
                  lastValue: _vitalData.spo2,
                ),
                _buildStatCard(
                  context: context,
                  value: '${_vitalData.stressLevel.toStringAsFixed(1)} %',
                  label: 'Estresse',
                  icon: Icons.trending_up,
                  color: Colors.green,
                  lastValue: _vitalData.stressLevel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required double lastValue,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: screenWidth * 0.07),
            ),
            SizedBox(height: screenHeight * 0.015),
            Text(
              value,
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.032,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            // ✅ NOVO: Indicador visual de que os dados estão sendo atualizados
            SizedBox(height: screenHeight * 0.005),
            Container(
              height: 2,
              width: screenWidth * 0.1,
              decoration: BoxDecoration(
                color: color.withOpacity(0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
