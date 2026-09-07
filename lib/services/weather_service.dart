import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const baseUrl = 'https://api.openweathermap.org/data/2.5';
  final String apiKey;

  WeatherService(this.apiKey);

  Future<Weather> getWeather(String cityName) async {
    // Fetch Current Weather
    final currentResponse = await http.get(
      Uri.parse('$baseUrl/weather?q=$cityName&appid=$apiKey&units=metric'),
    );

    // Fetch Forecast
    final forecastResponse = await http.get(
      Uri.parse('$baseUrl/forecast?q=$cityName&appid=$apiKey&units=metric'),
    );

    if (currentResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
      final currentData = jsonDecode(currentResponse.body);
      final forecastData = jsonDecode(forecastResponse.body);
      return Weather.fromJson(currentData, forecastData);
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<Weather> getWeatherByLocation(double lat, double lon) async {
    // 1. Get accurate City Name via Reverse Geocoding
    String? accurateCityName;
    try {
      final geoResponse = await http.get(
        Uri.parse('https://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$apiKey'),
      );
      if (geoResponse.statusCode == 200) {
        final List geoData = jsonDecode(geoResponse.body);
        if (geoData.isNotEmpty) {
          accurateCityName = geoData[0]['name'];
        }
      }
    } catch (_) {
      // Fallback to weather API name if geocoding fails
    }

    // 2. Fetch Weather and Forecast
    final currentResponse = await http.get(
      Uri.parse('$baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric'),
    );

    final forecastResponse = await http.get(
      Uri.parse('$baseUrl/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric'),
    );

    if (currentResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
      final currentData = jsonDecode(currentResponse.body);
      final forecastData = jsonDecode(forecastResponse.body);
      
      // Override local area name with major city name if found
      if (accurateCityName != null) {
        // Clean up common API spelling/formatting issues
        String cleanedName = accurateCityName
            .replaceAll('Gujujranwala', 'Gujranwala')
            .replaceAll('City Tehsil', '')
            .trim();
        currentData['name'] = cleanedName;
      }
      
      return Weather.fromJson(currentData, forecastData);
    } else {
      throw Exception('Failed to load weather for your location');
    }
  }

  Future<List<String>> getCitySuggestions(String query) async {
    if (query.length < 2) return [];

    // Use the 'find' endpoint with 'type=like' for better fuzzy matching of misspellings
    final response = await http.get(
      Uri.parse('$baseUrl/find?q=$query&type=like&sort=population&cnt=10&appid=$apiKey'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List list = data['list'] ?? [];
      
      // Use a Set to avoid duplicate entries (same city name in different systems)
      final Set<String> suggestions = {};
      
      for (var item in list) {
        final name = item['name'];
        final sys = item['sys'] ?? {};
        final country = sys['country'] ?? '';
        
        if (name != null) {
          suggestions.add('$name, $country');
        }
      }
      
      return suggestions.toList();
    }
    
    // Fallback to direct geocoding if 'find' fails (some keys have different permissions)
    try {
      final geoResponse = await http.get(
        Uri.parse('https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$apiKey'),
      );
      if (geoResponse.statusCode == 200) {
        final List geoData = jsonDecode(geoResponse.body);
        return geoData.map((item) {
          final name = item['name'];
          final country = item['country'];
          return '$name, $country';
        }).toList();
      }
    } catch (_) {}

    return [];
  }
}
