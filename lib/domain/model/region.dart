import 'package:equatable/equatable.dart';

class Region extends Equatable {
  final String id;
  final String name;
  final String? displayName;
  final double centerLat;
  final double centerLon;
  final double minLat;
  final double minLon;
  final double maxLat;
  final double maxLon;
  final String? imageAsset;
  final double defaultZoom;
  final List<String>? countries;
  const Region({
    required this.id,
    required this.name,
    this.displayName,
    required this.centerLat,
    required this.centerLon,
    required this.minLat,
    required this.minLon,
    required this.maxLat,
    required this.maxLon,
    this.imageAsset,
    this.defaultZoom = 5.0,
    this.countries,
  });
  @override
  List<Object?> get props => [id, name];
  static const List<Region> quickRegions = [
    Region(
      id: 'india',
      name: 'India',
      displayName: 'India',
      centerLat: 20.5937,
      centerLon: 78.9629,
      minLat: 6.5546,
      minLon: 68.1113,
      maxLat: 35.6745,
      maxLon: 97.3956,
      imageAsset: 'assets/images/regions/dark/india.png',
      defaultZoom: 5.0,
      countries: ['India'],
    ),
    Region(
      id: 'europe',
      name: 'Europe',
      displayName: 'Europe',
      centerLat: 54.5260,
      centerLon: 15.2551,
      minLat: 34.0,
      minLon: -25.0,
      maxLat: 72.0,
      maxLon: 45.0,
      imageAsset: 'assets/images/regions/dark/europe.png',
      defaultZoom: 4.0,
    ),
    Region(
      id: 'usa',
      name: 'USA',
      displayName: 'USA',
      centerLat: 37.0902,
      centerLon: -95.7129,
      minLat: 24.396,
      minLon: -125.0,
      maxLat: 49.384,
      maxLon: -66.934,
      imageAsset: 'assets/images/regions/dark/usa.png',
      defaultZoom: 4.0,
      countries: ['United States of America', 'USA', 'United States'],
    ),
    Region(
      id: 'china',
      name: 'China',
      displayName: 'China',
      centerLat: 35.8617,
      centerLon: 104.1954,
      minLat: 18.0,
      minLon: 73.0,
      maxLat: 54.0,
      maxLon: 135.0,
      imageAsset: 'assets/images/regions/dark/china.png',
      defaultZoom: 4.5,
      countries: ['China'],
    ),
    Region(
      id: 'africa',
      name: 'Africa',
      displayName: 'Africa',
      centerLat: -8.7832,
      centerLon: 34.5085,
      minLat: -35.0,
      minLon: -18.0,
      maxLat: 37.0,
      maxLon: 52.0,
      imageAsset: 'assets/images/regions/dark/africa.png',
      defaultZoom: 3.5,
    ),
    Region(
      id: 'spain',
      name: 'Spain',
      displayName: 'Spain',
      centerLat: 40.4637,
      centerLon: -3.7492,
      minLat: 36.0,
      minLon: -9.4,
      maxLat: 43.8,
      maxLon: 3.3,
      imageAsset: 'assets/images/regions/dark/spain.png',
      defaultZoom: 2.0,
      countries: ['Spain'],
    ),
  ];
}
