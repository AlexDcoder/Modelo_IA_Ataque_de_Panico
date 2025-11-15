import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileTimeField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Duration initialDuration;
  final void Function(Duration) onDurationChanged;

  const ProfileTimeField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.initialDuration,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Tempo de Detecção',
          labelStyle: GoogleFonts.inter(
            color: Theme.of(context).textTheme.labelMedium?.color,
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
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () => _showTimerPicker(context),
            tooltip: 'Selecionar tempo',
          ),
        ),
        onTap: () => _showTimerPicker(context),
      ),
    );
  }

  void _showTimerPicker(BuildContext context) {
    Duration tempDuration = initialDuration;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => Container(
            height: MediaQuery.of(context).size.height * 0.4,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header do picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selecionar Tempo',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        // Botão Cancelar
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.inter(color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Botão Confirmar (>)
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          tooltip: 'Confirmar',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Picker de tempo
                Expanded(
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hms,
                    initialTimerDuration: initialDuration,
                    onTimerDurationChanged: (Duration newDuration) {
                      tempDuration = newDuration;
                    },
                  ),
                ),

                // Preview do tempo selecionado
                Container(
                  padding: const EdgeInsets.all(12),
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
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tempo selecionado: ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        "${tempDuration.inHours.toString().padLeft(2, '0')}:"
                        "${(tempDuration.inMinutes % 60).toString().padLeft(2, '0')}:"
                        "${(tempDuration.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: GoogleFonts.inter(
                          fontSize: 14,
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
