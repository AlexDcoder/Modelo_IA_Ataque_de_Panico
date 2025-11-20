import 'dart:async';
import 'package:flutter/foundation.dart';

class DetectionTimerService {
  Timer? _detectionTimer;
  Duration _currentInterval = const Duration(minutes: 30);
  Function? _onDetectionCallback;
  bool _isRunning = false;
  bool _isProcessing = false; // Nova flag para controlar processamento

  void startDetection({
    required Duration interval,
    required Function onDetection,
  }) {
    debugPrint(
      '🔄 [DETECTION_TIMER] Iniciando temporizador com intervalo: $interval',
    );

    _currentInterval = interval;
    _onDetectionCallback = onDetection;
    _isRunning = true;

    _startTimer();
  }

  void updateDetectionInterval(Duration newInterval) {
    debugPrint(
      '🔄 [DETECTION_TIMER] Atualizando intervalo: $_currentInterval → $newInterval',
    );

    _currentInterval = newInterval;

    if (_isRunning) {
      _restartTimer();
    }
  }

  void _startTimer() {
    _detectionTimer?.cancel();

    _detectionTimer = Timer.periodic(_currentInterval, (timer) async {
      if (_isProcessing) {
        debugPrint(
          '⏳ [DETECTION_TIMER] Processamento anterior em andamento, ignorando...',
        );
        return;
      }

      debugPrint('⏰ [DETECTION_TIMER] Timer disparado - executando callback');

      _isProcessing = true;
      try {
        await _onDetectionCallback?.call();
      } catch (e) {
        debugPrint('❌ [DETECTION_TIMER] Erro no callback: $e');
      } finally {
        _isProcessing = false;
      }
    });

    debugPrint(
      '✅ [DETECTION_TIMER] Timer iniciado com intervalo: $_currentInterval',
    );
  }

  void _restartTimer() {
    debugPrint('🔄 [DETECTION_TIMER] Reiniciando timer com novo intervalo');
    _startTimer();
  }

  // Método para verificar se está processando (útil para outras services)
  bool get isProcessing => _isProcessing;

  void stopDetection() {
    debugPrint('🛑 [DETECTION_TIMER] Parando detecção');
    _detectionTimer?.cancel();
    _detectionTimer = null;
    _isRunning = false;
    _isProcessing = false;
  }

  bool get isRunning => _isRunning;
  Duration get currentInterval => _currentInterval;

  void dispose() {
    debugPrint('♻️ [DETECTION_TIMER] Dispose chamado');
    _detectionTimer?.cancel();
    _onDetectionCallback = null;
    _isProcessing = false;
  }
}
