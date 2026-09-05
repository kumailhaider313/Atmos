# Atmos Weather

![Atmos Logo](assets/logo.png)

**Atmos** is a premium, cross-platform weather application built with Flutter. It provides real-time weather updates, detailed hourly/weekly forecasts, and professional data visualization with a modern glassmorphism design.

## ✨ Features

-   **Adaptive UI**: Optimized layouts for Mobile (Phone/Tablet) and Desktop (PC/Web).
-   **Glassmorphism Design**: Semi-transparent, blurred cards with dynamic background gradients that change based on current weather conditions.
-   **Professional Charts**: High-end temperature trend lines for both hourly and weekly forecasts using `fl_chart`.
-   **Pure Hourly Forecast**: Interpolated data providing a smooth, gap-free 24-hour weather trend.
-   **Smart Search**: Real-time city suggestions as you type, powered by the OpenWeatherMap Geocoding API.
-   **Location Intelligence**: 
    -   One-tap "Current Location" weather fetching.
    -   Reverse geocoding to ensure accurate city names (e.g., correcting "Babian" to "Gujranwala").
-   **Detailed Weather Metrics**: Humidity, Wind Speed (km/hr), Visibility, and "Feels Like" temperatures.
-   **Linked Scrolling**: Synchronized scrolling between charts and data boxes for an intuitive experience.

## 🚀 Getting Started

### Prerequisites

-   [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable channel)
-   An OpenWeatherMap API Key (Get a free key at [openweathermap.org](https://openweathermap.org/api))

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/your-username/atmos.git
    cd atmos
    ```

2.  **Fetch dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Configure API Key**:
    Open `lib/main.dart` and replace `YOUR_API_KEY_HERE` with your actual OpenWeatherMap API key:
    ```dart
    final _weatherService = WeatherService('your_actual_key_here');
    ```

4.  **Run the application**:
    ```bash
    # For Mobile
    flutter run
    
    # For Web/Desktop
    flutter run -d chrome  # or your preferred platform
    ```

## 🛠️ Built With

-   [Flutter](https://flutter.dev/) - UI Toolkit
-   [fl_chart](https://pub.dev/packages/fl_chart) - For professional data visualization.
-   [http](https://pub.dev/packages/http) - For network requests.
-   [geolocator](https://pub.dev/packages/geolocator) - For GPS location access.
-   [intl](https://pub.dev/packages/intl) - For date and time formatting.

## 📸 Screenshots

*(Add your screenshots here to showcase the glassmorphism and charts)*

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---
Developed with ❤️ by **Kumails Computer** using Flutter.
