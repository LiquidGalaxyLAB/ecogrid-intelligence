import 'dart:async';
import 'package:dartssh2/dartssh2.dart';
import 'package:ecogrid_intelligence/core/errors/exceptions.dart';

/// SSH service for communicating with the Liquid Galaxy rig.
class SSHService {
  SSHClient? _client;
  String _password = '';

  String get password => _password;
  bool get isConnected => _client != null;

  /// Establish SSH connection to LG master.
  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    try {
      disconnect();
      _password = password;

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
    } catch (e) {
      _client = null;
      throw ConnectionException(message: 'SSH connection failed: $e');
    }
  }

  /// Execute a command on the LG master.
  Future<String> execute(String command) async {
    if (_client == null) {
      throw const ConnectionException(message: 'Not connected to LG');
    }

    try {
      final result = await _client!.run(command);
      return String.fromCharCodes(result);
    } catch (e) {
      throw ConnectionException(message: 'Command execution failed: $e');
    }
  }

  /// Disconnect from LG.
  void disconnect() {
    _client?.close();
    _client = null;
  }
}
