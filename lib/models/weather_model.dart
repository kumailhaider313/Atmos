class Weather {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final String description;
  final int humidity;
  final double windSpeed;
  final List<ForecastItem> hourlyForecast;
  final List<ForecastItem> dailyForecast;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.hourlyForecast,
    required this.dailyForecast,
  });

  factory Weather.fromJson(Map<String, dynamic> currentJson, Map<String, dynamic> forecastJson) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is int) return val.toDouble();
      if (val is double) return val;
      return 0.0;
    }

    final List<ForecastItem> rawForecast = [];
    final list = forecastJson['list'];
    if (list is List) {
      for (var item in list) {
        if (item is Map<String, dynamic>) {
          rawForecast.add(ForecastItem.fromJson(item));
        }
      }
    }

    // Generate PURE HOURLY data (24 points, 1 per hour) via interpolation
    final List<ForecastItem> hourly = [];
    if (rawForecast.isNotEmpty) {
      for (int i = 0; i < rawForecast.length - 1; i++) {
        final start = rawForecast[i];
        final end = rawForecast[i + 1];
        final hoursDiff = end.time.difference(start.time).inHours;

        if (hoursDiff > 0) {
          final tempStep = (end.temperature - start.temperature) / hoursDiff;
          for (int h = 0; h < hoursDiff; h++) {
            if (hourly.length >= 24) break;
            hourly.add(ForecastItem(
              time: start.time.add(Duration(hours: h)),
              temperature: start.temperature + (tempStep * h),
              condition: start.condition,
            ));
          }
        }
        if (hourly.length >= 24) break;
      }
    }

    // Daily Forecast: 7 days
    final daily = <ForecastItem>[];
    final seenDates = <String>{};
    final now = DateTime.now();
    final todayString = "${now.year}-${now.month}-${now.day}";

    for (var item in rawForecast) {
      final dateString = "${item.time.year}-${item.time.month}-${item.time.day}";
      if (dateString != todayString && !seenDates.contains(dateString)) {
        seenDates.add(dateString);
        daily.add(item);
      }
      if (daily.length >= 7) break;
    }

    final main = currentJson['main'] ?? {};
    final weather = (currentJson['weather'] as List?)?.firstOrNull ?? {};
    final wind = currentJson['wind'] ?? {};

    return Weather(
      cityName: currentJson['name'] ?? 'Unknown',
      temperature: toDouble(main['temp']),
      mainCondition: weather['main'] ?? 'Clear',
      description: weather['description'] ?? '',
      humidity: main['humidity'] ?? 0,
      windSpeed: toDouble(wind['speed']) * 3.6,
      hourlyForecast: hourly,
      dailyForecast: daily,
    );
  }
}

class ForecastItem {
  final DateTime time;
  final double temperature;
  final String condition;

  ForecastItem({
    required this.time,
    required this.temperature,
    required this.condition,
  });

  factory ForecastItem.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is int) return val.toDouble();
      if (val is double) return val;
      return 0.0;
    }
    final main = json['main'] ?? {};
    final weather = (json['weather'] as List?)?.firstOrNull ?? {};
    return ForecastItem(
      time: DateTime.fromMillisecondsSinceEpoch((json['dt'] ?? 0) * 1000),
      temperature: toDouble(main['temp']),
      condition: weather['main'] ?? 'Clear',
    );
  }
}

extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
