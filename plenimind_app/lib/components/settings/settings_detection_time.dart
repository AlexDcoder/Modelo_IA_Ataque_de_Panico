import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsDetectionTime extends StatefulWidget {
  final String initialDetectionTime;
  final Function(String) onDetectionTimeUpdated;
  final double screenWidth;

  const SettingsDetectionTime({
    super.key,
    required this.initialDetectionTime,
    required this.onDetectionTimeUpdated,
    required this.screenWidth,
  });

  @override
  State<SettingsDetectionTime> createState() => _SettingsDetectionTimeState();
}

class _SettingsDetectionTimeState extends State<SettingsDetectionTime> {
  late Duration _currentDuration;

  @override
  void initState() {
    super.initState();
    _currentDuration = _parseDuration(widget.initialDetectionTime);
  }

  Duration _parseDuration(String timeString) {
    final parts = timeString.split(':');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(parts[2]),
    );
  }

  String _formatDuration(Duration duration) {
    return "${duration.inHours.toString().padLeft(2, '0')}:"
        "${(duration.inMinutes % 60).toString().padLeft(2, '0')}:"
        "${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  void _showTimePicker() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.4,
            padding: EdgeInsets.all(widget.screenWidth * 0.04),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Configurar Tempo de Detecção',
                      style: TextStyle(
                        fontSize: widget.screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        SizedBox(width: widget.screenWidth * 0.02),
                        ElevatedButton(
                          onPressed: () {
                            widget.onDetectionTimeUpdated(
                              _formatDuration(_currentDuration),
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: widget.screenWidth * 0.04),
                Expanded(
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hms,
                    initialTimerDuration: _currentDuration,
                    onTimerDurationChanged: (Duration newDuration) {
                      setState(() {
                        _currentDuration = newDuration;
                      });
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(widget.screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Theme.of(context).colorScheme.primary,
                        size: widget.screenWidth * 0.04,
                      ),
                      SizedBox(width: widget.screenWidth * 0.02),
                      Text(
                        'Tempo selecionado: ',
                        style: TextStyle(fontSize: widget.screenWidth * 0.035),
                      ),
                      Text(
                        _formatDuration(_currentDuration),
                        style: TextStyle(
                          fontSize: widget.screenWidth * 0.035,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intervalo de verificação dos sinais vitais',
          style: TextStyle(
            fontSize: widget.screenWidth * 0.04,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: widget.screenWidth * 0.02),
        ListTile(
          leading: Icon(
            Icons.timer,
            color: Theme.of(context).colorScheme.primary,
            size: widget.screenWidth * 0.06,
          ),
          title: Text(
            _formatDuration(_currentDuration),
            style: TextStyle(
              fontSize: widget.screenWidth * 0.045,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Horas : Minutos : Segundos',
            style: TextStyle(fontSize: widget.screenWidth * 0.035),
          ),
          trailing: IconButton(
            icon: Icon(Icons.edit, size: widget.screenWidth * 0.05),
            onPressed: _showTimePicker,
            tooltip: 'Alterar tempo',
          ),
          onTap: _showTimePicker,
        ),
      ],
    );
  }
}
