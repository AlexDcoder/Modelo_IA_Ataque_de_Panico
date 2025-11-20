import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  late TextEditingController _controller;
  late Duration _currentDuration;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentDuration = _parseDuration(widget.initialDetectionTime);
    _controller = TextEditingController(
      text: _formatDuration(_currentDuration),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Duration _parseDuration(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 3) {
        return Duration(
          hours: int.parse(parts[0]),
          minutes: int.parse(parts[1]),
          seconds: int.parse(parts[2]),
        );
      }
      return const Duration(hours: 0, minutes: 30, seconds: 0);
    } catch (e) {
      return const Duration(hours: 0, minutes: 30, seconds: 0);
    }
  }

  String _formatDuration(Duration duration) {
    return "${duration.inHours.toString().padLeft(2, '0')}:"
        "${(duration.inMinutes % 60).toString().padLeft(2, '0')}:"
        "${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  void _showTimerPicker(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    Duration tempDuration = _currentDuration;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => Container(
            height: screenHeight * 0.4,
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selecionar Tempo de Detecção',
                      style: GoogleFonts.inter(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        IconButton(
                          onPressed: () {
                            _controller.text = _formatDuration(tempDuration);
                            _currentDuration = tempDuration;
                            widget.onDetectionTimeUpdated(_controller.text);
                            Navigator.of(context).pop();
                          },
                          icon: Container(
                            width: screenWidth * 0.1,
                            height: screenWidth * 0.1,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: screenWidth * 0.05,
                            ),
                          ),
                          tooltip: 'Confirmar',
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                Expanded(
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hms,
                    initialTimerDuration: _currentDuration,
                    onTimerDurationChanged: (Duration newDuration) {
                      tempDuration = newDuration;
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Theme.of(context).primaryColor,
                        size: screenWidth * 0.04,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Tempo selecionado: ',
                        style: GoogleFonts.inter(
                          fontSize: screenWidth * 0.035,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        _formatDuration(tempDuration),
                        style: GoogleFonts.inter(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
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
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.screenWidth * 0.05,
        vertical: widget.screenWidth * 0.02,
      ),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Tempo de Detecção',
          labelStyle: GoogleFonts.inter(
            color: Theme.of(context).textTheme.labelMedium?.color,
            fontSize: widget.screenWidth * 0.04,
          ),
          hintText: 'hh:mm:ss',
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          contentPadding: EdgeInsets.all(widget.screenWidth * 0.04),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              size: widget.screenWidth * 0.04,
            ),
            onPressed: () => _showTimerPicker(context),
            tooltip: 'Selecionar tempo',
          ),
        ),
        onTap: () => _showTimerPicker(context),
      ),
    );
  }
}
