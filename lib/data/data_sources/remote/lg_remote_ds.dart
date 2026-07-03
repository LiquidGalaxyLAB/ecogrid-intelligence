import 'package:flutter/foundation.dart';
import '../../../core/exception/invalid_response_exception.dart';
import '../../../core/utils/kml_utils.dart';
import '../../../service/ssh_service.dart';
import '../../../core/constants/lg_constants.dart';

class LGRemoteDataSource {
  final SSHService sshService;
  bool _isLogoVisible = true;
  int _screenCount = 3;
  void setScreenCount(int count) {
    _screenCount = count < 1 ? 1 : count;
    debugPrint('[EcoGrid] LG screen count set to $_screenCount');
  }

  LGRemoteDataSource({required this.sshService});
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

  Future<void> clearBalloonOnSlave(int slaveNumber) async {
    try {
      final emptyBalloonKml = KmlUtils.emptyBalloon().replaceAll("'", "'\\''");
      await sshService.execute(
        "echo '$emptyBalloonKml' > ${LGConstants.kmlPath}slave_$slaveNumber.kml",
      );
    } catch (e) {
      throw ConnectionException(
        message: 'Clear balloon on slave $slaveNumber failed: $e',
      );
    }
  }

  Future<void> playTour(String tourName) async {
    try {
      await sshService.execute(
        'echo "playtour=$tourName" > ${LGConstants.queryFile}',
      );
    } catch (e) {
      throw ConnectionException(message: 'Play tour failed: $e');
    }
  }

  Future<void> exitTour() async {
    try {
      await sshService.execute(
        'echo "exittour=true" > ${LGConstants.queryFile}',
      );
    } catch (e) {
      throw ConnectionException(message: 'Exit tour failed: $e');
    }
  }

  Future<void> sendOrbitKml(String orbitKml) async {
    try {
      final escaped = orbitKml.replaceAll("'", "'\\''");
      await sshService.execute("echo '$escaped' > /var/www/html/orbit.kml");
      await sshService.execute(
        "echo 'http://lg1:81/orbit.kml' >> /var/www/html/kmls.txt",
      );
    } catch (e) {
      throw ConnectionException(message: 'Send orbit KML failed: $e');
    }
  }

  Future<void> clearKml() async {
    try {
      await sshService.execute(
        'echo "exittour=true" > ${LGConstants.queryFile}',
      );
      final empty = KmlUtils.emptyKml().replaceAll("'", "'\\''");
      await sshService.execute("echo '$empty' > ${LGConstants.masterKmlFile}");
      await sshService.execute("echo '' > /var/www/html/kmls.txt");
      final emptyBalloonKml = KmlUtils.emptyBalloon().replaceAll("'", "'\\''");
      for (int i = 2; i <= _screenCount; i++) {
        try {
          await sshService.execute(
            "echo '$emptyBalloonKml' > ${LGConstants.kmlPath}slave_$i.kml",
          );
        } catch (_) {}
      }
      if (_isLogoVisible) {
        await showLogos();
      }
    } catch (e) {}
  }

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

  Future<void> reboot() async {
    for (int i = _screenCount; i >= 2; i--) {
      try {
        await sshService.execute(
          'sshpass -p ${sshService.password} ssh -t lg$i "echo ${sshService.password} | sudo -S reboot"',
        );
      } catch (_) {}
    }
    try {
      await sshService.execute('echo ${sshService.password} | sudo -S reboot');
    } catch (_) {}
  }

  Future<void> shutdown() async {
    for (int i = _screenCount; i >= 2; i--) {
      try {
        await sshService.execute(
          'sshpass -p ${sshService.password} ssh -t lg$i "echo ${sshService.password} | sudo -S poweroff"',
        );
      } catch (_) {}
    }
    try {
      await sshService.execute(
        'echo ${sshService.password} | sudo -S poweroff',
      );
    } catch (_) {}
  }

  Future<void> relaunch() async {
    final pw = sshService.password;
    final remoteCmd =
        'if [ -f /etc/init/lxdm.conf ]; then export SERVICE=lxdm; '
        'elif [ -f /etc/init/lightdm.conf ]; then export SERVICE=lightdm; '
        'else exit 1; fi; '
        'if [[ \$(service \$SERVICE status) =~ "stop" ]]; then '
        'echo $pw | sudo -S service \$SERVICE start; '
        'else '
        'echo $pw | sudo -S service \$SERVICE restart; '
        'fi';
    for (int i = _screenCount; i >= 2; i--) {
      try {
        await sshService.execute("sshpass -p $pw ssh -t lg$i '$remoteCmd'");
      } catch (_) {}
    }
    try {
      await sshService.execute(remoteCmd);
    } catch (_) {}
  }

  int _leftScreenIndex() {
    if (_screenCount == 1) return 1;
    return (_screenCount / 2).floor() + 2;
  }

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
