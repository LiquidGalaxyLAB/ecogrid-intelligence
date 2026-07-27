import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/enums/connection_status.dart';
import '../core/resources/data_state.dart';
import '../di/di.dart';
import '../service/lg_service.dart';
import 'kml_test_generators.dart';

class _LogEntry {
  final String action;
  final bool success;
  final String timestamp;

  _LogEntry({
    required this.action,
    required this.success,
    required this.timestamp,
  });
}

class KmlTestPage extends StatefulWidget {
  const KmlTestPage({super.key});

  @override
  State<KmlTestPage> createState() => _KmlTestPageState();
}

class _KmlTestPageState extends State<KmlTestPage> {
  late final LGService _lgService;
  _LogEntry? _lastLog;
  bool _isOrbiting = false;
  int _selectedScreen = 1;
  final TextEditingController _customKmlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _lgService = sl<LGService>();
    final int maxScreens = _lgService.screenCount > 0 ? _lgService.screenCount : 3;
    if (_selectedScreen > maxScreens) {
      _selectedScreen = maxScreens;
    }
  }

  @override
  void dispose() {
    _customKmlController.dispose();
    super.dispose();
  }

  void _addLog(String action, bool success) {
    setState(() {
      _lastLog = _LogEntry(
        action: action,
        success: success,
        timestamp: DateFormat('hh:mm:ss a').format(DateTime.now()),
      );
    });
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _sendKmlAction(String label, String kmlContent, {bool isBalloon = false}) async {
    try {
      await Clipboard.setData(ClipboardData(text: kmlContent));
      if (isBalloon) {
        final settingsRes = await _lgService.loadSettings();
        final int rightScreen = settingsRes is DataSuccess && settingsRes.data != null
            ? settingsRes.data!.rightmostScreen
            : (_lgService.screenCount > 1 ? _lgService.screenCount : 2);
        final res = await _lgService.showBalloonOnSlave(rightScreen, kmlContent);
        if (res is DataSuccess) {
          await _lgService.flyTo(
            KmlTestGenerators.defaultLat,
            KmlTestGenerators.defaultLon,
            0,
            0,
            45,
            2500,
          );
          _addLog(label, true);
          _showSnackbar('$label copied to clipboard & sent successfully!');
        } else {
          _addLog(label, false);
          _showSnackbar('Failed to send $label', isError: true);
        }
      } else {
        final res = await _lgService.sendKmlToAllScreens(kmlContent);
        if (res is DataSuccess) {
          await _lgService.flyTo(
            KmlTestGenerators.defaultLat,
            KmlTestGenerators.defaultLon,
            0,
            0,
            60,
            3500,
          );
          _addLog(label, true);
          _showSnackbar('$label copied to clipboard & sent successfully!');
        } else {
          _addLog(label, false);
          _showSnackbar('Failed to send $label', isError: true);
        }
      }
    } catch (e) {
      _addLog(label, false);
      _showSnackbar('Error: $e', isError: true);
    }
  }

  Future<void> _toggleOrbitTour() async {
    try {
      if (_isOrbiting) {
        await _lgService.stopOrbit();
        setState(() => _isOrbiting = false);
        _addLog('Stop Orbit Tour', true);
        _showSnackbar('Orbit tour stopped');
      } else {
        final kml = KmlTestGenerators.buildOrbitTourKml();
        await Clipboard.setData(ClipboardData(text: kml));
        final res = await _lgService.startOrbit(
          KmlTestGenerators.defaultLat,
          KmlTestGenerators.defaultLon,
          4000,
          60,
        );
        if (res is DataSuccess) {
          setState(() => _isOrbiting = true);
          _addLog('Send Orbit Tour', true);
          _showSnackbar('Orbit tour copied to clipboard & started!');
        } else {
          _addLog('Send Orbit Tour', false);
          _showSnackbar('Failed to send Orbit Tour', isError: true);
        }
      }
    } catch (e) {
      _addLog('Orbit Tour', false);
      _showSnackbar('Error: $e', isError: true);
    }
  }

  Future<void> _sendCustomKml() async {
    final kml = _customKmlController.text.trim();
    if (kml.isEmpty) {
      _showSnackbar('Please paste custom KML first', isError: true);
      return;
    }
    try {
      await Clipboard.setData(ClipboardData(text: kml));
      final res = await _lgService.sendKmlToScreen(_selectedScreen, kml);
      if (res is DataSuccess) {
        _addLog('Custom KML (Screen $_selectedScreen)', true);
        _showSnackbar('Custom KML copied to clipboard & sent to Screen $_selectedScreen!');
      } else {
        _addLog('Custom KML (Screen $_selectedScreen)', false);
        _showSnackbar('Failed to send custom KML', isError: true);
      }
    } catch (e) {
      _addLog('Custom KML (Screen $_selectedScreen)', false);
      _showSnackbar('Error: $e', isError: true);
    }
  }

  Future<void> _clearKml() async {
    try {
      if (_isOrbiting) {
        await _lgService.stopOrbit();
        setState(() => _isOrbiting = false);
      }
      final settingsRes = await _lgService.loadSettings();
      final int rightScreen = settingsRes is DataSuccess && settingsRes.data != null
          ? settingsRes.data!.rightmostScreen
          : (_lgService.screenCount > 1 ? _lgService.screenCount : 2);
      await _lgService.clearBalloonOnSlave(rightScreen);
      final res = await _lgService.clearKml();
      if (res is DataSuccess) {
        _addLog('Clear KML', true);
        _showSnackbar('KML cleared successfully');
      } else {
        _addLog('Clear KML', false);
        _showSnackbar('Failed to clear KML', isError: true);
      }
    } catch (e) {
      _addLog('Clear KML', false);
      _showSnackbar('Error: $e', isError: true);
    }
  }

  Future<void> _reconnect() async {
    try {
      final settingsRes = await _lgService.loadSettings();
      if (settingsRes is DataSuccess && settingsRes.data != null) {
        final res = await _lgService.connect(settingsRes.data!);
        if (res is DataSuccess) {
          _addLog('Reconnect', true);
          _showSnackbar('Reconnected to Liquid Galaxy');
        } else {
          _addLog('Reconnect', false);
          _showSnackbar('Reconnect failed', isError: true);
        }
      } else {
        _addLog('Reconnect', false);
        _showSnackbar('Failed to load LG settings', isError: true);
      }
      setState(() {});
    } catch (e) {
      _addLog('Reconnect', false);
      _showSnackbar('Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isConnected = _lgService.connectionStatus == ConnectionStatus.connected;
    final int maxScreens = (_lgService.screenCount > 0) ? _lgService.screenCount : 3;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Clean dark theme background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'KML Test Page',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isConnected
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isConnected ? Icons.check_circle : Icons.error_outline,
                      color: isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Connection Status: ${isConnected ? 'Connected' : 'Disconnected'}',
                      style: TextStyle(
                        color: isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3D KML Test Buttons
              const Text(
                '3D KML TEST BUTTONS',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              _buildActionButton(
                label: 'Send Cube',
                icon: Icons.view_in_ar,
                onPressed: () => _sendKmlAction('Send Cube', KmlTestGenerators.buildCubeKml()),
              ),
              const SizedBox(height: 10),

              _buildActionButton(
                label: 'Send Cylinder',
                icon: Icons.data_array,
                onPressed: () => _sendKmlAction('Send Cylinder', KmlTestGenerators.buildCylinderKml()),
              ),
              const SizedBox(height: 10),

              _buildActionButton(
                label: 'Send Pyramid',
                icon: Icons.change_history,
                onPressed: () => _sendKmlAction('Send Pyramid', KmlTestGenerators.buildPyramidKml()),
              ),
              const SizedBox(height: 10),

              _buildActionButton(
                label: _isOrbiting ? 'Stop Orbit Tour' : 'Send Orbit Tour',
                icon: _isOrbiting ? Icons.stop_circle : Icons.rotate_right,
                color: _isOrbiting ? const Color(0xFFEF4444) : null,
                onPressed: _toggleOrbitTour,
              ),
              const SizedBox(height: 10),

              _buildActionButton(
                label: 'Send KML Balloon',
                icon: Icons.chat_bubble_outline,
                onPressed: () => _sendKmlAction('Send KML Balloon', KmlTestGenerators.buildTestBalloonKml(), isBalloon: true),
              ),
              const SizedBox(height: 10),

              _buildActionButton(
                label: 'Clear KML',
                icon: Icons.clear_all,
                color: const Color(0xFFE2E8F0),
                textColor: const Color(0xFF0F172A),
                onPressed: _clearKml,
              ),
              const SizedBox(height: 28),

              // Customize KML Option
              const Text(
                'CUSTOMIZE KML OPTION',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LG Screen Number: $_selectedScreen',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '(Total: $maxScreens screens)',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ],
                    ),
                    Slider(
                      value: _selectedScreen.toDouble().clamp(1.0, maxScreens.toDouble()),
                      min: 1,
                      max: maxScreens.toDouble(),
                      divisions: (maxScreens - 1) > 0 ? (maxScreens - 1) : 1,
                      label: 'Screen $_selectedScreen',
                      activeColor: const Color(0xFF38BDF8),
                      onChanged: (val) {
                        setState(() {
                          _selectedScreen = val.round();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customKmlController,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Paste custom XML / KML here...',
                        hintStyle: const TextStyle(color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.send),
                      label: Text(
                        'Send Custom KML to Screen $_selectedScreen',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _sendCustomKml,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Debug Output Card
              const Text(
                'DEBUG OUTPUT',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: _lastLog == null
                    ? const Text(
                        'No actions performed yet.',
                        style: TextStyle(color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Last KML Sent:',
                                style: TextStyle(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _lastLog!.timestamp,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _lastLog!.action,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                _lastLog!.success ? Icons.check_circle : Icons.error,
                                color: _lastLog!.success
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _lastLog!.success ? 'SUCCESS' : 'FAILED',
                                style: TextStyle(
                                  color: _lastLog!.success
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 28),

              // Bottom Actions: Reconnect & Clear Logs
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF475569)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Reconnect'),
                      onPressed: _reconnect,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFF7F1D1D)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Text('Clear Logs'),
                      onPressed: () {
                        setState(() {
                          _lastLog = null;
                        });
                        _showSnackbar('Logs cleared');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    Color? textColor,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? const Color(0xFF1E293B),
        foregroundColor: textColor ?? Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: color != null
                ? color.withValues(alpha: 0.5)
                : const Color(0xFF334155),
          ),
        ),
      ),
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
    );
  }
}
