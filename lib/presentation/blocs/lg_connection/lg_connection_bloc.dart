import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ecogrid_intelligence/core/enums/connection_status.dart';
import 'package:ecogrid_intelligence/domain/entities/lg_settings.dart';
import 'package:ecogrid_intelligence/domain/repositories/lg_repository.dart';

// Events
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

// States
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

// BLoC
class LGConnectionBloc extends Bloc<LGConnectionEvent, LGConnectionState> {
  final LGRepository lgRepository;

  LGConnectionBloc({required this.lgRepository})
      : super(const LGConnectionState()) {
    on<LGSettingsLoadRequested>(_onLoadSettings);
    on<LGConnectRequested>(_onConnect);
    on<LGDisconnectRequested>(_onDisconnect);
    on<LGSettingsSaveRequested>(_onSaveSettings);
  }

  Future<void> _onLoadSettings(
    LGSettingsLoadRequested event,
    Emitter<LGConnectionState> emit,
  ) async {
    final result = await lgRepository.loadSettings();
    result.fold(
      (_) => null,
      (settings) => emit(state.copyWith(settings: settings)),
    );
  }

  Future<void> _onConnect(
    LGConnectRequested event,
    Emitter<LGConnectionState> emit,
  ) async {
    emit(state.copyWith(status: ConnectionStatus.connecting));
    final result = await lgRepository.connect(event.settings);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ConnectionStatus.error,
        error: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: ConnectionStatus.connected,
        settings: event.settings,
      )),
    );
  }

  Future<void> _onDisconnect(
    LGDisconnectRequested event,
    Emitter<LGConnectionState> emit,
  ) async {
    await lgRepository.disconnect();
    emit(state.copyWith(status: ConnectionStatus.disconnected));
  }

  Future<void> _onSaveSettings(
    LGSettingsSaveRequested event,
    Emitter<LGConnectionState> emit,
  ) async {
    await lgRepository.saveSettings(event.settings);
    emit(state.copyWith(settings: event.settings));
  }
}
