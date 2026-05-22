import 'package:equatable/equatable.dart';
import 'package:ecogrid_intelligence/core/enums/plant_type.dart';

/// Domain entity representing a power generation facility.
class PowerPlant extends Equatable {
  final String id;
  final String name;
  final String country;
  final String? countryLong;
  final double latitude;
  final double longitude;
  final PlantType primaryFuel;
  final double? capacityMw;
  final int? commissioningYear;
  final String? owner;
  final String? source;
  final String? url;

  const PowerPlant({
    required this.id,
    required this.name,
    required this.country,
    this.countryLong,
    required this.latitude,
    required this.longitude,
    required this.primaryFuel,
    this.capacityMw,
    this.commissioningYear,
    this.owner,
    this.source,
    this.url,
  });

  @override
  List<Object?> get props => [id, name, latitude, longitude];
}
