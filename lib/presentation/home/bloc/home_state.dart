import 'package:equatable/equatable.dart';
import 'package:ecogrid_intelligence/core/enums/connection_status.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final int totalPlants;
  final ConnectionStatus lgStatus;

  const HomeLoaded({
    required this.totalPlants,
    required this.lgStatus,
  });

  @override
  List<Object?> get props => [totalPlants, lgStatus];

  HomeLoaded copyWith({
    int? totalPlants,
    ConnectionStatus? lgStatus,
  }) {
    return HomeLoaded(
      totalPlants: totalPlants ?? this.totalPlants,
      lgStatus: lgStatus ?? this.lgStatus,
    );
  }
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}
