import 'package:flutter/material.dart';
import '../core/utils/globals.dart';
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
      final orbitKml = KmlUtils.orbitTour(
        lat: lat,
        lon: lon,
        range: range,
        tilt: tilt,
      );
      await _sendOrbitKml(orbitKml);
      await Future.delayed(const Duration(seconds: 2));
      await _playTour('Orbit');
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> stopOrbit() async {
    if (!_checkConnection(silent: true)) {
      return DataFailure(UnhandledException(message: 'LG not connected'));
    }
    try {
      await _exitTour();
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
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

  String _escapeForEcho(String value) => value.replaceAll("'", "'\\\\''");

  Future<void> _initialize() async {
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

  Future<void> _sendKmlToMaster(String kml) async {
    final escaped = _escapeForEcho(kml);
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _sshService.execute(
      "echo '$escaped' > ${LGConstants.masterKmlFile} ; "
      "echo 'http://lg1:81/kml/kmls.kml?t=$timestamp' > /var/www/html/kmls.txt",
    );
  }

  Future<void> _clearMaster() async {
    await _sshService.execute(
      "echo '${_escapeForEcho(KmlUtils.emptyKml())}' > ${LGConstants.masterKmlFile} ; "
      "echo '' > /var/www/html/kmls.txt",
    );
  }

  Future<void> _sendKmlToSlave(
    int slaveNumber,
    String kml,
  ) => _sshService.execute(
    "echo '${_escapeForEcho(kml)}' > ${LGConstants.kmlPath}slave_$slaveNumber.kml",
  );

  Future<void> _playTour(String name) =>
      _sshService.execute('echo "playtour=$name" > ${LGConstants.queryFile}');

  Future<void> _exitTour() =>
      _sshService.execute('echo "exittour=true" > ${LGConstants.queryFile}');

  Future<void> _sendOrbitKml(String kml) => _sshService.execute(
    "echo '${_escapeForEcho(kml)}' > /var/www/html/orbit.kml ; "
    "echo 'http://lg1:81/orbit.kml' >> /var/www/html/kmls.txt",
  );

  Future<void> _clearAllKml() async {
    final commands = <String>[
      'echo "exittour=true" > ${LGConstants.queryFile}',
      "echo '' > /var/www/html/kmls.txt",
      "echo '${_escapeForEcho(KmlUtils.emptyKml())}' > ${LGConstants.masterKmlFile}",
    ];
    final emptyBalloon = _escapeForEcho(KmlUtils.emptyBalloon());
    for (var screen = 2; screen <= _screenCount; screen++) {
      commands.add(
        "echo '$emptyBalloon' > ${LGConstants.kmlPath}slave_$screen.kml",
      );
    }
    if (_isLogoVisible) {
      commands.add(
        "echo '${_escapeForEcho(KmlUtils.screenOverlayKml())}' > ${LGConstants.kmlPath}slave_${_leftScreenIndex()}.kml",
      );
    }
    await _sshService.execute(commands.join(' ; '));
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
