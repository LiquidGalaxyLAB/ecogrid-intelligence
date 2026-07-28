import 'package:ecogrid_intelligence/core/utils/region_boundary_service.dart';
void main() async {
  final kml = await RegionBoundaryService.fetchBoundaryKml(
    regionName: 'Italy',
    displayName: 'Italy',
    minLat: 36.6, minLon: 6.6, maxLat: 47.1, maxLon: 18.5,
  );
  print(kml.substring(0, 500));
}
