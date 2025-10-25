import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plenimind_app/schemas/request/vital_data.dart';
import 'package:plenimind_app/service/user_service.dart';

/// Serviço que se comunica com o Samsung Health
class SamsungHealthService {
  static const _channel = MethodChannel('com.plenimind/samsung_health');

  /// Busca a frequência cardíaca atual do usuário
  static Future<double?> getHeartRate() async {
    try {
      final double bpm = await _channel.invokeMethod('getHeartRate');
      return bpm;
    } on PlatformException catch (e) {
      debugPrint("Erro ao acessar Samsung Health: ${e.message}");
      return null;
    }
  }
}

class StatusPage extends StatefulWidget {
  static const String routePath = '/status';
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  final UserService _userService = UserService();

  UserVitalData _vitalData = UserVitalData(
    heartRate: 0.0,
    respirationRate: 0.0,
    accelStd: 0.0,
    spo2: 0.0,
    stressLevel: 0.0,
  );

  bool _isLoading = true;
  String _errorMessage = '';
  String _userEmail = 'usuario@exemplo.com'; // Email temporário
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _loadVitalData();
    _startAutoRefresh();
  }

  /// Atualiza os dados vitais periodicamente
  void _startAutoRefresh() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadVitalData();
    });
  }

  /// Busca o batimento cardíaco via Samsung Health e atualiza a tela
  Future<void> _loadVitalData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final heartRate = await SamsungHealthService.getHeartRate();

      if (heartRate == null) {
        throw Exception('Não foi possível obter os batimentos cardíacos.');
      }

      setState(() {
        _vitalData = UserVitalData(
          heartRate: heartRate,
          respirationRate: 16.0, // Valor fixo até integrar os outros dados
          accelStd: 0.5,
          spo2: 98.0,
          stressLevel: (heartRate / 100 * 25).clamp(0, 100), // exemplo simples
        );
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
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PleniMind - Status'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVitalData,
          ),
        ],
      ),
      body: _isLoading
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
                  value: '${_vitalData.heartRate.toStringAsFixed(1)} bpm',
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
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
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
