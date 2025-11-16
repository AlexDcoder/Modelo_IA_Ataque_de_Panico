import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileTimeField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Duration initialDuration;
  final void Function(Duration) onDurationChanged;
  final double screenWidth;

  const ProfileTimeField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.initialDuration,
    required this.onDurationChanged,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenWidth * 0.02,
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Tempo de Detecção',
          labelStyle: GoogleFonts.inter(
            color: Theme.of(context).textTheme.labelMedium?.color,
            fontSize: screenWidth * 0.04,
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
          contentPadding: EdgeInsets.all(screenWidth * 0.04),
          suffixIcon: IconButton(
            icon: Icon(Icons.arrow_forward_ios, size: screenWidth * 0.04),
            onPressed: () => _showTimerPicker(context),
            tooltip: 'Selecionar tempo',
          ),
        ),
        onTap: () => _showTimerPicker(context),
      ),
    );
  }

  void _showTimerPicker(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    Duration tempDuration = initialDuration;

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
                      'Selecionar Tempo',
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
                            controller.text =
                                "${tempDuration.inHours.toString().padLeft(2, '0')}:"
                                "${(tempDuration.inMinutes % 60).toString().padLeft(2, '0')}:"
                                "${(tempDuration.inSeconds % 60).toString().padLeft(2, '0')}";
                            onDurationChanged(tempDuration);
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
                    initialTimerDuration: initialDuration,
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
                        "${tempDuration.inHours.toString().padLeft(2, '0')}:"
                        "${(tempDuration.inMinutes % 60).toString().padLeft(2, '0')}:"
                        "${(tempDuration.inSeconds % 60).toString().padLeft(2, '0')}",
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
}
