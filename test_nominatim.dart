import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'User-Agent': 'EcoGridIntelligence/1.0 (liquidgalaxy@ecogrid.app)',
      },
    ),
  );

  final queries = ['Italy', 'Kenya'];
  
  for (var query in queries) {
    final url = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&polygon_geojson=1&format=json&limit=1&polygon_threshold=0.01';
    try {
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final results = response.data as List<dynamic>;
        if (results.isNotEmpty) {
          final geojson = results.first['geojson'];
          print('$query: ${geojson['type']}');
        } else {
          print('$query: Empty results');
        }
      }
    } catch (e) {
      print('$query: Error: $e');
    }
  }
}
