import 'package:flutter/foundation.dart';
import '../../../core/exception/invalid_response_exception.dart';
import '../../../core/utils/kml_utils.dart';
import '../../../service/ssh_service.dart';
import '../../../core/constants/lg_constants.dart';

/// Handles all communication with the Liquid Galaxy rig.
///
/// Rules for writing KML to LG:
///   • Small KML (< ~4 KB): use `echo '...' > file` via SSH exec.
///     This is the standard LG pattern, fast, and reliable.
///   • Large KML (region boundaries, plant batches): use SFTP.
///     Shell argument length has a ~128 KB limit; SFTP has no limit.
///   • Query file (`/tmp/query.txt`): always use `echo` (tiny strings).
///   • `kmls.txt`: always use `echo` (one-line URL).
class LGRemoteDataSource {
  final SSHService sshService;
  bool _isLogoVisible = true;
  int _screenCount = 3;

  void setScreenCount(int count) {
    _screenCount = count < 1 ? 1 : count;
    debugPrint('[EcoGrid] LG screen count set to $_screenCount');
  }

  LGRemoteDataSource({required this.sshService});

  /// Initialize necessary directories on the master node.
  Future<void> initialize() async {
    try {
      final pw = sshService.password;
      await sshService.execute(
        'echo $pw | sudo -S mkdir -p ${LGConstants.kmlPath}',
      );
      await sshService.execute(
        'echo $pw | sudo -S chmod 777 ${LGConstants.kmlPath}',
      );
      await sshService.execute(
        'echo $pw | sudo -S touch /var/www/html/kmls.txt',
      );
      await sshService.execute(
        'echo $pw | sudo -S chmod 777 /var/www/html/kmls.txt',
      );
    } catch (e) {
      debugPrint('[EcoGrid] Initialization failed: $e');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Escape a KML string for safe use inside single-quoted `echo '...'`.
  /// Replaces every `'` with `'\''` (end quote, escaped quote, reopen quote).
  String _escapeForEcho(String kml) => kml.replaceAll("'", "'\\''");

  /// Write a small KML string to [remotePath] using `echo` via SSH exec.
  /// This is the standard Liquid Galaxy pattern — fast and reliable for
  /// content under ~4 KB.
  Future<void> _writeSmallKml(String remotePath, String kml) async {
    final escaped = _escapeForEcho(kml);
    await sshService.execute("echo '$escaped' > $remotePath");
  }

  // ─── Camera Control ───────────────────────────────────────────────────────

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

  // ─── Master KML ───────────────────────────────────────────────────────────

  Future<void> sendKmlToMaster(String kmlContent) async {
    try {
      final escaped = _escapeForEcho(kmlContent);
      final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final commands = [
        "echo '$escaped' > ${LGConstants.masterKmlFile}",
        "echo 'http://lg1:81/kml/kmls.kml?t=$ts' > /var/www/html/kmls.txt",
      ];
      await sshService.execute(commands.join(' ; '));
    } catch (e) {
      throw ConnectionException(message: 'Send KML to Master failed: $e');
    }
  }

  Future<void> clearMaster() async {
    try {
      final emptyKml = _escapeForEcho(KmlUtils.emptyKml());
      await sshService.execute(
        "echo '$emptyKml' > ${LGConstants.masterKmlFile}",
      );
      await sshService.execute("echo '' > /var/www/html/kmls.txt");
    } catch (e) {
      throw ConnectionException(message: 'Clear Master failed: $e');
    }
  }

  // ─── Slave KML ────────────────────────────────────────────────────────────

  Future<void> sendKmlToSlave(int slaveNumber, String kml) async {
    try {
      await _writeSmallKml(
          '${LGConstants.kmlPath}slave_$slaveNumber.kml', kml);
    } catch (e) {
      throw ConnectionException(
        message: 'Send KML to slave $slaveNumber failed: $e',
      );
    }
  }

  /// Show a balloon on a slave screen.
  /// Balloons are typically 2-8 KB — safe for echo.
  Future<void> showBalloonOnSlave(int slaveNumber, String balloonKml) async {
    try {
      await _writeSmallKml(
          '${LGConstants.kmlPath}slave_$slaveNumber.kml', balloonKml);
    } catch (e) {
      throw ConnectionException(
        message: 'Show balloon on slave $slaveNumber failed: $e',
      );
    }
  }

  Future<void> clearBalloonOnSlave(int slaveNumber) async {
    try {
      await _writeSmallKml(
          '${LGConstants.kmlPath}slave_$slaveNumber.kml',
          KmlUtils.emptyBalloon());
    } catch (e) {
      throw ConnectionException(
        message: 'Clear balloon on slave $slaveNumber failed: $e',
      );
    }
  }

  // ─── Tours ────────────────────────────────────────────────────────────────

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

  /// Send orbit tour KML. Uses echo (safe since orbit KML is only ~5-10KB).
  Future<void> sendOrbitKml(String orbitKml) async {
    try {
      final escaped = _escapeForEcho(orbitKml);
      final commands = [
        "echo '$escaped' > /var/www/html/orbit.kml",
        "echo 'http://lg1:81/orbit.kml' >> /var/www/html/kmls.txt",
      ];
      await sshService.execute(commands.join(' ; '));
    } catch (e) {
      throw ConnectionException(message: 'Send orbit KML failed: $e');
    }
  }

  // ─── Clear All ────────────────────────────────────────────────────────────

  /// Clear ALL KML from the rig. Uses echo for everything (small files only).
  /// No SFTP channels opened — avoids channel exhaustion entirely.
  Future<void> clearKml() async {
    try {
      final commands = <String>[
        'echo "exittour=true" > ${LGConstants.queryFile}',
        "echo '' > /var/www/html/kmls.txt",
        "echo '${_escapeForEcho(KmlUtils.emptyKml())}' > ${LGConstants.masterKmlFile}",
      ];
      final emptyBalloon = _escapeForEcho(KmlUtils.emptyBalloon());
      for (int i = 2; i <= _screenCount; i++) {
        commands.add("echo '$emptyBalloon' > ${LGConstants.kmlPath}slave_$i.kml");
      }
      if (_isLogoVisible) {
        final leftScreen = _leftScreenIndex();
        final kml = _escapeForEcho(KmlUtils.screenOverlayKml());
        commands.add("echo '$kml' > ${LGConstants.kmlPath}slave_$leftScreen.kml");
      }
      // Execute all commands in a single SSH channel to prevent exhaustion
      await sshService.execute(commands.join(' ; '));
    } catch (e) {
      debugPrint('[EcoGrid] clearKml failed: $e');
    }
  }

  // ─── Refresh Intervals ────────────────────────────────────────────────────

  Future<void> setRefreshIntervals() async {
    final pw = sshService.password;
    final commands = <String>[];
    const search = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href>';
    const replace = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>2<\\/refreshInterval>';
    for (var i = 2; i <= _screenCount; i++) {
      final s = search.replaceAll('{{slave}}', i.toString());
      final r = replace.replaceAll('{{slave}}', i.toString());
      commands.add('sshpass -p $pw ssh -o ConnectTimeout=2 -q lg$i \'echo $pw | sudo -S sed -i "s/$s/$r/" ~/earth/kml/slave/myplaces.kml\'');
    }
    try {
      await sshService.execute(commands.join(' ; '));
    } catch (e) {
      debugPrint('[EcoGrid] setRefreshIntervals failed: $e');
    }
  }

  Future<void> removeRefreshIntervals() async {
    final pw = sshService.password;
    final commands = <String>[];
    const search = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href>';
    const replace = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>2<\\/refreshInterval>';
    for (var i = 2; i <= _screenCount; i++) {
      final s = search.replaceAll('{{slave}}', i.toString());
      final r = replace.replaceAll('{{slave}}', i.toString());
      commands.add('sshpass -p $pw ssh -o ConnectTimeout=2 -q lg$i \'echo $pw | sudo -S sed -i "s/$r/$s/" ~/earth/kml/slave/myplaces.kml\'');
    }
    try {
      await sshService.execute(commands.join(' ; '));
    } catch (e) {
      debugPrint('[EcoGrid] removeRefreshIntervals failed: $e');
    }
  }

  // ─── System Control ───────────────────────────────────────────────────────

  Future<void> reboot() async {
    for (int i = _screenCount; i >= 2; i--) {
      try {
        await sshService.execute(
          'sshpass -p ${sshService.password} ssh -t lg$i '
          '"echo ${sshService.password} | sudo -S reboot"',
        );
      } catch (_) {}
    }
    try {
      await sshService.execute(
        'echo ${sshService.password} | sudo -S reboot',
      );
    } catch (_) {}
  }

  Future<void> shutdown() async {
    for (int i = _screenCount; i >= 2; i--) {
      try {
        await sshService.execute(
          'sshpass -p ${sshService.password} ssh -t lg$i '
          '"echo ${sshService.password} | sudo -S poweroff"',
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

  // ─── Logos ────────────────────────────────────────────────────────────────

  int _leftScreenIndex() {
    if (_screenCount == 1) return 1;
    return (_screenCount / 2).floor() + 2;
  }

  Future<void> showLogos() async {
    _isLogoVisible = true;
    try {
      final leftScreen = _leftScreenIndex();
      final kml = _escapeForEcho(KmlUtils.screenOverlayKml());
      await sshService.execute(
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
      final emptyKml = _escapeForEcho(KmlUtils.emptyBalloon());
      await sshService.execute(
        "echo '$emptyKml' > ${LGConstants.kmlPath}slave_$leftScreen.kml",
      );
    } catch (e) {
      throw ConnectionException(message: 'Clear logos failed: $e');
    }
  }
}
