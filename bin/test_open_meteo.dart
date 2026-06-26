import 'dart:convert';
import 'dart:io';

// ignore_for_file: avoid_print

void main() async {
  final url = Uri.parse(
    'https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41&past_days=30&daily=temperature_2m_mean,temperature_2m_max,precipitation_sum,wind_speed_10m_max&timezone=auto',
  );
  final request = await HttpClient().getUrl(url);
  final response = await request.close();
  final stringData = await response.transform(utf8.decoder).join();
  print(stringData);
}
