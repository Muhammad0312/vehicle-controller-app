import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/controller_registry.dart';

class SettingsScreen extends StatefulWidget {
  final String currentIP;
  final int currentPort;
  final String currentControllerId;
  final Function(String ip, int port, String controllerId) onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.currentIP,
    required this.currentPort,
    required this.currentControllerId,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late String _selectedControllerId;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.currentIP);
    _portController = TextEditingController(
      text: widget.currentPort.toString(),
    );
    _selectedControllerId = widget.currentControllerId;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid IP address'),
          backgroundColor: Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (port == null || port < 1 || port > 65535) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid port number (1-65535)'),
          backgroundColor: Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tcp_ip', ip);
    await prefs.setInt('tcp_port', port);
    await prefs.setString('controller_id', _selectedControllerId);

    widget.onSettingsChanged(ip, port, _selectedControllerId);

    // Check if widget is still mounted before using context
    if (!mounted) return;
    Navigator.of(context).pop();
    if (!mounted) return;
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
        duration: Duration(milliseconds: 1000), // 1 second
        width: 300, // Constrain width (cannot use with margin)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controllers = ControllerRegistry().getAllControllers();

    return Scaffold(
      backgroundColor: Colors.black, // Solid Black Theme
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Technical Header
            Container(
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
                      'V1.0',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
