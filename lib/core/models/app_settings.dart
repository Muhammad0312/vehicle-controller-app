class AppSettings {
  final String ip;
  final int port;
  final String controllerId;
  final double steeringSensitivity;
  final double deadzone;

  const AppSettings({
    this.ip = '192.168.1.100',
    this.port = 8080,
    this.controllerId = 'touch_drive',
    this.steeringSensitivity = 1.0,
    this.deadzone = 0.05,
  });

  AppSettings copyWith({
    String? ip,
    int? port,
    String? controllerId,
    double? steeringSensitivity,
    double? deadzone,
  }) {
    return AppSettings(
      ip: ip ?? this.ip,
      port: port ?? this.port,
      controllerId: controllerId ?? this.controllerId,
      steeringSensitivity: steeringSensitivity ?? this.steeringSensitivity,
      deadzone: deadzone ?? this.deadzone,
    );
  }
}
