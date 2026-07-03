import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dartssh2/dartssh2.dart';
import '../core/exception/invalid_response_exception.dart';

class SSHService {
  SSHClient? _client;
  String _host = '';
  String _password = '';
  String _username = '';
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;
  String get password => _password;
  String get host => _host;
  String get username => _username;
  bool get isConnected => _client != null;
  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
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
      _client?.close();
      _client = null;
      _connectionController.add(false);
      throw ConnectionException(message: 'Command execution failed: $e');
    }
  }

  void disconnect() {
    if (_client != null) {
      try {
        _client!.close();
      } catch (_) {}
      _client = null;
      _connectionController.add(false);
      debugPrint('[EcoGrid] SSH disconnected');
    }
  }

  Future<void> uploadAsset(String assetPath, String remotePath) async {
    if (_client == null) {
      throw const ConnectionException(
        message: 'Not connected to Liquid Galaxy',
      );
    }
    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      final sftp = await _client!.sftp();
      final remoteFile = await sftp.open(
        remotePath,
        mode:
            SftpFileOpenMode.create |
            SftpFileOpenMode.write |
            SftpFileOpenMode.truncate,
      );
      await remoteFile.write(Stream.value(bytes).cast<Uint8List>());
      await remoteFile.close();
      debugPrint('[EcoGrid] Successfully uploaded $assetPath to $remotePath');
    } catch (e) {
      throw ConnectionException(
        message: 'SFTP upload failed for $assetPath: $e',
      );
    }
  }

  void dispose() {
    disconnect();
    _connectionController.close();
  }
}
