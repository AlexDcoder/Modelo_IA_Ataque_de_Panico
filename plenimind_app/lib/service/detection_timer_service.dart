// detection_timer_service.dart (ATUALIZADO)
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:plenimind_app/service/detection_time_manager.dart';

class DetectionTimerService {
  Timer? _detectionTimer;
  Duration _currentInterval = const Duration(minutes: 30);
  Function? _onDetectionCallback;
  bool _isRunning = false;
  bool _isProcessing = false;

  final DetectionTimeManager _detectionTimeManager = DetectionTimeManager();
  StreamSubscription<Duration>? _detectionTimeSubscription;

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

    // ✅ INICIALIZAR DETECTION TIME MANAGER
    _detectionTimeManager.initializeDetectionTime(interval);

    // ✅ OUVIR MUDANÇAS NO DETECTION TIME
    _setupDetectionTimeListener();

    _startTimer();
  }

  void _setupDetectionTimeListener() {
    _detectionTimeSubscription?.cancel();

    _detectionTimeSubscription = _detectionTimeManager.detectionTimeStream
        .listen(
          (newDuration) {
            debugPrint(
              '🎯 [DETECTION_TIMER] Nova duração recebida: $newDuration',
            );
            _handleDetectionTimeChange(newDuration);
          },
          onError: (error) {
            debugPrint('❌ [DETECTION_TIMER] Erro no stream: $error');
          },
          onDone: () {
            debugPrint('🔚 [DETECTION_TIMER] Stream fechado');
          },
        );
  }

  void _handleDetectionTimeChange(Duration newDuration) {
    if (_currentInterval != newDuration) {
      debugPrint(
        '🔄 [DETECTION_TIMER] Atualizando intervalo: $_currentInterval → $newDuration',
      );

      _currentInterval = newDuration;

      if (_isRunning) {
        _restartTimer();

        // ✅ NOTIFICAR INTERFACE SE NECESSÁRIO
        debugPrint(
          '✅ [DETECTION_TIMER] Timer reiniciado com novo intervalo: $newDuration',
        );
      } else {
        debugPrint(
          'ℹ️ [DETECTION_TIMER] Timer não está rodando, apenas atualizando intervalo',
        );
      }
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
      debugPrint('   📊 Intervalo atual: $_currentInterval');

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
    debugPrint(
      '🔄 [DETECTION_TIMER] Reiniciando timer com novo intervalo: $_currentInterval',
    );
    _startTimer();
  }

  void updateDetectionInterval(Duration newInterval) {
    debugPrint(
      '🔄 [DETECTION_TIMER] Atualização manual do intervalo: $_currentInterval → $newInterval',
    );
    _currentInterval = newInterval;

    if (_isRunning) {
      _restartTimer();
    }
  }

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
    _detectionTimeSubscription?.cancel();
    _onDetectionCallback = null;
    _isProcessing = false;
  }
}
