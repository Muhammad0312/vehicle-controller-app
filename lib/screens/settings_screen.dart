import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/controller_registry.dart';
import '../core/di/service_locator.dart';
import '../core/providers.dart';
import '../core/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late String _selectedControllerId;
  late double _sensitivity;
  late double _deadzone;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _ipController = TextEditingController(text: settings.ip);
    _portController = TextEditingController(text: settings.port.toString());
    _selectedControllerId = settings.controllerId;
    _sensitivity = settings.steeringSensitivity;
    _deadzone = settings.deadzone;
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());

    if (ip.isEmpty) {
      _showError('Please enter a valid IP address');
      return;
    }

    if (port == null || port < 1 || port > 65535) {
      _showError('Please enter a valid port number (1-65535)');
      return;
    }

    await ref
        .read(settingsProvider.notifier)
        .updateSettings(
          ip: ip,
          port: port,
          controllerId: _selectedControllerId,
          steeringSensitivity: _sensitivity,
          deadzone: _deadzone,
        );

    // Refresh TCP connection if connection settings changed
    // This is handled by HomeScreen watching the settings or we can force it here
    final tcpClient = ref.read(tcpClientProvider);
    tcpClient.updateIP(ip);
    tcpClient.updatePort(port);
    tcpClient.connect();

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Settings saved successfully'),
          ],
        ),
        backgroundColor: Color(0xFF00D4AA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 1),
        width: 300,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFFFF6B6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controllers = getIt<ControllerRegistry>().getAllControllers();

    // Ensure selected ID is valid to prevent Dropdown crash
    if (!controllers.any((c) => c.id == _selectedControllerId)) {
      if (controllers.any((c) => c.id == 'touch_drive')) {
        _selectedControllerId = 'touch_drive';
      } else if (controllers.isNotEmpty) {
        _selectedControllerId = controllers.first.id;
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader('NETWORK CONFIGURATION'),
                    SizedBox(height: 16),
                    _buildTechnicalTextField(
                      controller: _ipController,
                      label: 'TARGET IP ADDRESS',
                      hint: '192.168.1.100',
                      icon: Icons.wifi,
                    ),
                    SizedBox(height: 16),
                    _buildTechnicalTextField(
                      controller: _portController,
                      label: 'TARGET PORT',
                      hint: '8080',
                      icon: Icons.dns,
                      isNumber: true,
                    ),
                    SizedBox(height: 32),

                    _buildSectionHeader('CONTROLS'),
                    SizedBox(height: 16),
                    _buildSlider(
                      label: 'STEERING SENSITIVITY',
                      value: _sensitivity,
                      min: 0.1,
                      max: 2.0,
                      divisions: 19,
                      icon: Icons.speed,
                      onChanged: (val) => setState(() => _sensitivity = val),
                    ),
                    SizedBox(height: 16),
                    _buildSlider(
                      label: 'DEADZONE',
                      value: _deadzone,
                      min: 0.0,
                      max: 0.5,
                      divisions: 10,
                      icon: Icons.track_changes,
                      onChanged: (val) => setState(() => _deadzone = val),
                    ),
                    SizedBox(height: 32),

                    _buildSectionHeader('CONTROLLER INTERFACE'),
                    SizedBox(height: 16),
                    _buildTechnicalDropdown(
                      value: _selectedControllerId,
                      items: controllers,
                      onChanged: (val) {
                        setState(() {
                          _selectedControllerId = val!;
                        });
                      },
                    ),

                    SizedBox(height: 48),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTechnicalIconButton(
            Icons.arrow_back,
            () => Navigator.of(context).pop(),
          ),
          SizedBox(width: 20),
          Text(
            'SYSTEM SETTINGS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyanAccent, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'V1.1',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, color: Colors.cyanAccent),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.cyanAccent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white54, size: 18),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white24),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            Spacer(),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                color: Colors.cyanAccent,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Icon(icon, color: Colors.white54, size: 18),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.cyanAccent,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.white,
                    overlayColor: Colors.cyanAccent.withValues(alpha: 0.2),
                    trackHeight: 2,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalDropdown({
    required String value,
    required List<dynamic> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVE LAYOUT',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Color(0xFF1E1E1E),
              icon: Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((controller) {
                return DropdownMenuItem<String>(
                  value: controller.id,
                  child: Row(
                    children: [
                      Icon(controller.icon, size: 16, color: Colors.white70),
                      SizedBox(width: 12),
                      Text(controller.name.toUpperCase()),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveSettings,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.greenAccent.withValues(alpha: 0.1),
          border: Border.all(color: Colors.greenAccent, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_alt, color: Colors.greenAccent),
            SizedBox(width: 12),
            Text(
              'APPLY CONFIGURATION',
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
