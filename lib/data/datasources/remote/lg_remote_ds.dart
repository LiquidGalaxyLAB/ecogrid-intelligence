import 'package:ecogrid_intelligence/core/errors/exceptions.dart';
import 'package:ecogrid_intelligence/core/utils/kml_generator.dart';
import 'package:ecogrid_intelligence/service/ssh_service.dart';
import 'package:ecogrid_intelligence/config/app_config.dart';

/// Remote data source for Liquid Galaxy SSH operations.
class LGRemoteDataSource {
  final SSHService sshService;

  LGRemoteDataSource({required this.sshService});

  /// Send FlyTo command via query.txt.
  Future<void> flyTo(double lat, double lon, double altitude, double heading,
      double tilt, double range) async {
    try {
      final query = KMLGenerator.queryFlyTo(
        lat: lat,
        lon: lon,
        altitude: altitude,
        heading: heading,
        tilt: tilt,
        range: range,
      );
      await sshService.execute(
          'echo "$query" > ${AppConfig.lgQueryFile}');
    } catch (e) {
      throw ConnectionException(message: 'FlyTo failed: $e');
    }
  }

  /// Send KML to master screen.
  Future<void> sendKml(String kmlContent) async {
    try {
      // Write KML to file on LG
      final escapedKml = kmlContent.replaceAll("'", "'\\''");
      await sshService.execute(
          "echo '$escapedKml' > ${AppConfig.lgKmlPath}slave_2.kml");
    } catch (e) {
      throw ConnectionException(message: 'Send KML failed: $e');
    }
  }

  /// Send KML to a specific slave screen.
  Future<void> sendKmlToSlave(int slaveNumber, String kml) async {
    try {
      final escapedKml = kml.replaceAll("'", "'\\''");
      await sshService.execute(
          "echo '$escapedKml' > ${AppConfig.lgKmlPath}slave_$slaveNumber.kml");
    } catch (e) {
      throw ConnectionException(
          message: 'Send KML to slave $slaveNumber failed: $e');
    }
  }

  /// Clear all KML from LG.
  Future<void> clearKml() async {
    try {
      await sshService.execute(
          'echo "" > ${AppConfig.lgQueryFile}');
      // Clear all slave KML files
      for (int i = 2; i <= AppConfig.lgScreenCount; i++) {
        await sshService.execute(
            'echo "" > ${AppConfig.lgKmlPath}slave_$i.kml');
      }
    } catch (e) {
      throw ConnectionException(message: 'Clear KML failed: $e');
    }
  }

  /// Reboot the LG system.
  Future<void> reboot() async {
    try {
      for (int i = AppConfig.lgScreenCount; i >= 1; i--) {
        final target = i == 1 ? 'lg' : 'lg$i';
        await sshService.execute(
            'sshpass -p ${sshService.password} ssh -t $target "echo ${sshService.password} | sudo -S reboot"');
      }
    } catch (e) {
      throw ConnectionException(message: 'Reboot failed: $e');
    }
  }
}
