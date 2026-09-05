import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'models/weather_model.dart';
import 'services/weather_service.dart';
import 'widgets/weather_display.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Atmos Weather',
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.trackpad, PointerDeviceKind.stylus},
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final _weatherService = WeatherService('70fe892adb54dc69a6b5e7d537990639');
  final _searchController = TextEditingController();
  
  Weather? _weather;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocationWeather();
  }

  Future<void> _fetchCurrentLocationWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      final position = await Geolocator.getCurrentPosition();
      final weather = await _weatherService.getWeatherByLocation(position.latitude, position.longitude);
      
      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getWeatherColor() {
    if (_weather == null) return Colors.blue.shade900;
    switch (_weather!.mainCondition.toLowerCase()) {
      case 'clear':
        return Colors.blue.shade800;
      case 'clouds':
        return Colors.blueGrey.shade800;
      case 'rain':
      case 'drizzle':
        return Colors.indigo.shade900;
      case 'thunderstorm':
        return Colors.deepPurple.shade900;
      default:
        return Colors.blue.shade900;
    }
  }

  void _fetchWeather([String? cityName]) async {
    final query = cityName ?? _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weather = await _weatherService.getWeather(query);
      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "City not found or connection error";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getWeatherColor();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: themeColor.withAlpha(204), // roughly 0.8 opacity
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 30,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.wb_sunny, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('ATMOS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient (Dynamic based on Weather)
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [themeColor, Colors.black],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: _buildSearchBar(),
                ),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              final suggestions = await _weatherService.getCitySuggestions(textEditingValue.text);
              return ['Current Location', ...suggestions];
            },
            onSelected: (String selection) {
              if (selection == 'Current Location') {
                _fetchCurrentLocationWeather();
              } else {
                _fetchWeather(selection);
              }
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search city...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.my_location, color: Colors.white70),
                        onPressed: _fetchCurrentLocationWeather,
                        tooltip: 'Use current location',
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Colors.white70),
                        onPressed: () => _fetchWeather(controller.text),
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
                onSubmitted: (value) {
                  onFieldSubmitted();
                  _fetchWeather(value);
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width - 40,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        final isLocation = option == 'Current Location';
                        return ListTile(
                          leading: isLocation ? const Icon(Icons.location_searching, color: Colors.blueAccent, size: 20) : null,
                          title: Text(
                            option,
                            style: TextStyle(
                              color: isLocation ? Colors.blueAccent : Colors.white,
                              fontWeight: isLocation ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.white70)),
      );
    }

    if (_weather == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using the logo if possible, otherwise an icon
            Image.asset(
              'assets/logo.png',
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.wb_sunny_outlined, size: 100, color: Colors.white24);
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Atmos',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Discover the sky anywhere.',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return WeatherDisplay(weather: _weather!);
  }
}
