class OperaStudioConfig {
  // Production Configuration - Using your actual Supabase credentials
  static const String supabaseUrl = 'https://rnygtixdxbnflxflzpyr.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_7jmrzEA_j5vrXtP4OWhEBA_UjDD32z3';
  
  // API Configuration - Using your Opera Studio API
  static const String apiBaseUrl = 'https://api.operastudio.ai';
  static const String predictEndpoint = '/replicate-predict';
  static const String statusEndpoint = '/replicate-status';
  
  // Rate Limits
  static const int rateLimitPerMinute = 60;
  static const int rateLimitPerDay = 1000;
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  
  // Processing settings - Using your model configuration
  static const Map<String, dynamic> defaultEnhancementSettings = {
    'scale': '2x',
    'sharpen': 37,
    'denoise': 25,
    'faceRecovery': false,
    'model_name': 'mranderson01901234/my-app-scunetrepliactemodel',
    'model_version': 'df9a3c1d'
  };
  
  // App Configuration
  static const String appName = 'Opera Studio AI';
  static const String appVersion = '1.0.0';
  static const bool debugMode = false;
}
