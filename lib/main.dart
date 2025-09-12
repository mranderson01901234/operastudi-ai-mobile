import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/opera_studio_config.dart';
import 'services/app_state.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase with your actual credentials
  await Supabase.initialize(
    url: OperaStudioConfig.supabaseUrl,
    anonKey: OperaStudioConfig.supabaseAnonKey,
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: OperaStudioConfig.appName,
        theme: ThemeData(
          useMaterial3: false,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Color(0xFF181A1B),
          primaryColor: Color(0xFF4A90E2),
          primarySwatch: MaterialColor(0xFF4A90E2, {
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
          colorScheme: ColorScheme.dark(
            primary: Color(0xFF4A90E2),
            secondary: Color(0xFF4A90E2),
            surface: Color(0xFF23272A),
            background: Color(0xFF181A1B),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.white,
            onBackground: Colors.white,
            surfaceContainer: Color(0xFF181A1B),
            surfaceContainerHigh: Color(0xFF23272A),
            surfaceContainerHighest: Color(0xFF2A2A2A),
            surfaceContainerLow: Color(0xFF181A1B),
            surfaceContainerLowest: Color(0xFF181A1B),
            surfaceDim: Color(0xFF181A1B),
            surfaceBright: Color(0xFF23272A),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF23272A),
            foregroundColor: Colors.white,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFF23272A),
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
              borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
            ),
            labelStyle: TextStyle(color: Color(0xFFB0B0B0)),
            hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4A90E2),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        home: LoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
