import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dartssh2/dartssh2.dart';
import '../core/exception/invalid_response_exception.dart';

/// SSH service for communicating with the Liquid Galaxy rig.
///
/// This is a singleton service (registered via GetIt) that maintains
/// a single persistent SSH connection. It exposes a [connectionStream]
/// so that any BLoC or widget can reactively monitor connection state
/// without tight coupling to this service's internals.
///
/// Design decisions:
/// - Connection state is broadcast via a StreamController
/// - Authentication is validated by running a test command after connect
/// - All public methods handle null-client gracefully
/// - Disconnect is idempotent (safe to call multiple times)
class SSHService {
  SSHClient? _client;
  String _host = '';
  String _password = '';
  String _username = '';

  /// Broadcasts connection state changes.
  /// `true` = connected, `false` = disconnected.
  final _connectionController = StreamController<bool>.broadcast();

  /// Reactive stream of connection status.
  Stream<bool> get connectionStream => _connectionController.stream;

  String get password => _password;
  String get host => _host;
  String get username => _username;
  bool get isConnected => _client != null;

  /// Establish and validate an SSH connection to the LG master.
  ///
  /// After creating the SSHClient, a test command (`echo "ecogrid_ok"`)
  /// is executed to confirm that:
  /// 1. The TCP socket connected successfully
  /// 2. The SSH handshake completed
  /// 3. The password was accepted
  ///
  /// If any of these fail, the client is closed and a
  /// [ConnectionException] is thrown.
  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    // Always clean up any existing connection first
    disconnect();

    try {
      _host = host;
      _password = password;
      _username = username;

      final socket = await SSHSocket.connect(
        host,
        port,
        timeout: const Duration(seconds: 15),
      );

      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      // ── Authentication validation ─────────────────
      // dartssh2 doesn't throw on bad passwords immediately.
      // We must run a test command to verify the session is usable.
      final testResult = await _client!
          .run('echo "ecogrid_ok"')
          .timeout(const Duration(seconds: 10));

      final output = String.fromCharCodes(testResult).trim();
      if (!output.contains('ecogrid_ok')) {
        throw const ConnectionException(
          message:
              'SSH authentication failed: test command returned unexpected output',
        );
      }

      _connectionController.add(true);
      debugPrint('[EcoGrid] SSH connected to $host:$port');
    } catch (e) {
      // Clean up on any failure
      _client?.close();
      _client = null;
      _connectionController.add(false);

      if (e is ConnectionException) rethrow;

      if (e is TimeoutException) {
        throw ConnectionException(
          message: 'SSH connection timed out: $host:$port',
        );
      }

      throw ConnectionException(
        message:
            'SSH connection failed: ${e.toString().replaceAll(password, '***')}',
      );
    }
  }

  /// Execute a command on the LG master.
  ///
  /// Returns the stdout output as a String.
  /// Throws [ConnectionException] if not connected or if execution fails.
  Future<String> execute(String command) async {
    if (_client == null) {
      throw const ConnectionException(
        message: 'Not connected to Liquid Galaxy',
      );
    }

    try {
      final result = await _client!
          .run(command)
          .timeout(const Duration(seconds: 30));
      return String.fromCharCodes(result);
    } on TimeoutException {
      throw ConnectionException(
        message:
            'Command timed out: ${command.length > 80 ? '${command.substring(0, 80)}...' : command}',
      );
    } catch (e) {
      // If the command fails, the connection may be dead
      _client?.close();
      _client = null;
      _connectionController.add(false);

      throw ConnectionException(message: 'Command execution failed: $e');
    }
  }

  /// Disconnect from the LG rig.
  ///
  /// Idempotent — safe to call even if already disconnected.
  void disconnect() {
    if (_client != null) {
      try {
        _client!.close();
      } catch (_) {
        // Ignore errors during cleanup
      }
      _client = null;
      _connectionController.add(false);
      debugPrint('[EcoGrid] SSH disconnected');
    }
  }

  /// Uploads a Flutter asset (like an image) directly to the LG rig via SFTP.
  Future<void> uploadAsset(String assetPath, String remotePath) async {
    if (_client == null) {
      throw const ConnectionException(message: 'Not connected to Liquid Galaxy');
    }
    
    try {
      // 1. Read the asset from the Flutter bundle
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      // 2. Open an SFTP session
      final sftp = await _client!.sftp();
      
      // 3. Open the remote file for writing
      final remoteFile = await sftp.open(
        remotePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
      );

      // 4. Write the bytes and close
      await remoteFile.write(
        Stream.value(bytes).cast<Uint8List>(),
      );
      await remoteFile.close();
      debugPrint('[EcoGrid] Successfully uploaded $assetPath to $remotePath');
      
    } catch (e) {
      throw ConnectionException(message: 'SFTP upload failed for $assetPath: $e');
    }
  }

  /// Clean up resources. Call when the app is shutting down.
  void dispose() {
    disconnect();
    _connectionController.close();
  }
}
