import 'package:flutter/material.dart';
import 'package:plenimind_app/components/profile/profile_next_field.dart';
import 'package:plenimind_app/schemas/profile/profile_model.dart';
import 'profile_name_field.dart';
import 'profile_time_field.dart';

class ProfileForm extends StatelessWidget {
  final CreateProfileModel model;
  final VoidCallback onNext;

  const ProfileForm({super.key, required this.model, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileNameField(
          controller: model.yourNameTextController!,
          focusNode: model.yourNameFocusNode!,
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
