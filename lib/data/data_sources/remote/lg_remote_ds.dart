import 'package:flutter/foundation.dart';
import '../../../core/exception/invalid_response_exception.dart';
import '../../../core/utils/kml_utils.dart';
import '../../../service/ssh_service.dart';
import '../../../core/constants/lg_constants.dart';

/// Remote data source for Liquid Galaxy SSH operations.
class LGRemoteDataSource {
  final SSHService sshService;
  
  bool _isLogoVisible = true;

  /// The number of screens in the connected LG rig.
  /// Set via [setScreenCount] at connection time from the user's saved settings.
  /// Defaults to 3 (most common rig size) until explicitly configured.
  int _screenCount = 3;

  /// Update the screen count to match the user's saved LG settings.
  /// Must be called by [LGService] after a successful connection.
  void setScreenCount(int count) {
    _screenCount = count < 1 ? 1 : count;
    debugPrint('[EcoGrid] LG screen count set to $_screenCount');
  }

  LGRemoteDataSource({required this.sshService});

  /// Send FlyTo command via query.txt.
  Future<void> flyTo(
    double lat,
    double lon,
    double altitude,
    double heading,
    double tilt,
    double range,
  ) async {
    try {
      final query = KmlUtils.queryFlyTo(
        lat: lat,
        lon: lon,
        altitude: altitude,
        heading: heading,
        tilt: tilt,
        range: range,
      );
      await sshService.execute('echo "$query" > ${LGConstants.queryFile}');
    } catch (e) {
      throw ConnectionException(message: 'FlyTo failed: $e');
    }
  }

  /// Send KML to master screen.
  Future<void> sendKmlToMaster(String kmlContent) async {
    try {
      final escapedKml = kmlContent.replaceAll("'", "'\\''");
      await sshService.execute(
        "echo '$escapedKml' > ${LGConstants.masterKmlFile}",
      );
      await sshService.execute(
        "echo 'http://lg1:81/kml/kmls.kml' > /var/www/html/kmls.txt",
      );
    } catch (e) {
      throw ConnectionException(message: 'Send KML to Master failed: $e');
    }
  }

  /// Clear master screen only.
  Future<void> clearMaster() async {
    try {
      final escapedKml = KmlUtils.emptyKml().replaceAll("'", "'\\''");
      await sshService.execute(
        "echo '$escapedKml' > ${LGConstants.masterKmlFile}",
      );
      await sshService.execute("echo '' > /var/www/html/kmls.txt");
    } catch (e) {
      throw ConnectionException(message: 'Clear Master failed: $e');
    }
  }

  /// Send KML to a specific slave screen.
  Future<void> sendKmlToSlave(int slaveNumber, String kml) async {
    try {
      final escapedKml = kml.replaceAll("'", "'\\''");
      await sshService.execute(
        "echo '$escapedKml' > ${LGConstants.kmlPath}slave_$slaveNumber.kml",
      );
    } catch (e) {
      throw ConnectionException(
        message: 'Send KML to slave $slaveNumber failed: $e',
      );
    }
  }

  /// Show a KML balloon overlay on a specific slave screen.
  ///
  /// Writes the KML (with BalloonStyle) to the slave's KML file.
  /// Google Earth on that slave picks it up and renders the balloon
  /// as a floating card — no Chromium needed.
  Future<void> showBalloonOnSlave(int slaveNumber, String balloonKml) async {
    try {
      final escapedKml = balloonKml.replaceAll("'", "'\\''");
      await sshService.execute(
        "echo '$escapedKml' > ${LGConstants.kmlPath}slave_$slaveNumber.kml",
      );
    } catch (e) {
      throw ConnectionException(
        message: 'Show balloon on slave $slaveNumber failed: $e',
      );
    }
  }

  /// Clear the balloon/KML from a specific slave screen.
  Future<void> clearBalloonOnSlave(int slaveNumber) async {
    try {
      final emptyBalloonKml = KmlUtils.emptyBalloon().replaceAll(
        "'",
        "'\\''",
      );
      await sshService.execute(
        "echo '$emptyBalloonKml' > ${LGConstants.kmlPath}slave_$slaveNumber.kml",
      );
    } catch (e) {
      throw ConnectionException(
        message: 'Clear balloon on slave $slaveNumber failed: $e',
      );
    }
  }

  /// Play a tour by name via query.txt.
  Future<void> playTour(String tourName) async {
    try {
      await sshService.execute('echo "playtour=$tourName" > ${LGConstants.queryFile}');
    } catch (e) {
      throw ConnectionException(message: 'Play tour failed: $e');
    }
  }

  /// Exit/stop any active tour via query.txt.
  Future<void> exitTour() async {
    try {
      await sshService.execute('echo "exittour=true" > ${LGConstants.queryFile}');
    } catch (e) {
      throw ConnectionException(message: 'Exit tour failed: $e');
    }
  }

  /// Write the orbit tour KML to a dedicated file and append it to kmls.txt.
  Future<void> sendOrbitKml(String orbitKml) async {
    try {
      final escaped = orbitKml.replaceAll("'", "'\\''");
      // Write orbit KML to a dedicated file
      await sshService.execute("echo '$escaped' > /var/www/html/orbit.kml");
      // Append it to kmls.txt so GE loads it alongside existing KMLs
      await sshService.execute(
        "echo 'http://lg1:81/orbit.kml' >> /var/www/html/kmls.txt",
      );
    } catch (e) {
      throw ConnectionException(message: 'Send orbit KML failed: $e');
    }
  }

