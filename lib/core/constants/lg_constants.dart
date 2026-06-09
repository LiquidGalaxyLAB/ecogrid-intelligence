/// LG and SSH related constants.
class LGConstants {
  LGConstants._();

  // ─── LG Defaults ────────────────────────────────────
  static const int defaultPort = 22;
  static const String defaultUsername = 'lg';
  static const String kmlPath = '/var/www/html/kml/';
  static const String queryFile = '/tmp/query.txt';
  static const String flyToFile = '/tmp/query.txt';
  static const int screenCount = 3;
  static const String masterKmlFile = '/var/www/html/kml/kmls.kml';
  static const String dashboardHtmlFile = '/var/www/html/dashboard.html';
  static const String dashboardUrl = 'http://lg1:81/dashboard.html';

  // ─── LG Orbit ───────────────────────────────────────
  static const double defaultOrbitRadius = 5000;
  static const int orbitSteps = 36;
  static const double defaultTilt = 60.0;
  static const double defaultRange = 10000.0;

  // ─── SSH Timeouts ────────────────────────────────────
  static const Duration sshTimeout = Duration(seconds: 15);
  static const Duration sshHeartbeatInterval = Duration(seconds: 30);
}
