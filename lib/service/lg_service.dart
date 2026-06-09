import 'package:dartz/dartz.dart';
import 'package:ecogrid_intelligence/core/enums/connection_status.dart';
import 'package:ecogrid_intelligence/core/exception/failures.dart';
import 'package:ecogrid_intelligence/core/exception/exceptions.dart';
import 'package:ecogrid_intelligence/data/data_sources/local/settings_local_ds.dart';
import 'package:ecogrid_intelligence/data/data_sources/remote/lg_remote_ds.dart';
import 'package:ecogrid_intelligence/core/enums/lg_display_mode.dart';
import 'package:ecogrid_intelligence/domain/model/lg_settings.dart';

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

  Future<Either<Failure, bool>> connect(LGSettings settings) async {
    try {
      _status = ConnectionStatus.connecting;
      final sshService = remoteDataSource.sshService;
      await sshService.connect(
        host: settings.host,
        port: settings.port,
        username: settings.username,
        password: settings.password,
      );

      // Auto-configure the LG rig for slave KML refreshing, just like mentor's code.
      await remoteDataSource.setRefresh();

      _status = ConnectionStatus.connected;
      return const Right(true);
    } catch (e) {
      _status = ConnectionStatus.error;
      return Left(ConnectionFailure(message: 'Failed to connect: $e'));
    }
  }

  Future<Either<Failure, void>> disconnect() async {
    try {
      remoteDataSource.sshService.disconnect();
      _status = ConnectionStatus.disconnected;
      return const Right(null);
    } catch (e) {
      return Left(ConnectionFailure(message: 'Failed to disconnect: $e'));
    }
  }

  Future<Either<Failure, void>> flyTo(
    double lat,
    double lon,
    double altitude,
    double heading,
    double tilt,
    double range,
  ) async {
    try {
      await remoteDataSource.flyTo(lat, lon, altitude, heading, tilt, range);
      return const Right(null);
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(message: e.message));
    }
  }

  Future<Either<Failure, void>> sendKmlToMaster(String kmlContent) async {
    try {
      await remoteDataSource.sendKmlToMaster(kmlContent);
      return const Right(null);
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(message: e.message));
    }
  }

  Future<Either<Failure, void>> clearMasterScreen() async {
    try {
      await remoteDataSource.clearMaster();
      return const Right(null);
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(message: e.message));
    }
  }

  Future<Either<Failure, void>> sendKmlToSlave(
    int slaveNumber,
    String kml,
  ) async {
    try {
      await remoteDataSource.sendKmlToSlave(slaveNumber, kml);
      return const Right(null);
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(message: e.message));
    }
  }

  Future<Either<Failure, void>> showBalloonOnSlave(
    int slaveNumber,
    String balloonKml,
  ) async {
    try {
      await remoteDataSource.showBalloonOnSlave(slaveNumber, balloonKml);
      return const Right(null);
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(message: e.message));
    }
  }

  Future<Either<Failure, void>> clearBalloonOnSlave(int slaveNumber) async {
    try {
      await remoteDataSource.clearBalloonOnSlave(slaveNumber);
      return const Right(null);
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(message: e.message));
    }
  }

  Future<Either<Failure, void>> startOrbit(
    double lat,
    double lon,
    double range,
    double tilt,
  ) async {
    try {
      final orbitKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <gx:Tour><name>Orbit</name><gx:Playlist>''';
      final buffer = StringBuffer(orbitKml);
      for (int i = 0; i < 36; i++) {
        final heading = i * 10.0;
        buffer.writeln('''
    <gx:FlyTo>
      <gx:duration>1.2</gx:duration>
      <gx:flyToMode>smooth</gx:flyToMode>
      <LookAt>
        <longitude>$lon</longitude><latitude>$lat</latitude>
        <heading>$heading</heading><tilt>$tilt</tilt><range>$range</range>
        <altitudeMode>relativeToGround</altitudeMode>
      </LookAt>
    </gx:FlyTo>''');
      }
      buffer.writeln('</gx:Playlist></gx:Tour></kml>');

      await remoteDataSource.sendKmlToMaster(buffer.toString());
      return const Right(null);
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(message: e.message));
    }
  }

  Future<Either<Failure, void>> stopOrbit() async {
    return clearKml();
  }

  Future<Either<Failure, void>> clearKml() async {
    try {
      await remoteDataSource.clearKml();
      _currentRegion = null;
      _currentMode = LGDisplayMode.none;
      return const Right(null);
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(message: e.message));
    }
  }

  Future<Either<Failure, void>> reboot() async {
    try {
      await remoteDataSource.reboot();
      _status = ConnectionStatus.disconnected;
      return const Right(null);
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(message: e.message));
    }
  }

  Future<Either<Failure, void>> setRefresh() async {
    try {
      await remoteDataSource.setRefresh();
      return const Right(null);
    } catch (e) {
      return Left(ConnectionFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, void>> saveSettings(LGSettings settings) async {
    try {
      await settingsDataSource.saveSettings(settings);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save settings: $e'));
    }
  }

  Future<Either<Failure, LGSettings>> loadSettings() async {
    try {
      return Right(await settingsDataSource.loadSettings());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to load settings: $e'));
    }
  }
}