  /// Clear all KML from LG.
  Future<void> clearKml() async {
    try {
      // Stop any active tour first
      await sshService.execute('echo "exittour=true" > ${LGConstants.queryFile}');

      // Clear master KML and the sync file
      final empty = KmlUtils.emptyKml().replaceAll("'", "'\\''");
      await sshService.execute("echo '$empty' > ${LGConstants.masterKmlFile}");
      await sshService.execute("echo '' > /var/www/html/kmls.txt");

      // Clear all slave KML files (no pkill — it's slow and causes lag)
      final emptyBalloonKml = KmlUtils.emptyBalloon().replaceAll("'", "'\\''");
      for (int i = 2; i <= _screenCount; i++) {
        try {
          await sshService.execute(
            "echo '$emptyBalloonKml' > ${LGConstants.kmlPath}slave_$i.kml",
          );
        } catch (_) {}
      }

      // Re-apply logos only if they haven't been explicitly hidden
      if (_isLogoVisible) {
        await showLogos();
      }
    } catch (e) {
      // Don't throw — clearKml is often called fire-and-forget
    }
  }

  /// Removes auto-refresh from slave screens to stop the KML from blinking.
  Future<void> removeRefreshIntervals() async {
    const search = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href>';
    const replace =
        '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>5<\\/refreshInterval>';
    final clear =
        'echo ${sshService.password} | sudo -S sed -i "s/$replace/$search/" ~/earth/kml/slave/myplaces.kml';

    for (var i = 2; i <= _screenCount; i++) {
      final clearCmd = clear.replaceAll('{{slave}}', i.toString());
      try {
        await sshService.execute(
          'sshpass -p ${sshService.password} ssh -t lg$i \'$clearCmd\'',
        );
      } catch (_) {}
    }
  }

  /// Reboot the LG system.
  Future<void> reboot() async {
    // Reboot slaves first so they get the command before master disconnects
    for (int i = _screenCount; i >= 2; i--) {
      try {
        await sshService.execute(
          'sshpass -p ${sshService.password} ssh -t lg$i "echo ${sshService.password} | sudo -S reboot"',
        );
      } catch (_) {} // Ignore — connection may drop during reboot
    }
    // Reboot master last (this will drop our connection)
    try {
      await sshService.execute(
        'echo ${sshService.password} | sudo -S reboot',
      );
    } catch (_) {}
  }

  /// Shutdown the LG system.
  Future<void> shutdown() async {
    // Shutdown slaves first
    for (int i = _screenCount; i >= 2; i--) {
      try {
        await sshService.execute(
          'sshpass -p ${sshService.password} ssh -t lg$i "echo ${sshService.password} | sudo -S poweroff"',
        );
      } catch (_) {}
    }
    // Shutdown master last
    try {
      await sshService.execute(
        'echo ${sshService.password} | sudo -S poweroff',
      );
    } catch (_) {}
  }

  /// Relaunch the Liquid Galaxy software (Earth).
  Future<void> relaunch() async {
    final pw = sshService.password;

    // The core command to restart the display manager (which fully restarts LG)
    final remoteCmd = 
      'if [ -f /etc/init/lxdm.conf ]; then export SERVICE=lxdm; '
      'elif [ -f /etc/init/lightdm.conf ]; then export SERVICE=lightdm; '
      'else exit 1; fi; '
      'if [[ \$(service \$SERVICE status) =~ "stop" ]]; then '
      'echo $pw | sudo -S service \$SERVICE start; '
      'else '
      'echo $pw | sudo -S service \$SERVICE restart; '
      'fi';

    // 1. Relaunch slaves first
    for (int i = _screenCount; i >= 2; i--) {
      try {
        await sshService.execute("sshpass -p $pw ssh -t lg$i '$remoteCmd'");
      } catch (_) {}
    }

    // 2. Relaunch master last (this will drop the SSH connection)
    try {
      await sshService.execute(remoteCmd);
    } catch (_) {}
  }

  /// Returns the leftmost slave screen index based on the connected rig's screen count.
  /// Follows the standard LG formula used across all official LG apps.
  int _leftScreenIndex() {
    if (_screenCount == 1) return 1;
    return (_screenCount / 2).floor() + 2;
  }

  /// Display the EcoGrid + LG logos on the leftmost rig (554×500 px overlay).
  Future<void> showLogos() async {
    _isLogoVisible = true;
    try {
      final leftScreen = _leftScreenIndex();
      final kml = KmlUtils.screenOverlayKml().replaceAll("'", "'\\''");
      await sshService.execute(
        "chmod 777 ${LGConstants.kmlPath}slave_$leftScreen.kml; "
        "echo '$kml' > ${LGConstants.kmlPath}slave_$leftScreen.kml",
      );
    } catch (e) {
      throw ConnectionException(message: 'Show logos failed: $e');
    }
  }

  /// Clear logos from the leftmost rig by writing an empty balloon KML.
  Future<void> clearLogos() async {
    _isLogoVisible = false;
    try {
      final leftScreen = _leftScreenIndex();
      final emptyKml = KmlUtils.emptyBalloon().replaceAll("'", "'\\''");
      await sshService.execute(
        "chmod 777 ${LGConstants.kmlPath}slave_$leftScreen.kml; "
        "echo '$emptyKml' > ${LGConstants.kmlPath}slave_$leftScreen.kml",
      );
    } catch (e) {
      throw ConnectionException(message: 'Clear logos failed: $e');
    }
  }
}

