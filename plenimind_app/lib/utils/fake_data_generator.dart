import 'dart:math';
import 'package:plenimind_app/schemas/request/vital_data.dart';

class FakeDataGenerator {
  static final Random _random = Random();

  // ✅ MODIFICAÇÃO: Gerar dados vitais realistas com ranges ampliados
  static UserVitalData generateFakeVitalData() {
    return UserVitalData(
      heartRate: _randomInRange(55.0, 110.0), // BPM - range ampliado
      respirationRate: _randomInRange(
        10.0,
        28.0,
      ), // respirações por minuto - range ampliado
      accelStd: _randomInRange(
        0.05,
        4.0,
      ), // desvio padrão da aceleração - range ampliado
      spo2: _randomInRange(
        90.0,
        100.0,
      ), // saturação de oxigênio - range ampliado
      stressLevel: _randomInRange(0.0, 8.0), // nível de stress - range ampliado
    );
  }

  // ✅ REMOVIDO: generatePanicAttackVitalData - não é mais necessário
  // ✅ REMOVIDO: generateNormalVitalData - não é mais necessário
  // ✅ REMOVIDO: generateConsistentVitalData - não é mais necessário

  static double _randomInRange(double min, double max) {
    return _random.nextDouble() * (max - min) + min;
  }
}
