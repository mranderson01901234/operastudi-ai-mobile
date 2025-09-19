class OperaStudioConfig {
  // Production Configuration - Using your actual Supabase credentials (from working web app)
  static const String supabaseUrl = 'https://rnygtixdxbnflxflzpyr.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_7jmrzEA_j5vrXtP4OWhEBA_UjDD32z3';
  
  // API Configuration - Fixed to match working web API
  static const String apiBaseUrl = 'https://operastudio.io';
  static const String predictEndpoint = '/.netlify/functions/replicate-predict';
  static const String statusEndpoint = '/.netlify/functions/replicate-status';
  
  // Rate Limits
  static const int rateLimitPerMinute = 60;
  static const int rateLimitPerDay = 1000;
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  
  // Processing settings - Fixed parameter formats to match netlify function expectations
  static const Map<String, dynamic> defaultEnhancementSettings = {
    'scale': 2,              // Changed from '2x' to integer 2
    'sharpen': 45,           // Updated value
    'denoise': 30,           // Updated value
    'face_recovery': false,  // Changed from 'faceRecovery' to 'face_recovery' (snake_case)
    // 'General' is the user-facing name for the default model
    'model_name': 'mranderson01901234/my-app-scunetrepliactemodel', // General
    'model_version': 'df9a3c1d'
  };
  
  // Model deployment IDs
  static const String generalModelDeploymentId = 'mranderson01901234/my-app-scunetrepliactemodel';
  static const String portraitModelDeploymentId = 'portrait-pro-v1'; // TODO: Replace with actual deployment ID if different
  static const String portraitModelVersion = 'v1.0'; // TODO: Replace with actual version if needed
  
  // App Configuration
  static const String appName = 'Opera Studio AI';
  static const String appVersion = '1.0.0';
  static const bool debugMode = true; // Enable debug mode for better logging
}
