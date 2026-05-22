import 'package:dartz/dartz.dart';
import 'package:ecogrid_intelligence/core/enums/connection_status.dart';
import 'package:ecogrid_intelligence/core/errors/failures.dart';
import 'package:ecogrid_intelligence/domain/entities/lg_settings.dart';

/// Repository interface for Liquid Galaxy operations.
abstract class LGRepository {
  /// Connect to LG rig via SSH.
  Future<Either<Failure, bool>> connect(LGSettings settings);

  /// Disconnect from LG.
  Future<Either<Failure, void>> disconnect();

  /// Get current connection status.
  ConnectionStatus get connectionStatus;

  /// Send a FlyTo command to LG.
  Future<Either<Failure, void>> flyTo(
      double lat, double lon, double altitude, double heading, double tilt,
      double range);

  /// Send KML content to master screen.
  Future<Either<Failure, void>> sendKml(String kmlContent);

  /// Send KML content to a specific slave screen.
  Future<Either<Failure, void>> sendKmlToSlave(int slaveNumber, String kml);

  /// Start orbit around a point.
  Future<Either<Failure, void>> startOrbit(
      double lat, double lon, double range, double tilt);

  /// Stop current orbit.
  Future<Either<Failure, void>> stopOrbit();

  /// Clear all KML from LG.
  Future<Either<Failure, void>> clearKml();

  /// Reboot LG rig.
  Future<Either<Failure, void>> reboot();

  /// Save LG settings locally.
  Future<Either<Failure, void>> saveSettings(LGSettings settings);

  /// Load saved LG settings.
  Future<Either<Failure, LGSettings>> loadSettings();
}
