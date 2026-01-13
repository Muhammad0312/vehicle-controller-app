import '../interfaces/base_controller.dart';

class ControllerRegistry {
  final Map<String, BaseController> _controllers = {};

  void register(BaseController controller) {
    _controllers[controller.id] = controller;
  }

  BaseController? getController(String id) {
    return _controllers[id];
  }

  List<BaseController> getAllControllers() {
    return _controllers.values.toList();
  }

  String get defaultControllerId {
    if (_controllers.isNotEmpty) {
      return _controllers.keys.first;
    }
    return '';
  }
}
