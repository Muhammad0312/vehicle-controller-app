class ControllerState {
  final String type;
  final List<double> axes;
  final List<int> buttons;
  final int timestamp;

  ControllerState({
    required this.type,
    required this.axes,
    required this.buttons,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'axes': axes,
      'buttons': buttons,
      'timestamp': timestamp,
    };
  }
}
