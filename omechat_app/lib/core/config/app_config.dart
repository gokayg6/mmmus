/// App Configuration - Backend URLs and Environment Settings
class AppConfig {
  // ═══════════════════════════════════════════════════════════
  // BACKEND URL CONFIGURATION
  // ═══════════════════════════════════════════════════════════
  
  /// Production backend URL (Railway/Render)
  /// Deploy ettikten sonra buraya Railway veya Render URL'ini yazın
  static const String productionBackendUrl = 'https://your-backend.railway.app';
  
  /// Development backend URL (local network - accessible from all devices)
  /// IMPORTANT: Bu IP adresini bilgisayarınızın yerel IP adresiyle güncelleyin
  /// IP adresinizi öğrenmek için: ipconfig (Windows) veya ifconfig (Mac/Linux)
  /// Backend başlatıldığında gösterilen "AĞ" IP adresini buraya yazın
  static const String developmentBackendUrl = 'http://192.168.1.103:8001';
  
  /// Use production backend? (true = Railway/Render, false = local)
  static const bool useProductionBackend = false;
  
  // ═══════════════════════════════════════════════════════════
  // ENVIRONMENT
  // ═══════════════════════════════════════════════════════════
  
  static bool get isProduction => useProductionBackend;
  static bool get isDevelopment => !useProductionBackend;
  
  /// Get backend URL based on environment
  static String get backendUrl {
    return useProductionBackend ? productionBackendUrl : developmentBackendUrl;
  }
  
  /// Get WebSocket URL
  static String get websocketUrl {
    final base = backendUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
    return '$base/ws';
  }
}

