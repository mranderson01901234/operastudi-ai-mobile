import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'dev';
  
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'https://operastudio.io';
  static String get webApiEndpoint => dotenv.env['WEB_API_ENDPOINT'] ?? 'https://operastudio.io/.netlify/functions';
  
  static String get replicateApiToken => dotenv.env['REPLICATE_API_TOKEN'] ?? '';
  
  static bool get debugMode => dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
  static String get logLevel => dotenv.env['LOG_LEVEL'] ?? 'debug';
  
  static bool get isDevelopment => environment == 'dev';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'prod';
  
  static Future<void> load() async {
    // dotenv is already loaded in main.dart; no need to load again here.
  }
}
