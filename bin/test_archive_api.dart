import 'dart:convert';
import 'dart:io';

// ignore_for_file: avoid_print

void main() async {
  try {
    // Let's try fetching daily data for 10 years to see if it's too slow, or if we can use monthly/yearly.
    // Open-Meteo doesn't have a "yearly" param, but let's test if we can fetch daily data from 2010 to 2024 fast enough.
    final url = Uri.parse(
      'https://archive-api.open-meteo.com/v1/archive?latitude=52.52&longitude=13.41&start_date=2014-01-01&end_date=2024-12-31&daily=temperature_2m_mean,precipitation_sum,wind_speed_10m_max&timezone=auto',
    );
    final sw = Stopwatch()..start();
    final request = await HttpClient().getUrl(url);
    final response = await request.close();
    final stringData = await response.transform(utf8.decoder).join();
    sw.stop();
    print(
      'Fetched in ${sw.elapsedMilliseconds}ms. Length: ${stringData.length}',
    );
  } catch (e) {
    print('Error: $e');
  }
}
