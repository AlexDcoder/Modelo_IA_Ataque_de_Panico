// detection_time_manager.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

class DetectionTimeManager {
  static final DetectionTimeManager _instance =
      DetectionTimeManager._internal();
  factory DetectionTimeManager() => _instance;
  DetectionTimeManager._internal();

  final StreamController<Duration> _detectionTimeController =
      StreamController<Duration>.broadcast();

  Duration _currentDetectionTime = const Duration(minutes: 30);
  bool _isInitialized = false;

  Stream<Duration> get detectionTimeStream => _detectionTimeController.stream;

  Duration get currentDetectionTime => _currentDetectionTime;

  bool get isInitialized => _isInitialized;

  void initializeDetectionTime(Duration initialTime) {
    if (!_isInitialized) {
      _currentDetectionTime = initialTime;
      _isInitialized = true;
      debugPrint('✅ [DETECTION_TIME_MANAGER] Inicializado com: $initialTime');
    }
  }

  void updateDetectionTime(Duration newTime) {
    if (_currentDetectionTime != newTime) {
      _currentDetectionTime = newTime;
      _detectionTimeController.add(newTime);
      debugPrint(
        '🔄 [DETECTION_TIME_MANAGER] Detection time atualizado: $newTime',
      );
    } else {
      debugPrint(
        'ℹ️ [DETECTION_TIME_MANAGER] Detection time não alterado: $newTime',
      );
    }
  }

  void dispose() {
    _detectionTimeController.close();
    debugPrint('♻️ [DETECTION_TIME_MANAGER] Dispose executado');
  }
}
