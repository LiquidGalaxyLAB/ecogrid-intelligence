import 'package:equatable/equatable.dart';

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
  static const LGSettings empty = LGSettings(
    host: '',
    password: '',
    screenCount: 3,
  );
  bool get isConfigured => host.isNotEmpty && password.isNotEmpty;
  int get rightmostScreen {
    if (screenCount == 1) return 1;
    return (screenCount / 2).floor() + 1;
  }

  int get leftmostScreen {
    if (screenCount == 1) return 1;
    return (screenCount / 2).floor() + 2;
  }

  @override
  List<Object?> get props => [host, port, username, password, screenCount];
}
