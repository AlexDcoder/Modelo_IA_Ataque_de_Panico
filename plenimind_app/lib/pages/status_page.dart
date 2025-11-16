import 'package:flutter/material.dart';
import 'dart:async';
import 'package:plenimind_app/schemas/request/vital_data.dart';
import 'package:plenimind_app/core/auth/auth_manager.dart';
import 'package:plenimind_app/service/user_service.dart';
import 'package:plenimind_app/service/vital_data_service.dart';
import 'package:plenimind_app/service/notification_service.dart';
import 'package:plenimind_app/components/app_drawer.dart';
import 'package:plenimind_app/utils/fake_data_generator.dart';

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
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Iniciar polling a cada 30 segundos
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (Timer t) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
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

      final userResponse = await _userService.getCurrentUser();
      if (userResponse != null) {
        setState(() {
          _userEmail = userResponse.email;
        });
      }

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
        });

        debugPrint('✅ Using real vital data from server');
      } else {
        final fakeVitalData = FakeDataGenerator.generateFakeVitalData();
        setState(() {
          _vitalData = fakeVitalData;
        });

        debugPrint('ℹ️ Using generated vital data (no server data available)');

        try {
          await _vitalDataService.createOrUpdateVitalData(
            userId,
            fakeVitalData,
            token,
          );
          debugPrint('✅ Initial vital data created on server');
        } catch (e) {
          debugPrint('⚠️ Could not create initial vital data on server: $e');
        }
      }

      await _notificationService.processVitalDataAndNotify(
        userId,
        _vitalData,
        token,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      final fakeVitalData = FakeDataGenerator.generateFakeVitalData();
      setState(() {
        _vitalData = fakeVitalData;
        _isLoading = false;
        _errorMessage = 'Erro ao carregar dados: $e - Usando dados simulados';
      });

      debugPrint('⚠️ Error loading data, using fallback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PleniMind - Status'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
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

    // Calcular número de colunas baseado no tamanho da tela
    int crossAxisCount;
    if (screenWidth < 600) {
      crossAxisCount = 2; // Telas pequenas
    } else if (screenWidth < 1200) {
      crossAxisCount = 3; // Telas médias
    } else {
      crossAxisCount = 4; // Telas grandes
    }

    // Ajustar aspect ratio baseado na orientação
    double childAspectRatio = isPortrait ? 1.0 : 1.3;

    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bem-vindo, $_userEmail!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: screenWidth * 0.06,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
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
                ),
                _buildStatCard(
                  context: context,
                  value: '${_vitalData.respirationRate.toStringAsFixed(1)} rpm',
                  label: 'Respiração',
                  icon: Icons.air,
                  color: Colors.blue,
                ),
                _buildStatCard(
                  context: context,
                  value: _vitalData.accelStd.toStringAsFixed(2),
                  label: 'Movimento',
                  icon: Icons.directions_run,
                  color: Colors.orange,
                ),
                _buildStatCard(
                  context: context,
                  value: '${_vitalData.spo2.toStringAsFixed(1)} %',
                  label: 'Saturação O₂',
                  icon: Icons.bloodtype,
                  color: Colors.purple,
                ),
                _buildStatCard(
                  context: context,
                  value: '${_vitalData.stressLevel.toStringAsFixed(1)} %',
                  label: 'Estresse',
                  icon: Icons.trending_up,
                  color: Colors.green,
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
                color: color.withValues(alpha: 0.1),
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
          ],
        ),
      ),
    );
  }
}
