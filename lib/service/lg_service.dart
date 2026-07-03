import 'package:flutter/material.dart';
import '../core/utils/globals.dart';
import '../core/enums/connection_status.dart';
import '../core/exception/invalid_response_exception.dart';
import '../core/exception/unhandled_exception.dart';
import '../core/resources/data_state.dart';
import '../core/utils/kml_utils.dart';
import '../data/data_sources/local/settings_local_ds.dart';
import '../data/data_sources/remote/lg_remote_ds.dart';
import '../core/enums/lg_display_mode.dart';
import '../domain/model/lg_settings.dart';

class LGService {
  final LGRemoteDataSource remoteDataSource;
  final SettingsLocalDataSource settingsDataSource;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _currentRegion;
  LGDisplayMode _currentMode = LGDisplayMode.none;
  LGService({required this.remoteDataSource, required this.settingsDataSource});
  ConnectionStatus get connectionStatus => _status;
  String? get currentRegion => _currentRegion;
  void setCurrentRegion(String? region) => _currentRegion = region;
  LGDisplayMode get currentMode => _currentMode;
  void setCurrentMode(LGDisplayMode mode) => _currentMode = mode;
  bool _checkConnection({bool silent = false}) {
    if (_status != ConnectionStatus.connected) {
      if (!silent) {
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
      return false;
    }
    return true;
  }

  Future<DataState<bool>> connect(LGSettings settings) async {
    try {
      _status = ConnectionStatus.connecting;
      final sshService = remoteDataSource.sshService;
      await sshService.connect(
        host: settings.host,
        port: settings.port,
        username: settings.username,
        password: settings.password,
      );
      try {
        await sshService.uploadAsset(
          'assets/images/logos.png',
          '/var/www/html/logos.png',
        );
      } catch (e) {
        debugPrint('[EcoGrid] Failed to upload logo: $e');
      }
      _status = ConnectionStatus.connected;
      remoteDataSource.setScreenCount(settings.screenCount);
      try {
        await remoteDataSource.showLogos();
      } catch (e) {
        debugPrint('[EcoGrid] Failed to show logo on connect: $e');
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
      remoteDataSource.sshService.disconnect();
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
    if (!_checkConnection())
      return DataFailure(UnhandledException(message: 'LG not connected'));
    try {
      await remoteDataSource.flyTo(lat, lon, altitude, heading, tilt, range);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> sendKmlToMaster(String kmlContent) async {
    if (!_checkConnection())
      return DataFailure(UnhandledException(message: 'LG not connected'));
    try {
      await remoteDataSource.sendKmlToMaster(kmlContent);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> clearMasterScreen() async {
    if (!_checkConnection(silent: true))
      return DataFailure(UnhandledException(message: 'LG not connected'));
    try {
      await remoteDataSource.clearMaster();
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> sendKmlToSlave(int slaveNumber, String kml) async {
    if (!_checkConnection())
      return DataFailure(UnhandledException(message: 'LG not connected'));
    try {
      await remoteDataSource.sendKmlToSlave(slaveNumber, kml);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> showBalloonOnSlave(
    int slaveNumber,
    String balloonKml,
  ) async {
    if (!_checkConnection())
      return DataFailure(UnhandledException(message: 'LG not connected'));
    try {
      await remoteDataSource.showBalloonOnSlave(slaveNumber, balloonKml);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> clearBalloonOnSlave(int slaveNumber) async {
    if (!_checkConnection(silent: true))
      return DataFailure(UnhandledException(message: 'LG not connected'));
    try {
      await remoteDataSource.clearBalloonOnSlave(slaveNumber);
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
    if (!_checkConnection())
      return DataFailure(UnhandledException(message: 'LG not connected'));
    try {
      final orbitKml = KmlUtils.orbitTour(
        lat: lat,
        lon: lon,
        range: range,
        tilt: tilt,
      );
      await remoteDataSource.sendOrbitKml(orbitKml);
      await Future.delayed(const Duration(seconds: 2));
      await remoteDataSource.playTour('Orbit');
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> stopOrbit() async {
    if (!_checkConnection(silent: true))
      return DataFailure(UnhandledException(message: 'LG not connected'));
    try {
      await remoteDataSource.exitTour();
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> clearKml() async {
    if (!_checkConnection(silent: true))
      return DataFailure(UnhandledException(message: 'LG not connected'));
    try {
      await remoteDataSource.clearKml();
      _currentRegion = null;
      _currentMode = LGDisplayMode.none;
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> reboot() async {
    if (!_checkConnection())
      return DataFailure(UnhandledException(message: 'LG not connected'));
    try {
      await remoteDataSource.reboot();
      _status = ConnectionStatus.disconnected;
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> shutdown() async {
    if (!_checkConnection())
      return DataFailure(UnhandledException(message: 'LG not connected'));
    try {
      await remoteDataSource.shutdown();
      _status = ConnectionStatus.disconnected;
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> relaunch() async {
    if (!_checkConnection())
      return DataFailure(UnhandledException(message: 'LG not connected'));
    try {
      await remoteDataSource.relaunch();
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> removeRefreshIntervals() async {
    try {
      await remoteDataSource.removeRefreshIntervals();
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(
        UnhandledException(message: 'Failed to remove refresh intervals: $e'),
      );
    }
  }

  Future<DataState<void>> showLogos() async {
    if (!_checkConnection())
      return DataFailure(UnhandledException(message: 'LG not connected'));
    try {
      await remoteDataSource.showLogos();
      return const DataSuccess(null);
    } catch (e) {
      return DataFailure(UnhandledException(message: e.toString()));
    }
  }

  Future<DataState<void>> clearLogos() async {
    if (!_checkConnection(silent: true))
      return DataFailure(UnhandledException(message: 'LG not connected'));
    try {
      await remoteDataSource.clearLogos();
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
}
