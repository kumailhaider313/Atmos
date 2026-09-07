class Weather {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final String description;
  final int humidity;
  final double windSpeed;
  final int timezoneOffset; // Offset in seconds from UTC
  final List<ForecastItem> hourlyForecast;
  final List<ForecastItem> dailyForecast;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.timezoneOffset,
    required this.hourlyForecast,
    required this.dailyForecast,
  });

  // Helper to get the current local time of the city
  DateTime get localTime {
    final nowUtc = DateTime.now().toUtc();
    return nowUtc.add(Duration(seconds: timezoneOffset));
  }

  factory Weather.fromJson(Map<String, dynamic> currentJson, Map<String, dynamic> forecastJson) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is int) return val.toDouble();
      if (val is double) return val;
      return 0.0;
    }

    final int timezone = currentJson['timezone'] ?? 0;

    final List<ForecastItem> rawForecast = [];
    final list = forecastJson['list'];
    if (list is List) {
      for (var item in list) {
        if (item is Map<String, dynamic>) {
          rawForecast.add(ForecastItem.fromJson(item, timezone));
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
    
    // Get city's local today to skip correctly
    final cityNow = DateTime.now().toUtc().add(Duration(seconds: timezone));
    final todayString = "${cityNow.year}-${cityNow.month}-${cityNow.day}";

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
      timezoneOffset: timezone,
      hourlyForecast: hourly,
      dailyForecast: daily,
    );
  }
}

class ForecastItem {
  final DateTime time; // This is the LOCAL time of the city
  final double temperature;
  final String condition;

  ForecastItem({
    required this.time,
    required this.temperature,
    required this.condition,
  });

  factory ForecastItem.fromJson(Map<String, dynamic> json, int timezoneOffset) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is int) return val.toDouble();
      if (val is double) return val;
      return 0.0;
    }
    final main = json['main'] ?? {};
    final weather = (json['weather'] as List?)?.firstOrNull ?? {};
    
    // Convert UTC timestamp from API to City's Local Time
    final utcTime = DateTime.fromMillisecondsSinceEpoch((json['dt'] ?? 0) * 1000, isUtc: true);
    final localTime = utcTime.add(Duration(seconds: timezoneOffset));

    return ForecastItem(
      time: localTime,
      temperature: toDouble(main['temp']),
      condition: weather['main'] ?? 'Clear',
    );
  }
}

extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
