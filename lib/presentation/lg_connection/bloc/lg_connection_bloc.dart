import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/enums/connection_status.dart';
import '../../../core/resources/data_state.dart';
import '../../../domain/model/lg_settings.dart';
import '../../../domain/usecases/lg/bloc/init_lg_bloc_usecase.dart';
import '../../../service/lg_service.dart';
import '../../../service/ssh_service.dart';

// ═══════════════════════════════════════════════════════
// EVENTS
// ═══════════════════════════════════════════════════════

abstract class LGConnectionEvent extends Equatable {
  const LGConnectionEvent();
  @override
  List<Object?> get props => [];
}

class LGConnectRequested extends LGConnectionEvent {
  final LGSettings settings;
  const LGConnectRequested(this.settings);
  @override
  List<Object?> get props => [settings];
}

class LGDisconnectRequested extends LGConnectionEvent {
  const LGDisconnectRequested();
}

class LGSettingsLoadRequested extends LGConnectionEvent {
  const LGSettingsLoadRequested();
}

class LGSettingsSaveRequested extends LGConnectionEvent {
  final LGSettings settings;
  const LGSettingsSaveRequested(this.settings);
  @override
  List<Object?> get props => [settings];
}

class LGRebootRequested extends LGConnectionEvent {
  const LGRebootRequested();
}

class LGPowerOffRequested extends LGConnectionEvent {
  const LGPowerOffRequested();
}

class LGRelaunchRequested extends LGConnectionEvent {
  const LGRelaunchRequested();
}

class LGClearKmlRequested extends LGConnectionEvent {
  const LGClearKmlRequested();
}

class LGShowLogosRequested extends LGConnectionEvent {
  const LGShowLogosRequested();
}

class LGClearLogosRequested extends LGConnectionEvent {
  const LGClearLogosRequested();
}

/// Internal event — fired by the SSHService connection stream.
class _LGConnectionStatusChanged extends LGConnectionEvent {
  final bool isConnected;
  const _LGConnectionStatusChanged(this.isConnected);
  @override
  List<Object?> get props => [isConnected];
}

// ═══════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════

class LGConnectionState extends Equatable {
  final ConnectionStatus status;
  final LGSettings settings;
  final String? error;

  const LGConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.settings = LGSettings.empty,
    this.error,
  });

  LGConnectionState copyWith({
    ConnectionStatus? status,
    LGSettings? settings,
    String? error,
  }) {
    return LGConnectionState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, settings, error];
}

// ═══════════════════════════════════════════════════════
// BLOC
// ═══════════════════════════════════════════════════════

/// Global singleton BLoC for managing Liquid Galaxy connection state.
///
/// Registered as `registerLazySingleton` in GetIt so all screens share
/// the same instance. Listens to [SSHService.connectionStream] to
/// reactively update the UI whenever the connection drops or recovers.
class LGConnectionBloc extends Bloc<LGConnectionEvent, LGConnectionState> {
  final LGService _lgService;
  final SSHService sshService;
  final InitLgBlocUseCase initLgBlocUseCase;
  StreamSubscription<bool>? _connectionSubscription;

  LGConnectionBloc({
    required this._lgService,
    required this.sshService,
    required this.initLgBlocUseCase,
  }) : super(const LGConnectionState()) {
    on<LGSettingsLoadRequested>(_onLoadSettings);
    on<LGConnectRequested>(_onConnect);
    on<LGDisconnectRequested>(_onDisconnect);
    on<LGSettingsSaveRequested>(_onSaveSettings);
    on<_LGConnectionStatusChanged>(_onConnectionStatusChanged);
    on<LGRebootRequested>(_onReboot);
    on<LGPowerOffRequested>(_onPowerOff);
    on<LGRelaunchRequested>(_onRelaunch);
    on<LGClearKmlRequested>(_onClearKml);
    on<LGShowLogosRequested>(_onShowLogos);
    on<LGClearLogosRequested>(_onClearLogos);

    // Subscribe to the SSH service's connection stream via the use case
    _connectionSubscription = initLgBlocUseCase().listen((isConnected) {
      add(_LGConnectionStatusChanged(isConnected));
    });

    // Sync initial state from SSH service
    if (sshService.isConnected) {
      add(const _LGConnectionStatusChanged(true));
    }
  }

  Future<void> _onLoadSettings(
    LGSettingsLoadRequested event,
    Emitter<LGConnectionState> emit,
  ) async {
    final result = await _lgService.loadSettings();
    if (result is DataSuccess<LGSettings>) {
      emit(state.copyWith(settings: result.data!));
    } else {
      debugPrint('[EcoGrid] Failed to load LG settings: ${result.exception}');
    }
  }

  Future<void> _onConnect(
    LGConnectRequested event,
    Emitter<LGConnectionState> emit,
  ) async {
    emit(state.copyWith(status: ConnectionStatus.connecting, error: null));

    final result = await _lgService.connect(event.settings);
    if (result is DataSuccess) {
      emit(
        state.copyWith(
          status: ConnectionStatus.connected,
          settings: event.settings,
          error: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: ConnectionStatus.error,
          error: result.exception?.toString(),
        ),
      );
    }
  }

  Future<void> _onDisconnect(
    LGDisconnectRequested event,
    Emitter<LGConnectionState> emit,
  ) async {
    await _lgService.disconnect();
    emit(state.copyWith(status: ConnectionStatus.disconnected, error: null));
  }

  Future<void> _onSaveSettings(
    LGSettingsSaveRequested event,
    Emitter<LGConnectionState> emit,
  ) async {
    await _lgService.saveSettings(event.settings);
    emit(state.copyWith(settings: event.settings));
  }

  void _onConnectionStatusChanged(
    _LGConnectionStatusChanged event,
    Emitter<LGConnectionState> emit,
  ) {
    if (event.isConnected) {
      emit(state.copyWith(status: ConnectionStatus.connected, error: null));
    } else {
      if (state.status == ConnectionStatus.connected ||
          state.status == ConnectionStatus.connecting) {
        emit(state.copyWith(status: ConnectionStatus.disconnected));
      }
    }
  }

  Future<void> _onReboot(
    LGRebootRequested event,
    Emitter<LGConnectionState> emit,
  ) async {
    await _lgService.reboot();
  }

  Future<void> _onPowerOff(
    LGPowerOffRequested event,
    Emitter<LGConnectionState> emit,
  ) async {
    await _lgService.shutdown();
  }

  Future<void> _onRelaunch(
    LGRelaunchRequested event,
    Emitter<LGConnectionState> emit,
  ) async {
    await _lgService.relaunch();
  }

  Future<void> _onClearKml(
    LGClearKmlRequested event,
    Emitter<LGConnectionState> emit,
  ) async {
    await _lgService.clearKml();
  }

  Future<void> _onShowLogos(
    LGShowLogosRequested event,
    Emitter<LGConnectionState> emit,
  ) async {
    await _lgService.showLogos();
  }

  Future<void> _onClearLogos(
    LGClearLogosRequested event,
    Emitter<LGConnectionState> emit,
  ) async {
    await _lgService.clearLogos();
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    return super.close();
  }
}
