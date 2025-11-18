import 'package:flutter/material.dart';
import 'package:plenimind_app/schemas/request/vital_data.dart';

class EmergencyAlertDialog extends StatefulWidget {
  final String uid;
  final UserVitalData vitalData;
  final String token;
  final VoidCallback onConfirm;
  final VoidCallback onFalseAlarm;

  const EmergencyAlertDialog({
    super.key,
    required this.uid,
    required this.vitalData,
    required this.token,
    required this.onConfirm,
    required this.onFalseAlarm,
  });

  @override
  State<EmergencyAlertDialog> createState() => _EmergencyAlertDialogState();
}

class _EmergencyAlertDialogState extends State<EmergencyAlertDialog> {
  bool _isHandlingResponse = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        backgroundColor: Colors.red[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.red, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '🚨 POSSÍVEL ATAQUE DE PÂNICO DETECTADO',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O sistema detectou sinais vitais indicando um possível ataque de pânico.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15),
            Text(
              'Deseja acionar os contatos de emergência?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              '⚠️ O aplicativo irá ligar automaticamente para seus contatos de emergência.',
              style: TextStyle(fontSize: 14, color: Colors.red),
            ),
          ],
        ),
        actions: [
          if (!_isHandlingResponse) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _isHandlingResponse = true);
                  widget.onFalseAlarm();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close),
                    SizedBox(width: 8),
                    Text('FALSO ALARME'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _isHandlingResponse = true);
                  widget.onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emergency),
                    SizedBox(width: 8),
                    Text('SIM, LIGAR PARA CONTATOS'),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processando...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
