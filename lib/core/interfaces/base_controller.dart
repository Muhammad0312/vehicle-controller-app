import 'package:flutter/material.dart';
import '../models/controller_state.dart';

abstract class BaseController {
  String get id;
  String get name;
  IconData get icon;

  Widget buildUI(
    BuildContext context,
    Function(ControllerState) onStateChanged,
  );
}
