import 'package:equatable/equatable.dart';

/// Domain entity representing climate data for a location.
class ClimateData extends Equatable {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  // Current conditions
  final double? temperature;
  final double? precipitation;
  final double? windSpeed;
  final double? humidity;

  // Anomaly intensities (normalized 0.0–1.0)
  final double tempAnomaly;
  final double waterAnomaly;
  final double windAnomaly;

  // Raw anomaly values
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
