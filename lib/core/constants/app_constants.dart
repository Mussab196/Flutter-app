/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'VisionAid';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyAuthenticated = 'visionaid-authenticated';
  static const String keyDarkMode = 'visionaid-dark-mode';
  static const String keyOnboardingComplete = 'visionaid-onboarding';
  static const String keyAccessToken = 'visionaid-access-token';
  static const String keyRefreshToken = 'visionaid-refresh-token';
  static const String keyUserId = 'visionaid-user-id';
  static const String keyUserName = 'visionaid-user-name';
  static const String keyUserEmail = 'visionaid-user-email';

  // API Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Pagination
  static const int defaultPageSize = 20;
}
