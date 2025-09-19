import 'dart:async';
import 'dart:io';
import 'config/environment_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/opera_studio_config.dart';
import 'services/app_state.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/landing_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // For web builds, .env file might not be available, so we'll use defaults
  try {
    await dotenv.load();
    print('✅ .env loaded successfully');
  } catch (e) {
    print('⚠️ .env file not found, using environment defaults for web build: $e');
    // Initialize dotenv with default values for web builds
    dotenv.env.addAll({
      'ENVIRONMENT': 'prod',
      'DEBUG_MODE': 'false',
      'LOG_LEVEL': 'info',
      'API_BASE_URL': 'https://operastudio.io',
      'WEB_API_ENDPOINT': 'https://operastudio.io/.netlify/functions',
      'SUPABASE_URL': '',
      'SUPABASE_ANON_KEY': '',
      'REPLICATE_API_TOKEN': '',
    });
    print('✅ Default environment values loaded');
  }

  try {
    print('🚀 Starting Opera Studio AI...');
    
    // Load environment variables with timeout
    await EnvironmentConfig.load().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('⚠️ Environment loading timed out, using defaults');
      },
    );
    
    print('✅ Environment loaded successfully');
    
    // Initialize Supabase with timeout and error handling
    await Supabase.initialize(
      url: OperaStudioConfig.supabaseUrl,
      anonKey: OperaStudioConfig.supabaseAnonKey,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Supabase initialization timed out', const Duration(seconds: 10));
      },
    );
    
    print('✅ Supabase initialized successfully');
    print('🔗 Connected to: ${OperaStudioConfig.supabaseUrl}');
    
    runApp(const MyApp());
    
  } catch (e) {
    print('❌ Initialization failed: $e');
    // Run app with error state
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: OperaStudioConfig.appName,
        theme: ThemeData(
          useMaterial3: false,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1A1A1A),
          primaryColor: const Color(0xFF4A90E2),
          primarySwatch: const MaterialColor(0xFF4A90E2, {
            50: Color(0xFFE3F2FD),
            100: Color(0xFFBBDEFB),
            200: Color(0xFF90CAF9),
            300: Color(0xFF64B5F6),
            400: Color(0xFF42A5F5),
            500: Color(0xFF4A90E2),
            600: Color(0xFF1E88E5),
            700: Color(0xFF1976D2),
            800: Color(0xFF1565C0),
            900: Color(0xFF0D47A1),
          }),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4A90E2),
            secondary: Color(0xFF4A90E2),
            surface: Color(0xFF23272A),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.white,
            surfaceContainer: Color(0xFF1A1A1A),
            surfaceContainerHigh: Color(0xFF23272A),
            surfaceContainerHighest: Color(0xFF2A2A2A),
            surfaceContainerLow: Color(0xFF1A1A1A),
            surfaceContainerLowest: Color(0xFF1A1A1A),
            surfaceDim: Color(0xFF1A1A1A),
            surfaceBright: Color(0xFF23272A),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF23272A),
            foregroundColor: Colors.white,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF23272A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
            ),
            labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
            hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        home: const ImprovedAuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// ✅ IMPROVED: AuthWrapper with timeout and error handling
class ImprovedAuthWrapper extends StatefulWidget {
  const ImprovedAuthWrapper({super.key});

  @override
  State<ImprovedAuthWrapper> createState() => _ImprovedAuthWrapperState();
}

class _ImprovedAuthWrapperState extends State<ImprovedAuthWrapper> {
  Timer? _timeoutTimer;
  bool _hasTimedOut = false;

  @override
  void initState() {
    super.initState();
    
    // Attempt auto-login with saved credentials
    _attemptAutoLogin();
    
    // Set a timeout for authentication check - INCREASED for production
    _timeoutTimer = Timer(const Duration(seconds: 60), () {  // Increased from 15s to 60s
      if (mounted) {
        setState(() {
          _hasTimedOut = true;
        });
        print('⚠️ Authentication check timed out after 60s, showing login screen');
      }
    });
  }

  /// Attempt to automatically sign in with saved credentials
  Future<void> _attemptAutoLogin() async {
    try {
      print('🔄 Attempting auto-login with saved credentials...');
      final success = await AuthService.signInWithSavedCredentials();
      
      if (success) {
        print('✅ Auto-login successful');
        // The StreamBuilder will handle navigation when auth state changes
      } else {
        print('ℹ️ No saved credentials or auto-login failed');
      }
    } catch (e) {
      print('⚠️ Auto-login error: $e');
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
        // If timed out, show login screen - but check auth state first
    if (_hasTimedOut) {
      // CRITICAL FIX: Check if user is actually authenticated before forcing logout
      final currentUser = Supabase.instance.client.auth.currentUser;
      final currentSession = Supabase.instance.client.auth.currentSession;
      
      if (currentUser != null && currentSession != null) {
        print('⚠️ Timeout reached but user is authenticated - continuing with app');
        // Cancel timeout and continue with authenticated flow
        _timeoutTimer?.cancel();
        _hasTimedOut = false;
      } else {
        print('⚠️ CRITICAL: Timeout reached and no valid authentication - showing login screen');
        return const LoginScreen();
      }
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        print('🔄 AuthWrapper StreamBuilder: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, hasError=${snapshot.hasError}');
        
        // Cancel timeout if we get data
        if (snapshot.hasData) {
          _timeoutTimer?.cancel();
          final authEvent = snapshot.data?.event;
          print('🔄 AuthWrapper: Auth event received: $authEvent');
        }

        // Handle stream errors
        if (snapshot.hasError) {
          print('❌ Auth stream error: ${snapshot.error}');
          return const LoginScreen();
        }

        // Show loading while checking authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('⏳ AuthWrapper: Waiting for auth state...');
          return Scaffold(
            backgroundColor: const Color(0xFF1A1A1A),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF4A90E2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connecting to ${OperaStudioConfig.supabaseUrl}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Check if user is authenticated
        final session = snapshot.data?.session;
        final user = Supabase.instance.client.auth.currentUser;
        
        print('🔐 Auth state: session=${session != null}, user=${user != null}');
        if (user != null) {
          print('🔐 Auth state: User ID: ${user.id}, Email: ${user.email}');
        }
        
        // Route based on authentication state
        if (session != null && user != null) {
          print('✅ User authenticated, showing landing screen');
          return const LandingScreen();
        } else {
          print('❌ No authentication, showing login screen');
          return const LoginScreen();
        }
      },
    );
  }
}

// ✅ NEW: Error app for initialization failures
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Opera Studio AI - Error',
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Failed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
