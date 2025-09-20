import 'package:flutter/material.dart';

class CreateProfileModel {
  TextEditingController? yourNameTextController;
  FocusNode? yourNameFocusNode;

  TextEditingController? cityTextController;
  FocusNode? cityFocusNode;

  Duration selectedDuration = Duration.zero;

  void dispose() {
    yourNameTextController?.dispose();
    yourNameFocusNode?.dispose();
    cityTextController?.dispose();
    cityFocusNode?.dispose();
  }
}
