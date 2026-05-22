import 'package:dartz/dartz.dart';
import 'package:ecogrid_intelligence/core/enums/connection_status.dart';
import 'package:ecogrid_intelligence/core/errors/failures.dart';
import 'package:ecogrid_intelligence/core/errors/exceptions.dart';
import 'package:ecogrid_intelligence/data/datasources/local/settings_local_ds.dart';
import 'package:ecogrid_intelligence/data/datasources/remote/lg_remote_ds.dart';
import 'package:ecogrid_intelligence/domain/entities/lg_settings.dart';
import 'package:ecogrid_intelligence/domain/repositories/lg_repository.dart';


class LGRepositoryImpl implements LGRepository {
  final LGRemoteDataSource remoteDataSource;
  final SettingsLocalDataSource settingsDataSource;
  ConnectionStatus _status = ConnectionStatus.disconnected;

  LGRepositoryImpl({
    required this.remoteDataSource,
    required this.settingsDataSource,
  });

  @override
  ConnectionStatus get connectionStatus => _status;

  @override
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
      _status = ConnectionStatus.connected;
      return const Right(true);
    } catch (e) {
      _status = ConnectionStatus.error;
      return Left(ConnectionFailure(message: 'Failed to connect: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    try {
      remoteDataSource.sshService.disconnect();
      _status = ConnectionStatus.disconnected;
      return const Right(null);
    } catch (e) {
      return Left(ConnectionFailure(message: 'Failed to disconnect: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> flyTo(double lat, double lon, double altitude,
      double heading, double tilt, double range) async {
    try {
      await remoteDataSource.flyTo(lat, lon, altitude, heading, tilt, range);
      return const Right(null);
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> sendKml(String kmlContent) async {
    try {
      await remoteDataSource.sendKml(kmlContent);
      return const Right(null);
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> sendKmlToSlave(
      int slaveNumber, String kml) async {
    try {
      await remoteDataSource.sendKmlToSlave(slaveNumber, kml);
      return const Right(null);
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> startOrbit(
      double lat, double lon, double range, double tilt) async {
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

      await remoteDataSource.sendKml(buffer.toString());
      return const Right(null);
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> stopOrbit() async {
    return clearKml();
  }

  @override
  Future<Either<Failure, void>> clearKml() async {
    try {
      await remoteDataSource.clearKml();
      return const Right(null);
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> reboot() async {
    try {
      await remoteDataSource.reboot();
      _status = ConnectionStatus.disconnected;
      return const Right(null);
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> saveSettings(LGSettings settings) async {
    try {
      await settingsDataSource.saveSettings(settings);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save settings: $e'));
    }
  }

  @override
  Future<Either<Failure, LGSettings>> loadSettings() async {
    try {
      return Right(settingsDataSource.loadSettings());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to load settings: $e'));
    }
  }
}
