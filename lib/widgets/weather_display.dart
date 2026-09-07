import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';

class WeatherDisplay extends StatefulWidget {
  final Weather weather;

  const WeatherDisplay({super.key, required this.weather});

  @override
  State<WeatherDisplay> createState() => _WeatherDisplayState();
}

class _WeatherDisplayState extends State<WeatherDisplay> {
  late ScrollController _hourlyChartController;
  late ScrollController _hourlyRowController;
  bool _isSyncingChart = false;
  bool _isSyncingRow = false;

  final double _hourlyItemWidth = 80.0;

  @override
  void initState() {
    super.initState();
    _hourlyChartController = ScrollController();
    _hourlyRowController = ScrollController();

    _hourlyChartController.addListener(() {
      if (!_isSyncingChart) {
        _isSyncingRow = true;
        if (_hourlyRowController.hasClients) {
          _hourlyRowController.jumpTo(_hourlyChartController.offset);
        }
        _isSyncingRow = false;
      }
    });

    _hourlyRowController.addListener(() {
      if (!_isSyncingRow) {
        _isSyncingChart = true;
        if (_hourlyChartController.hasClients) {
          _hourlyChartController.jumpTo(_hourlyRowController.offset);
        }
        _isSyncingChart = false;
      }
    });
  }

  @override
  void dispose() {
    _hourlyChartController.dispose();
    _hourlyRowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradientColors(widget.weather.mainCondition, widget.weather.localTime.hour),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildDesktopLayout(context);
          } else {
            return _buildMobileLayout(context);
          }
        },
      ),
    );
  }

  List<Color> _getGradientColors(String condition, int hour) {
    final isNight = hour < 6 || hour > 19;
    
    if (isNight) {
      return [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)];
    }

    switch (condition.toLowerCase()) {
      case 'clear':
        return [Colors.blue.shade800, Colors.lightBlue.shade400];
      case 'clouds':
        return [Colors.blueGrey.shade900, Colors.blueGrey.shade600];
      case 'rain':
      case 'drizzle':
        return [Colors.indigo.shade900, Colors.indigo.shade700];
      case 'thunderstorm':
        return [Colors.deepPurple.shade900, Colors.deepPurple.shade800];
      default:
        return [Colors.blue.shade900, Colors.blue.shade700];
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 30),
            _buildGlassCard(
              child: _buildMainWeatherInfo(context),
            ),
            const SizedBox(height: 20),
            _buildGlassCard(
              child: Column(
                children: [
                  const TabBar(
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: TextStyle(fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(text: 'Hourly'),
                      Tab(text: 'Weekly'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        Column(
                          children: [
                            SizedBox(height: 200, child: _buildTemperatureChart(context)),
                            const SizedBox(height: 20),
                            _buildForecastRow(context),
                          ],
                        ),
                        Column(
                          children: [
                            SizedBox(height: 180, child: _buildTemperatureChart(context, isWeekly: true)),
                            const SizedBox(height: 10),
                            Expanded(child: _buildForecastList(context, shrinkWrap: false)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailsGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(40.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isDesktop: true),
                  const SizedBox(height: 40),
                  _buildGlassCard(
                    child: _buildMainWeatherInfo(context, isDesktop: true),
                  ),
                  const SizedBox(height: 30),
                  _buildGlassCard(
                    child: Column(
                      children: [
                        const TabBar(
                          indicatorColor: Colors.white,
                          indicatorWeight: 3,
                          labelStyle: TextStyle(fontWeight: FontWeight.bold),
                          tabs: [
                            Tab(text: 'Hourly Forecast'),
                            Tab(text: 'Weekly Forecast'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 500,
                          child: TabBarView(
                            children: [
                              Column(
                                children: [
                                  Expanded(child: _buildTemperatureChart(context)),
                                  const SizedBox(height: 20),
                                  _buildForecastRow(context),
                                ],
                              ),
                              Column(
                                children: [
                                  SizedBox(height: 250, child: _buildTemperatureChart(context, isWeekly: true)),
                                  const SizedBox(height: 20),
                                  Expanded(child: _buildForecastList(context, shrinkWrap: false)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildGlassCard(
                    title: 'Details',
                    child: _buildDetailsGrid(context, isCompact: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({Widget? child, String? title}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20), // 0.08 * 255
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              child ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {bool isDesktop = false}) {
    final localTime = widget.weather.localTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.weather.cityName,
          style: TextStyle(
            color: Colors.white,
            fontSize: isDesktop ? 48 : 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
        Text(
          "${DateFormat('EEEE, d MMMM').format(localTime)}, ${DateFormat('h:mm a').format(localTime)}",
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildMainWeatherInfo(BuildContext context, {bool isDesktop = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.weather.temperature.round()}°',
              style: TextStyle(
                color: Colors.white,
                fontSize: isDesktop ? 100 : 72,
                fontWeight: FontWeight.w300,
              ),
            ),
            Text(
              widget.weather.mainCondition,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500),
            ),
            Text(
              widget.weather.description,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
        Icon(
          _getWeatherIcon(widget.weather.mainCondition, widget.weather.localTime.hour),
          color: Colors.white,
          size: isDesktop ? 120 : 80,
        ),
      ],
    );
  }

  Widget _buildTemperatureChart(BuildContext context, {bool isWeekly = false}) {
    final forecast = isWeekly ? widget.weather.dailyForecast : widget.weather.hourlyForecast;
    if (forecast.isEmpty) {
      return const Center(
        child: Text("No forecast data", style: TextStyle(color: Colors.white70)),
      );
    }

    final spots = forecast.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.temperature);
    }).toList();

    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    double padding = (maxY - minY) * 0.3;
    if (padding < 4) padding = 4;

    // Use a unique controller for Weekly, only sync Hourly
    final controller = isWeekly ? null : _hourlyChartController;

    return SingleChildScrollView(
      controller: controller,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        // For Hourly, we align with the 70px + 12px margin = 82px items.
        // Let's adjust both to use EXACTLY 80px per item.
        padding: EdgeInsets.symmetric(horizontal: isWeekly ? 40 : _hourlyItemWidth / 2),
        width: forecast.length * (isWeekly ? 150.0 : _hourlyItemWidth),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (forecast.length - 1).toDouble(),
            minY: minY - padding,
            maxY: maxY + padding,
            clipData: const FlClipData.none(),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: isWeekly ? 1 : 3,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= forecast.length) return const SizedBox();

                    String text;
                    if (isWeekly) {
                      text = DateFormat('E').format(forecast[index].time);
                    } else {
                      text = DateFormat('h a').format(forecast[index].time);
                    }

                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8,
                      child: Text(
                        text,
                        style: const TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.white,
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 3,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: Colors.blue.shade900,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForecastRow(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        controller: _hourlyRowController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.weather.hourlyForecast.length,
        itemBuilder: (context, index) {
          final item = widget.weather.hourlyForecast[index];
          return Container(
            width: _hourlyItemWidth - 12, // 80 - 12 margin = 68
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('h a').format(item.time), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Icon(_getWeatherIcon(item.condition, item.time.hour), color: Colors.white, size: 24),
                const SizedBox(height: 8),
                Text('${item.temperature.round()}°', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildForecastList(BuildContext context, {bool shrinkWrap = false}) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
      itemCount: widget.weather.dailyForecast.length,
      itemBuilder: (context, index) {
        final item = widget.weather.dailyForecast[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(_getWeatherIcon(item.condition, item.time.hour), color: Colors.white, size: 28),
          title: Text(
            DateFormat('EEEE').format(item.time),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          trailing: Text(
            '${item.temperature.round()}°',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        );
      },
    );
  }

  Widget _buildDetailsGrid(BuildContext context, {bool isCompact = false}) {
    final children = [
      _buildDetailItem(context, Icons.water_drop, 'Humidity', '${widget.weather.humidity}%'),
      _buildDetailItem(context, Icons.air, 'Wind', '${widget.weather.windSpeed.toStringAsFixed(1)} km/hr'),
      _buildDetailItem(context, Icons.compress, 'Visibility', widget.weather.mainCondition),
      _buildDetailItem(context, Icons.thermostat, 'Feels Like', '${widget.weather.temperature.round()}°'),
    ];

    if (isCompact) {
      return Column(children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList());
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: children,
    );
  }

  Widget _buildDetailItem(BuildContext context, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition, int hour) {
    final isNight = hour < 6 || hour > 19;
    switch (condition.toLowerCase()) {
      case 'clear':
        return isNight ? Icons.nightlight_round : Icons.wb_sunny;
      case 'clouds':
        return isNight ? Icons.cloud_queue : Icons.cloud;
      case 'rain':
        return Icons.umbrella;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.bolt;
      default:
        return isNight ? Icons.nightlight_round : Icons.wb_cloudy;
    }
  }
}
