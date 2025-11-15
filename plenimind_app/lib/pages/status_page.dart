import 'package:flutter/material.dart';
import 'dart:async';
import 'package:plenimind_app/schemas/request/vital_data.dart';
import 'package:plenimind_app/core/auth/auth_manager.dart';
import 'package:plenimind_app/service/user_service.dart';
import 'package:plenimind_app/service/vital_data_service.dart';
import 'package:plenimind_app/service/notification_service.dart';
import 'package:plenimind_app/components/app_drawer.dart';

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
      // ✅ CORREÇÃO: Resetar mensagem de erro antes de carregar
      setState(() {
        _errorMessage = '';
      });

      // ✅ CORREÇÃO: Carregar tokens de forma assíncrona
      await _authManager.reloadTokens();

      final token = _authManager.token;
      final userId = _authManager.userId;

      if (token == null || userId == null) {
        throw Exception('Usuário não autenticado');
      }

      // Buscar dados do usuário
      final userResponse = await _userService.getCurrentUser();
      if (userResponse != null) {
        setState(() {
          _userEmail = userResponse.email;
        });
      }

      // Buscar dados vitais reais
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

        // Processar com IA para notificações
        await _notificationService.processVitalDataAndNotify(
          userId,
          _vitalData,
          token,
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar dados: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PleniMind - Status'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(userEmail: _userEmail),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _buildStatusGrid(),
    );
  }

  Widget _buildStatusGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bem-vindo, $_userEmail!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: [
                _buildStatCard(
                  value: '${_vitalData.heartRate} bpm',
                  label: 'Frequência Cardíaca',
                  icon: Icons.favorite,
                  color: Colors.red,
                ),
                _buildStatCard(
                  value: '${_vitalData.respirationRate} rpm',
                  label: 'Respiração',
                  icon: Icons.air,
                  color: Colors.blue,
                ),
                _buildStatCard(
                  value: _vitalData.accelStd.toStringAsFixed(2),
                  label: 'Movimento',
                  icon: Icons.directions_run,
                  color: Colors.orange,
                ),
                _buildStatCard(
                  value: '${_vitalData.spo2} %',
                  label: 'Saturação O₂',
                  icon: Icons.bloodtype,
                  color: Colors.purple,
                ),
                _buildStatCard(
                  value: '${_vitalData.stressLevel} %',
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
    required String value,
    required String label,
    required IconData icon,
    required Color color,
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
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
