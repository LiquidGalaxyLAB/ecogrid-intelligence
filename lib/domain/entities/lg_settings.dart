import 'package:equatable/equatable.dart';

/// Domain entity for LG SSH connection settings.
class LGSettings extends Equatable {
  final String host;
  final int port;
  final String username;
  final String password;
  final int screenCount;

  const LGSettings({
    required this.host,
    this.port = 22,
    this.username = 'lg',
    required this.password,
    this.screenCount = 5,
  });

  /// Default/empty settings.
  static const LGSettings empty = LGSettings(
    host: '',
    password: '',
  );

  bool get isConfigured => host.isNotEmpty && password.isNotEmpty;

  /// The rightmost screen number (for analytics panel).
  int get rightmostScreen => (screenCount / 2).floor() + 2;

  /// The leftmost screen number.
  int get leftmostScreen => (screenCount / 2).floor() + 1;

  @override
  List<Object?> get props => [host, port, username, password, screenCount];
}
