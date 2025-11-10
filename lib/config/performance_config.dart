class PerformanceConfig {
  // Prevent instantiation
  PerformanceConfig._();

  // ========== Cache Settings ==========
  
  /// Duration to cache database queries
  static const Duration databaseCacheDuration = Duration(minutes: 5);
  
  /// Duration to cache API responses
  static const Duration apiCacheDuration = Duration(minutes: 10);
  
  /// Maximum number of cached items
  static const int maxCacheSize = 100;

  // ========== Map Settings ==========
  
  /// Debounce duration for map events to reduce rebuilds
  static const Duration mapEventDebounce = Duration(milliseconds: 300);
  
  /// Distance threshold (km) to reload POIs
  static const double poiReloadDistanceKm = 2.0;
  
  /// Maximum POI search radius (km)
  static const double maxPoiRadiusKm = 3.0;
  
  /// POI limits based on zoom levels
  static final Map<double, int> poiLimitsByZoom = {
    5.0: 5,   // Very zoomed out: 5 POIs
    10.0: 10, // Mid zoom: 10 POIs
    15.0: 15, // Close zoom: 15 POIs
    20.0: 20, // Very close: 20 POIs
  };

  // ========== Network Settings ==========
  
  /// Connection timeout for HTTP requests
  static const Duration connectionTimeout = Duration(seconds: 15);
  
  /// Request timeout for HTTP requests
  static const Duration requestTimeout = Duration(seconds: 30);
  
  /// Number of retry attempts for failed requests
  static const int maxRetryAttempts = 3;
  
  /// Delay between retry attempts
  static const Duration retryDelay = Duration(seconds: 2);

  // ========== Location Settings ==========
  
  /// Timeout for getting current location
  static const Duration locationTimeout = Duration(seconds: 15);
  
  /// Minimum distance (meters) to trigger location update
  static const double minLocationUpdateDistance = 50.0;
  
  /// Minimum time between location updates
  static const Duration minLocationUpdateInterval = Duration(seconds: 10);

  // ========== UI Settings ==========
  
  /// Duration for animations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  
  /// Duration to show SnackBars
  static const Duration snackBarDuration = Duration(seconds: 2);
  
  /// Number of items to load per page in lists
  static const int itemsPerPage = 20;
  
  /// Scroll threshold to trigger lazy loading
  static const double scrollLoadThreshold = 0.8; // 80% of scroll

  // ========== Memory Management ==========
  
  /// Maximum number of images to cache in memory
  static const int maxImageCacheSize = 50;
  
  /// Maximum image cache size in MB
  static const int maxImageCacheSizeMB = 100;
  
  /// Clear cache when memory usage exceeds this percentage
  static const double memoryClearThreshold = 0.85; // 85%

  // ========== Firebase Settings ==========
  
  /// Timeout for Firebase operations
  static const Duration firebaseTimeout = Duration(seconds: 10);
  
  /// Batch size for Firestore queries
  static const int firestoreBatchSize = 20;
  
  /// Listener reconnection delay
  static const Duration listenerReconnectDelay = Duration(seconds: 5);

  // ========== Video Call Settings ==========
  
  /// Maximum call duration before auto-disconnect (minutes)
  static const Duration maxCallDuration = Duration(minutes: 60);
  
  /// Call ringing timeout before auto-reject
  static const Duration callRingingTimeout = Duration(seconds: 30);
  
  /// Video quality settings
  static const int defaultVideoWidth = 640;
  static const int defaultVideoHeight = 480;
  static const int defaultVideoFrameRate = 15;
  static const int defaultVideoBitrate = 400; // kbps

  // ========== Debug Settings ==========
  
  /// Enable performance monitoring
  static const bool enablePerformanceMonitoring = true;
  
  /// Log slow operations (milliseconds)
  static const int slowOperationThreshold = 1000;
  
  /// Enable verbose logging
  static const bool enableVerboseLogging = false;

  // ========== Helper Methods ==========
  
  /// Get POI limit for a given zoom level
  static int getPoiLimitForZoom(double zoom) {
    if (zoom < 5.0) return poiLimitsByZoom[5.0]!;
    if (zoom < 10.0) return poiLimitsByZoom[10.0]!;
    if (zoom < 15.0) return poiLimitsByZoom[15.0]!;
    if (zoom < 20.0) return poiLimitsByZoom[20.0]!;
    return 9999; // No limit for very high zoom
  }
  
  /// Check if cache should be cleared based on time
  static bool shouldClearCache(DateTime lastClearTime, Duration cacheDuration) {
    return DateTime.now().difference(lastClearTime) > cacheDuration;
  }
  
  /// Calculate exponential backoff delay for retries
  static Duration getRetryDelay(int attemptNumber) {
    return retryDelay * (attemptNumber * 2); // Exponential backoff
  }
}
