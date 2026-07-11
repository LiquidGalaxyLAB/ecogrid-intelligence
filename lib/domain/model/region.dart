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
  /// The search query to send to Nominatim to fetch this region's boundary.
  /// Falls back to [name] if null.
  final String? nominatimQuery;
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
    this.nominatimQuery,
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
      nominatimQuery: 'India',
    ),
    Region(
      id: 'italy',
      name: 'Italy',
      displayName: 'Italy',
      centerLat: 41.8719,
      centerLon: 12.5674,
      minLat: 36.6,
      minLon: 6.6,
      maxLat: 47.1,
      maxLon: 18.5,
      imageAsset: 'assets/images/regions/dark/italy.png',
      defaultZoom: 4.5,
      countries: ['Italy'],
      nominatimQuery: 'Italy',
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
      nominatimQuery: 'United States of America',
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
      nominatimQuery: 'China',
    ),
    Region(
      id: 'kenya',
      name: 'Kenya',
      displayName: 'Kenya',
      centerLat: 0.0236,
      centerLon: 37.9062,
      minLat: -4.7,
      minLon: 33.9,
      maxLat: 5.5,
      maxLon: 41.9,
      imageAsset: 'assets/images/regions/dark/kenya.png',
      defaultZoom: 5.0,
      countries: ['Kenya'],
      nominatimQuery: 'Kenya',
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
      nominatimQuery: 'Spain',
    ),
  ];
}
