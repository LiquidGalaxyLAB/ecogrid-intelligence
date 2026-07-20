import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dartssh2/dartssh2.dart';
import '../core/exception/invalid_response_exception.dart';

class SSHService {
  SSHClient? _client;
  SftpClient? _sftpClient;
  String _host = '';
  String _password = '';
  String _username = '';
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;
  String get password => _password;
  String get host => _host;
  String get username => _username;
  bool get isConnected => _client != null && !_client!.isClosed;

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
      // Timeout on a single command does NOT mean the connection is broken.
      // Log it and throw, but keep the SSH client alive.
      throw ConnectionException(
        message:
            'Command timed out: ${command.length > 80 ? '${command.substring(0, 80)}...' : command}',
      );
    } catch (e) {
      // Only treat as a connection-level failure if the client socket is gone.
      // Regular command errors (non-zero exit codes, stderr, etc.) should NOT
      // close the SSH session — that was killing the LG connection after every
      // KML write that produced any stderr output.
      final msg = e.toString();
      final isConnectionLost = msg.contains('Connection closed') ||
          msg.contains('Connection reset') ||
          msg.contains('Broken pipe') ||
          msg.contains('SocketException');
      if (isConnectionLost) {
        _client?.close();
        _client = null;
        _sftpClient = null;
        _connectionController.add(false);
        debugPrint('[EcoGrid] SSH connection lost: $msg');
      }
      throw ConnectionException(message: 'Command execution failed: $e');
    }
  }

  /// Writes [content] to [remotePath] via SFTP.
  /// Reliable for any file size — no shell argument-length limits.
  /// The SFTP session is always closed in the finally block to avoid
  /// leaking SSH channels (which would eventually kill the connection).
  Future<void> writeFileViaSftp(String remotePath, String content) async {
    if (_client == null) {
      throw const ConnectionException(
        message: 'Not connected to Liquid Galaxy',
      );
    }
    SftpClient? sftp;
    try {
      final bytes = Uint8List.fromList(utf8.encode(content));
      sftp = await _client!.sftp();
      final remoteFile = await sftp.open(
        remotePath,
        mode: SftpFileOpenMode.create |
            SftpFileOpenMode.write |
            SftpFileOpenMode.truncate,
      );
      await remoteFile.write(Stream.value(bytes).cast<Uint8List>());
      await remoteFile.close();
    } catch (e) {
      throw ConnectionException(
        message: 'SFTP write failed for $remotePath: $e',
      );
    } finally {
      // Always close the SFTP subsystem channel — not doing this leaks
      // SSH channels and eventually causes the LG to drop the connection.
      try { sftp?.close(); } catch (_) {}
    }
  }


  void disconnect() {
    if (_client != null) {
      try {
        _sftpClient?.close();
        _sftpClient = null;
        _client!.close();
      } catch (_) {}
      _client = null;
      _connectionController.add(false);
      debugPrint('[EcoGrid] SSH disconnected');
    }
  }

  Future<void> uploadAsset(String assetPath, String remotePath) async {
    if (!isConnected) {
      throw Exception('SSH is not connected');
    }

    try {
      final ByteData data = await rootBundle.load(assetPath);
      final buffer = data.buffer;
      final bytes = buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      _sftpClient ??= await _client!.sftp();
      final file = await _sftpClient!.open(
        remotePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
      );
      await file.write(Stream.value(bytes));
      await file.close();
      debugPrint('[EcoGrid] Successfully uploaded $assetPath to $remotePath');
    } catch (e) {
      debugPrint('[EcoGrid] Failed to upload asset: $e');
      throw ConnectionException(
        message: 'SFTP upload failed for $assetPath: $e',
      );
    }
  }

  /// Upload raw bytes to a remote path via SFTP.
  Future<void> uploadBytesViaSftp(Uint8List bytes, String remotePath) async {
    if (!isConnected) {
      throw Exception('SSH is not connected');
    }
    try {
      _sftpClient ??= await _client!.sftp();
      final file = await _sftpClient!.open(
        remotePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
      );
      await file.write(Stream.value(bytes));
      await file.close();
    } catch (e) {
      debugPrint('[EcoGrid] Failed to upload bytes via SFTP: $e');
      throw ConnectionException(
        message: 'SFTP upload failed for $remotePath: $e',
      );
    }
  }


  void dispose() {
    disconnect();
    _connectionController.close();
  }
}
