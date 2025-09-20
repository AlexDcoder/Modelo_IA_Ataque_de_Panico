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
          labelText: 'Select Detection Time',
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
        ),
        onTap: () => _showTimerPicker(context),
      ),
    );
  }

  void _showTimerPicker(BuildContext context) {
    Duration tempDuration = initialDuration;

    showModalBottomSheet(
      context: context,
      builder:
          (_) => SizedBox(
            height: 250,
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hms,
                    initialTimerDuration: initialDuration,
                    onTimerDurationChanged: (Duration newDuration) {
                      tempDuration = newDuration;
                    },
                  ),
                ),
                TextButton(
                  onPressed: () {
                    controller.text =
                        "${tempDuration.inHours.toString().padLeft(2, '0')}:"
                        "${(tempDuration.inMinutes % 60).toString().padLeft(2, '0')}:"
                        "${(tempDuration.inSeconds % 60).toString().padLeft(2, '0')}";
                    onDurationChanged(tempDuration);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
    );
  }
}
