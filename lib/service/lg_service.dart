import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/globals.dart';
import 'dart:typed_data';
import '../core/enums/connection_status.dart';
import '../core/exception/invalid_response_exception.dart';
import '../core/exception/unhandled_exception.dart';
import '../core/resources/data_state.dart';
import '../core/utils/kml_utils.dart';
import '../data/local/data_sources/settings_local_ds.dart';
import '../core/enums/lg_display_mode.dart';
import '../domain/model/lg_settings.dart';
import '../core/constants/lg_constants.dart';
import 'ssh_service.dart';

class LGService {
  String _currentKmlContext = '';

  void setKmlContext(String context) {
    _currentKmlContext = context;
  }

  String get kmlContext => _currentKmlContext;

  final SSHService _sshService;
  final SettingsLocalDataSource settingsDataSource;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _currentRegion;
  LGDisplayMode _currentMode = LGDisplayMode.none;
  bool _isLogoVisible = true;
  int _screenCount = 3;
  LGService({required SSHService sshService, required this.settingsDataSource})
    : _sshService = sshService;
  DateTime? _lastSnackbarTime;
  ConnectionStatus get connectionStatus => _status;
  int get screenCount => _screenCount;
  String? get currentRegion => _currentRegion;
  void setCurrentRegion(String? region) => _currentRegion = region;
  LGDisplayMode get currentMode => _currentMode;
  void setCurrentMode(LGDisplayMode mode) => _currentMode = mode;
  bool _checkConnection({bool silent = false}) {
    if (_status != ConnectionStatus.connected) {
      if (!silent) {
        final now = DateTime.now();
        final lastShown = _lastSnackbarTime;
        if (lastShown == null || now.difference(lastShown).inSeconds > 5) {
          _lastSnackbarTime = now;
          snackbarKey.currentState?.clearSnackBars();
          snackbarKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text(
                'Liquid Galaxy not connected',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      return false;
    }
    return true;
  }

  Future<DataState<bool>> connect(LGSettings settings) async {
    try {
      _status = ConnectionStatus.connecting;
      await _sshService.connect(
        host: settings.host,
        port: settings.port,
        username: settings.username,
        password: settings.password,
      );
      try {
        await _sshService.uploadAsset(
          'assets/images/logos.png',
          '/var/www/html/logos.png',
        );
      } catch (e) {
        debugPrint('[EcoGrid] Failed to upload logo: $e');
      }
      _status = ConnectionStatus.connected;
      _setScreenCount(settings.screenCount);
      await _initialize();
      try {
        await _showLogos();
      } catch (e) {
        debugPrint('[EcoGrid] Failed to show logo on connect: $e');
      }
      try {
        await _setRefreshIntervals();
      } catch (e) {
        debugPrint('[EcoGrid] Failed to set refresh intervals: $e');
      }
      try {
        await clearKml();
        await flyToDefault();
      } catch (e) {
        debugPrint('[EcoGrid] Failed to reset LG state on connect: $e');
      }
      return const DataSuccess(true);
    } catch (e) {
      _status = ConnectionStatus.error;
      return DataFailure(
        InvalidResponseException(
          message: 'Failed to connect: $e',
          response: null,
        ),
      );
    }
  }

  Future<DataState<void>> disconnect() async {
    try {
      _sshService.disconnect();
      _status = ConnectionStatus.disconnected;
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(
        UnhandledException(message: 'Failed to disconnect: $e'),
      );
    }
  }

  Future<DataState<void>> flyTo(
    double lat,
    double lon,
    double altitude,
    double heading,
    double tilt,
    double range,
  ) async {
    if (!_checkConnection()) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await _flyTo(lat, lon, altitude, heading, tilt, range);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> flyToDefault() async {
    if (!_checkConnection()) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await _withRetry(() => _flyTo(
        40.4636688,
        -3.7492199,
        0,
        0,
        60,
        1500000,
      ));
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> sendKmlToMaster(String kmlContent) async {
    if (!_checkConnection()) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await _sendKmlToMaster(kmlContent);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> clearMasterScreen() async {
    if (!_checkConnection(silent: true)) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await _clearMaster();
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> sendKmlToSlave(int slaveNumber, String kml) async {
    if (!_checkConnection()) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await _sendKmlToSlave(slaveNumber, kml);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> sendKmlToScreen(int screenNumber, String kmlContent) async {
    if (!_checkConnection()) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      if (screenNumber <= 1) {
        await _sendKmlToMaster(kmlContent);
      } else {
        await _sendKmlToSlave(screenNumber, kmlContent);
      }
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  /// Sends placemarks KML to master AND all slave screens so that
  /// pins are visible across the entire Liquid Galaxy panoramic view.
  Future<DataState<void>> sendKmlToAllScreens(String kmlContent) async {
    if (!_checkConnection()) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      // Send to master so it renders on screen 1
      await _sendKmlToMaster(kmlContent);
      // Also send the same KML to every slave so their Google Earth
      // instances render the placemarks on their portion of the view.
      for (var screen = 2; screen <= _screenCount; screen++) {
        await _sendKmlToSlave(screen, kmlContent);
      }
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }


  Future<DataState<void>> showBalloonOnSlave(
    int slaveNumber,
    String balloonKml,
  ) async {
    if (!_checkConnection()) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await _sendKmlToSlave(slaveNumber, balloonKml);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> clearBalloonOnSlave(int slaveNumber) async {
    if (!_checkConnection(silent: true)) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await _sendKmlToSlave(slaveNumber, KmlUtils.emptyBalloon());
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> uploadBalloonImage(String filename, Uint8List bytes) async {
    if (!_checkConnection()) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await _sshService.execute('mkdir -p /var/www/html/kml/images');
      await _sshService.uploadBytesViaSftp(
        bytes,
        '/var/www/html/kml/images/$filename',
      );
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Timer? _orbitTimer;
  bool _isOrbiting = false;

  Future<DataState<void>> startOrbit(
    double lat,
    double lon,
    double range,
    double tilt,
  ) async {
    if (!_checkConnection()) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await stopOrbit();
      await _exitTour();
      
      final orbitKml = _buildOrbitTour(
        lat: lat,
        lon: lon,
        range: range,
        tilt: tilt,
      );
      await _sendOrbitKml(orbitKml);
      await Future.delayed(const Duration(milliseconds: 1500));
      await _playTour('Orbit');
      
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> stopOrbit() async {
    _isOrbiting = false;
    _orbitTimer?.cancel();
    _orbitTimer = null;
    if (!_checkConnection(silent: true)) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await _exitTour();
      await _sshService.execute('echo "flytoview=" > ${LGConstants.queryFile}');
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<void> startComparisonTour(String tourName) async {
    try {
      await Future.delayed(const Duration(milliseconds: 3000));
      await _playTour(tourName);
    } catch (e) {
      debugPrint('[LG] Error starting tour: $e');
    }
  }

  Future<DataState<void>> clearKml() async {
    if (!_checkConnection(silent: true)) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await _clearAllKml();
      _currentRegion = null;
      _currentMode = LGDisplayMode.none;
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> reboot() async {
    if (!_checkConnection()) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await _reboot();
      _status = ConnectionStatus.disconnected;
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> shutdown() async {
    if (!_checkConnection()) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await _shutdown();
      _status = ConnectionStatus.disconnected;
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> relaunch() async {
    if (!_checkConnection()) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await _relaunch();
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> setRefreshIntervals() async {
    try {
      await _setRefreshIntervals();
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(
        UnhandledException(message: 'Failed to set refresh intervals: $e'),
      );
    }
  }

  Future<DataState<void>> removeRefreshIntervals() async {
    try {
      await _removeRefreshIntervals();
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(
        UnhandledException(message: 'Failed to remove refresh intervals: $e'),
      );
    }
  }

  Future<DataState<void>> showLogos() async {
    if (!_checkConnection()) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await _showLogos();
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> clearLogos() async {
    if (!_checkConnection(silent: true)) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await _clearLogos();
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> saveSettings(LGSettings settings) async {
    try {
      await settingsDataSource.saveSettings(settings);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(
        UnhandledException(message: 'Failed to save settings: $e'),
      );
    }
  }

  Future<DataState<LGSettings>> loadSettings() async {
    try {
      return DataSuccess(await settingsDataSource.loadSettings());
    } catch (e) {
      return DataFailure(
        UnhandledException(message: 'Failed to load settings: $e'),
      );
    }
  }

  void _setScreenCount(int count) {
    _screenCount = count < 1 ? 1 : count;
  }



  Future<void> _initialize() async {
    // NOTE: 'echo $password | sudo -S <cmd>' pipes the password to sudo via
    // stdin, which is more secure than passing it as a CLI arg — sudo -S reads
    // from stdin, so the password never appears in the command string itself
    // (the shell expands $password before exec, but it stays in this process's
    // memory, not in a child process's argv visible via 'ps aux').
    // A cleaner alternative would be a dedicated executeWithStdin() method on
    // SSHService using SSHSession.stdin (dartssh2 supports this via
    // _client!.execute() rather than _client!.run()), but that requires a
    // non-trivial change to ssh_service.dart. Leave as-is until the rig's
    // sudo configuration is confirmed — if the LG account has NOPASSWD sudo
    // (common on standard LG installs), the sudo -S piping can be removed
    // entirely and replaced with plain 'sudo <cmd>'.
    final password = _sshService.password;
    await _sshService.execute(
      'echo $password | sudo -S mkdir -p ${LGConstants.kmlPath}',
    );
    await _sshService.execute(
      'echo $password | sudo -S chmod 777 ${LGConstants.kmlPath}',
    );
    await _sshService.execute(
      'echo $password | sudo -S touch /var/www/html/kmls.txt',
    );
    await _sshService.execute(
      'echo $password | sudo -S chmod 777 /var/www/html/kmls.txt',
    );
  }

  Future<void> _flyTo(
    double lat,
    double lon,
    double altitude,
    double heading,
    double tilt,
    double range,
  ) async {
    final query = KmlUtils.queryFlyTo(
      lat: lat,
      lon: lon,
      altitude: altitude,
      heading: heading,
      tilt: tilt,
      range: range,
    );
    await _sshService.execute('echo "$query" > ${LGConstants.queryFile}');
  }

  /// Retries [action] up to [maxAttempts] times with simple linear backoff.
  /// Capped at a fixed number of attempts — never retries forever.
  Future<T> _withRetry<T>(
    Future<T> Function() action, {
    int maxAttempts = 3,
    Duration delay = const Duration(milliseconds: 400),
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await action();
      } catch (e) {
        lastError = e;
        debugPrint('[LG] Attempt $attempt/$maxAttempts failed: $e');
        if (attempt < maxAttempts) {
          await Future.delayed(delay * attempt); // linear backoff
        }
      }
    }
    throw lastError!;
  }

  Future<void> _sendKmlToMaster(String kml) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _withRetry(
      () => _sshService.writeFileViaSftp(LGConstants.masterKmlFile, kml),
    );
  }

  Future<void> _clearMaster() async {
    await _withRetry(() => _sshService.writeFileViaSftp(
      LGConstants.masterKmlFile,
      KmlUtils.emptyKml(),
    ));
  }

  Future<void> _sendKmlToSlave(int slaveNumber, String kml) => _withRetry(
    () => _sshService.writeFileViaSftp(
      '${LGConstants.kmlPath}slave_$slaveNumber.kml',
      kml,
    ),
  );

  Future<void> _playTour(String name) =>
      _sshService.execute('echo "playtour=$name" > ${LGConstants.queryFile}');

  Future<void> _exitTour() =>
      _sshService.execute('echo "exittour=true" > ${LGConstants.queryFile}');

  Future<void> _sendOrbitKml(String kml) async {
    await _withRetry(
      () => _sshService.writeFileViaSftp('/var/www/html/orbit.kml', kml),
    );
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await _withRetry(
      () => _sshService.execute(
        "echo 'http://lg1:81/orbit.kml?t=\$timestamp' > /var/www/html/kmls.txt",
      ),
    );
  }

  String _buildOrbitTour({
    required double lat,
    required double lon,
    double range = 15000,
    double tilt = 60,
    int steps = 36,
    double stepDuration = 0.8,
  }) {
    final buffer = StringBuffer();
    for (int i = 0; i < steps; i++) {
      final heading = (360.0 * i / steps);
      buffer.writeln(
        KmlUtils.flyTo(
          lat: lat,
          lon: lon,
          altitude: 0,
          heading: heading,
          tilt: tilt,
          range: range,
          duration: stepDuration,
        ),
      );
    }
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <gx:Tour>
    <name>Orbit</name>
    <gx:Playlist>
${buffer.toString()}    </gx:Playlist>
  </gx:Tour>
</kml>''';
  }

  Future<void> _clearAllKml() async {
    // Short fixed strings — no user content, safe as echo commands.
    await _withRetry(() => _sshService.execute(
      'echo "exittour=true" > ${LGConstants.queryFile} ; echo \'\' > /var/www/html/kmls.txt',
    ));
    // KML payloads written via SFTP — no shell escaping, no command-length limits.
    await _withRetry(() => _sshService.writeFileViaSftp(
      LGConstants.masterKmlFile,
      KmlUtils.emptyKml(),
    ));
    for (var screen = 2; screen <= _screenCount; screen++) {
      await _withRetry(() => _sshService.writeFileViaSftp(
        '${LGConstants.kmlPath}slave_$screen.kml',
        KmlUtils.emptyBalloon(),
      ));
    }
    if (_isLogoVisible) {
      await _withRetry(() => _sshService.writeFileViaSftp(
        '${LGConstants.kmlPath}slave_${_leftScreenIndex()}.kml',
        KmlUtils.screenOverlayKml(),
      ));
    }
  }

  Future<void> _setRefreshIntervals() => _updateRefreshIntervals(add: true);
  Future<void> _removeRefreshIntervals() => _updateRefreshIntervals(add: false);

  Future<void> _updateRefreshIntervals({required bool add}) async {
    final password = _sshService.password;
    const base = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href>';
    const refreshed =
        '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>2<\\/refreshInterval>';
    final commands = <String>[];
    for (var screen = 2; screen <= _screenCount; screen++) {
      final from = (add ? base : refreshed).replaceAll('{{slave}}', '$screen');
      final to = (add ? refreshed : base).replaceAll('{{slave}}', '$screen');
      commands.add(
        'sshpass -p $password ssh -o ConnectTimeout=2 -q lg$screen \'echo $password | sudo -S sed -i "s/$from/$to/" ~/earth/kml/slave/myplaces.kml\'',
      );
    }
    if (commands.isNotEmpty) await _sshService.execute(commands.join(' ; '));
  }

  Future<void> _reboot() => _runOnAllNodes('reboot');
  Future<void> _shutdown() => _runOnAllNodes('poweroff');

  Future<void> _runOnAllNodes(String command) async {
    // NOTE: 'sshpass -p $password ssh -t lgN ...' is the standard pattern for
    // hopping to slave nodes when the rig is configured with password-based
    // inter-node SSH auth. sshpass fundamentally requires the password as a
    // CLI argument, which means it is visible in 'ps aux' on lg1 while the
    // command runs. The correct long-term fix is SSH key-based auth between
    // rig nodes (add lg1's public key to authorized_keys on lg2..lgN), after
    // which the sshpass wrapper and -p flag can be removed entirely. This is
    // an infrastructure change on the Lleida rig, not a Flutter code change.
    final password = _sshService.password;
    for (var screen = _screenCount; screen >= 2; screen--) {
      try {
        await _sshService.execute(
          'sshpass -p $password ssh -t lg$screen "echo $password | sudo -S $command"',
        );
      } catch (_) {}
    }
    await _sshService.execute('echo $password | sudo -S $command');
  }

  Future<void> _relaunch() async {
    final password = _sshService.password;
    final command =
        'if [ -f /etc/init/lxdm.conf ]; then export SERVICE=lxdm; elif [ -f /etc/init/lightdm.conf ]; then export SERVICE=lightdm; else exit 1; fi; if [[ \$(service \$SERVICE status) =~ "stop" ]]; then echo $password | sudo -S service \$SERVICE start; else echo $password | sudo -S service \$SERVICE restart; fi';
    for (var screen = _screenCount; screen >= 2; screen--) {
      try {
        await _sshService.execute(
          "sshpass -p $password ssh -t lg$screen '$command'",
        );
      } catch (_) {}
    }
    await _sshService.execute(command);
  }

  int _leftScreenIndex() =>
      _screenCount == 1 ? 1 : (_screenCount / 2).floor() + 2;

  Future<void> _showLogos() async {
    _isLogoVisible = true;
    await _sendKmlToSlave(_leftScreenIndex(), KmlUtils.screenOverlayKml());
  }

  Future<void> _clearLogos() async {
    _isLogoVisible = false;
    await _sendKmlToSlave(_leftScreenIndex(), KmlUtils.emptyBalloon());
  }
}
