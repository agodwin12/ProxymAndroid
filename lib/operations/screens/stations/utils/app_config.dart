class AppConfig {
  // API base URL
  static const String apiBaseUrl = 'http://10.0.2.2:5000/api';

  // Default search radius in meters
  static const double defaultSearchRadius = 5000.0;

  // Map settings
  static const double defaultZoom = 14.0;
  static const double closeZoom = 16.0;

  // Panel settings
  static const double minPanelHeight = 0.5; // 50% of screen height
  static const double maxPanelHeight = 0.85; // 85% of screen height

  // Animation durations
  static const Duration mapAnimationDuration = Duration(milliseconds: 500);
  static const Duration listAnimationDuration = Duration(milliseconds: 300);
}