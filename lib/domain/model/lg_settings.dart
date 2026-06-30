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
    this.screenCount = 3,
  });

  /// Default/empty settings.
  static const LGSettings empty = LGSettings(
    host: '',
    password: '',
    screenCount: 3,
  );

  bool get isConfigured => host.isNotEmpty && password.isNotEmpty;

  /// The rightmost screen number (for analytics panel).
  int get rightmostScreen {
    if (screenCount == 1) return 1;
    return (screenCount / 2).floor() + 1;
  }

  /// The leftmost screen number.
  /// Uses the standard LG formula (same as the official LG apps where _slaves == screenCount).
  int get leftmostScreen {
    if (screenCount == 1) return 1;
    return (screenCount / 2).floor() + 2;
  }

  @override
  List<Object?> get props => [host, port, username, password, screenCount];
}
