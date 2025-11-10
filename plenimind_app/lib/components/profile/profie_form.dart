import 'package:flutter/material.dart';
import 'package:plenimind_app/components/profile/profile_next_field.dart';
import 'package:plenimind_app/schemas/profile/profile_model.dart';
import 'profile_name_field.dart';
import 'profile_time_field.dart';

class ProfileForm extends StatelessWidget {
  final CreateProfileModel model;
  final VoidCallback onNext;
  final String? nameError;

  const ProfileForm({
    super.key,
    required this.model,
    required this.onNext,
    this.nameError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileNameField(
          controller: model.yourNameTextController!,
          focusNode: model.yourNameFocusNode!,
          errorText: nameError,
        ),
        ProfileTimeField(
          controller: model.cityTextController!,
          focusNode: model.cityFocusNode!,
          initialDuration: model.selectedDuration,
          onDurationChanged: (newDuration) {
            model.selectedDuration = newDuration;
          },
        ),
        ProfileNextButton(onPressed: onNext),
      ],
    );
  }
}
