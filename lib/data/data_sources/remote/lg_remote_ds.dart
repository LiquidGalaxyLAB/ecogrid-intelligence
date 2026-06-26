import '../../../core/exception/invalid_response_exception.dart';
import '../../../core/utils/kml_utils.dart';
import '../../../service/ssh_service.dart';
import '../../../core/constants/lg_constants.dart';

/// Remote data source for Liquid Galaxy SSH operations.
class LGRemoteDataSource {
  final SSHService sshService;

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

  /// Clear all KML from LG.
  Future<void> clearKml() async {
    try {
      await sshService.execute('echo "" > ${LGConstants.queryFile}');

      // Clear master KML and the sync file
      final empty = KmlUtils.emptyKml().replaceAll("'", "'\\''");
      await sshService.execute("echo '$empty' > ${LGConstants.masterKmlFile}");
      await sshService.execute("echo '' > /var/www/html/kmls.txt");

      // Clear all slave KML files and kill any old Chromium instances
      final emptyBalloonKml = KmlUtils.emptyBalloon().replaceAll(
        "'",
        "'\\''",
      );
      for (int i = 2; i <= LGConstants.screenCount; i++) {
        await sshService.execute(
          "echo '$emptyBalloonKml' > ${LGConstants.kmlPath}slave_$i.kml",
        );
        try {
          await sshService.execute(
            "sshpass -p ${sshService.password} ssh lg$i 'pkill chromium'",
          );
        } catch (_) {}
      }

      // Re-apply logos to ensure they persist through screen clears
      await showLogos();
    } catch (e) {
      throw ConnectionException(message: 'Clear KML failed: $e');
    }
  }

  /// Set up auto-refresh for slave screens (as done in mentor's code).
  Future<void> setRefresh() async {
    const search = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href>';
    const replace =
        '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>2<\\/refreshInterval>';
    final command =
        'echo ${sshService.password} | sudo -S sed -i "s/$search/$replace/" ~/earth/kml/slave/myplaces.kml';
    final clear =
        'echo ${sshService.password} | sudo -S sed -i "s/$replace/$search/" ~/earth/kml/slave/myplaces.kml';

    for (var i = 2; i <= LGConstants.screenCount; i++) {
      final clearCmd = clear.replaceAll('{{slave}}', i.toString());
      final cmd = command.replaceAll('{{slave}}', i.toString());
      try {
        await sshService.execute(
          'sshpass -p ${sshService.password} ssh -t lg$i \'$clearCmd\'',
        );
        await sshService.execute(
          'sshpass -p ${sshService.password} ssh -t lg$i \'$cmd\'',
        );
      } catch (_) {}
    }
    // Note: We don't reboot here to avoid sudden disconnects, but the user can use reboot button if needed.
  }

  /// Reboot the LG system.
  Future<void> reboot() async {
    try {
      for (int i = LGConstants.screenCount; i >= 1; i--) {
        final target = i == 1 ? 'lg' : 'lg$i';
        await sshService.execute(
          'sshpass -p ${sshService.password} ssh -t $target "echo ${sshService.password} | sudo -S reboot"',
        );
      }
    } catch (e) {
      throw ConnectionException(message: 'Reboot failed: $e');
    }
  }

  /// Shutdown the LG system.
  Future<void> shutdown() async {
    try {
      for (int i = LGConstants.screenCount; i >= 1; i--) {
        final target = i == 1 ? 'lg' : 'lg$i';
        await sshService.execute(
          'sshpass -p ${sshService.password} ssh -t $target "echo ${sshService.password} | sudo -S poweroff"',
        );
      }
    } catch (e) {
      throw ConnectionException(message: 'Shutdown failed: $e');
    }
  }

  /// Relaunch the Liquid Galaxy software (Earth).
  Future<void> relaunch() async {
    try {
      for (int i = LGConstants.screenCount; i >= 1; i--) {
        final target = i == 1 ? 'lg' : 'lg$i';
        final cmd = """RELAUNCH_CMD="\\
if [ -f /etc/init/lxdm.conf ]; then
  export SERVICE=lxdm
elif [ -f /etc/init/lightdm.conf ]; then
  export SERVICE=lightdm
else
  exit 1
fi
if  [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]]; then
  echo ${sshService.password} | sudo -S service \\\${SERVICE} start
else
  echo ${sshService.password} | sudo -S service \\\${SERVICE} restart
fi
" && sshpass -p ${sshService.password} ssh -x -t lg@$target "\\\$RELAUNCH_CMD\"""";
        
        await sshService.execute('"/home/lg/bin/lg-relaunch" > /home/lg/log.txt');
        await sshService.execute(cmd);
      }
    } catch (e) {
      throw ConnectionException(message: 'Relaunch failed: $e');
    }
  }

  /// Returns the leftmost slave screen index for a given screen count.
  /// Follows the standard LG formula used across all official LG apps.
  int _leftScreenIndex() {
    if (LGConstants.screenCount == 1) return 1;
    return (LGConstants.screenCount / 2).floor() + 2;
  }

  /// Display the EcoGrid + LG logos on the leftmost rig (554×500 px overlay).
  Future<void> showLogos() async {
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

