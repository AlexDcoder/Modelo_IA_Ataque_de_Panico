import 'package:flutter/material.dart';
import 'package:plenimind_app/components/profile/profile_next_field.dart';
import 'package:plenimind_app/schemas/profile/profile_model.dart';
import 'profile_name_field.dart';
import 'profile_time_field.dart';

class ProfileForm extends StatelessWidget {
  final CreateProfileModel model;
  final VoidCallback onNext;
  final double screenWidth;

  const ProfileForm({
    super.key,
    required this.model,
    required this.onNext,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileNameField(
          controller: model.yourNameTextController!,
          focusNode: model.yourNameFocusNode!,
          screenWidth: screenWidth,
        ),
        ProfileTimeField(
          controller: model.cityTextController!,
          focusNode: model.cityFocusNode!,
          initialDuration: model.selectedDuration,
          onDurationChanged: (newDuration) {
            model.selectedDuration = newDuration;
          },
          screenWidth: screenWidth,
        ),
        ProfileNextButton(onPressed: onNext, screenWidth: screenWidth),
      ],
    );
  }
}
