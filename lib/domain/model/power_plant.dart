import 'package:equatable/equatable.dart';
import '../../core/enums/plant_type.dart';

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
  final String searchKey;
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
    required this.searchKey,
  });
  @override
  List<Object?> get props => [id, name, latitude, longitude];
}
