import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:plenimind_app/schemas/request/vital_data.dart';

class FakeDataGenerator {
  static final Random _random = Random();

  // ✅ MODIFICAÇÃO: Gerar dados vitais realistas com ranges ampliados
  static UserVitalData generateFakeVitalData() {
    final data = UserVitalData(
      heartRate: _randomInRange(55.0, 110.0), // BPM - range ampliado
      respirationRate: _randomInRange(10.0, 28.0), // respirações por minuto
      accelStd: _randomInRange(0.05, 4.0), // desvio padrão da aceleração
      spo2: _randomInRange(90.0, 100.0), // saturação de oxigênio
      stressLevel: _randomInRange(0.0, 8.0), // nível de stress
    );

    debugPrint(
      '📊 Dados normais gerados - '
      'HR: ${data.heartRate.toStringAsFixed(1)}, '
      'RR: ${data.respirationRate.toStringAsFixed(1)}, '
      'SPO2: ${data.spo2.toStringAsFixed(1)}',
    );

    return data;
  }

  // ✅ Gerar dados vitais simulando ataque de pânico
  static UserVitalData generatePanicAttackVitalData() {
    final data = UserVitalData(
      heartRate: _randomInRange(100.0, 160.0), // Taquicardia durante ataque
      respirationRate: _randomInRange(20.0, 40.0), // Respiração acelerada
      accelStd: _randomInRange(2.0, 8.0), // Movimento agitado/tremedeira
      spo2: _randomInRange(85.0, 95.0), // Queda na saturação de oxigênio
      stressLevel: _randomInRange(6.0, 10.0), // Estresse elevado
    );

    debugPrint(
      '🎭 Dados de PANICO gerados - '
      'HR: ${data.heartRate.toStringAsFixed(1)}, '
      'RR: ${data.respirationRate.toStringAsFixed(1)}, '
      'SPO2: ${data.spo2.toStringAsFixed(1)}',
    );

    return data;
  }

  // ✅ Gerar dados com 40% de chance de ataque de pânico
  static UserVitalData generateFakeVitalDataWithPanicChance() {
    // 40% de chance de gerar dados de ataque de pânico
    bool isPanicAttack = _random.nextDouble() <= 0.4;

    if (isPanicAttack) {
      return generatePanicAttackVitalData();
    } else {
      return generateFakeVitalData();
    }
  }

  static double _randomInRange(double min, double max) {
    return _random.nextDouble() * (max - min) + min;
  }
}
