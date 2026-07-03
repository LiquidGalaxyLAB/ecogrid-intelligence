import 'package:equatable/equatable.dart';

class ClimateData extends Equatable {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? temperature;
  final double? precipitation;
  final double? windSpeed;
  final double? humidity;
  final double tempAnomaly;
  final double waterAnomaly;
  final double windAnomaly;
  final double? tempDeviationC;
  final double? precipDeviationMm;
  final double? windDeviationKmh;
  const ClimateData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.temperature,
    this.precipitation,
    this.windSpeed,
    this.humidity,
    this.tempAnomaly = 0.0,
    this.waterAnomaly = 0.0,
    this.windAnomaly = 0.0,
    this.tempDeviationC,
    this.precipDeviationMm,
    this.windDeviationKmh,
  });
  @override
  List<Object?> get props => [latitude, longitude, timestamp];
}
