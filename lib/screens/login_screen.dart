import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/credential_storage_service.dart';
import '../services/app_state.dart';
import 'landing_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _saveCredentials = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Load saved credentials and pre-populate the form
  Future<void> _loadSavedCredentials() async {
    try {
      // First try to get saved credentials
      final credentials = await AuthService.getSavedCredentials();
      
      if (credentials['email'] != null && credentials['password'] != null) {
        setState(() {
          _emailController.text = credentials['email']!;
          _passwordController.text = credentials['password']!;
          _saveCredentials = true;
        });
        print('✅ Loaded saved credentials for: ${credentials['email']}');
      } else {
        // If no saved credentials, try to get last login email for auto-fill
        final lastEmail = await AuthService.getLastLoginEmail();
        if (lastEmail != null) {
          setState(() {
            _emailController.text = lastEmail;
          });
          print('📧 Auto-filled last login email: $lastEmail');
        }
      }
    } catch (e) {
      print('⚠️ Failed to load saved credentials: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorWithSignInOption(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Account Already Exists'),
            content: const Text(
              'This email might already be registered. Would you like to sign in instead?'
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Focus on sign in by clearing the form and showing sign in message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your password to sign in'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                child: const Text('Sign In'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await AuthService.signInWithEmail(
        _emailController.text,
        _passwordController.text,
        saveCredentials: _saveCredentials,
      );

      if (success) {
        print('✅ Regular Sign In: Success, waiting for auth state change');
        
        // Wait for auth state to propagate, then navigate if needed
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted && ModalRoute.of(context)?.settings.name != '/landing') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LandingScreen()),
          );
        }
      } else {
        _showError("Sign in failed");
      }
    } catch (e) {
      _showError("Error: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegex.hasMatch(_emailController.text)) {
      _showError("Please enter a valid email address");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.signUpWithEmail(
        _emailController.text,
        _passwordController.text,
      );

      if (result['success'] == true) {
        print('✅ Regular Sign Up: Success, user created');
        
        // Save credentials if checkbox is checked
        if (_saveCredentials) {
          await CredentialStorageService.saveCredentials(
            _emailController.text.trim().toLowerCase(),
            _passwordController.text,
          );
          print('✅ Signup: Credentials saved for new user');
        } else {
          // Always save email for convenience
          await CredentialStorageService.updateLastLoginEmail(_emailController.text.trim().toLowerCase());
        }
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! You can now enhance images.'),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        // Wait for auth state and database to propagate
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Refresh app state for the new user
        if (mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          await appState.refreshUserData();
        }
        
        if (mounted && ModalRoute.of(context)?.settings.name != '/landing') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LandingScreen()),
          );
        }
      } else {
        final errorMessage = result['error'] ?? "Sign up failed";
        // If error suggests email already exists, offer sign in option
        if (errorMessage.toLowerCase().contains('already registered') || 
            errorMessage.toLowerCase().contains('already exists') ||
            errorMessage.toLowerCase().contains('invalid')) {
          _showErrorWithSignInOption(errorMessage);
        } else {
          _showError(errorMessage);
        }
      }
    } catch (e) {
      _showError("Error: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 48,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Opera Logo
                  const Text(
                    'OPERA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Studio AI',
                    style: TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Email Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF4A90E2)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF4A90E2)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Save Credentials Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _saveCredentials,
                        onChanged: (bool? value) {
                          setState(() {
                            _saveCredentials = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF4A90E2),
                        checkColor: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _saveCredentials = !_saveCredentials;
                            });
                          },
                          child: const Text(
                            'Save my login information for future sessions',
                            style: TextStyle(
                              color: Color(0xFFB0B0B0),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Sign In', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Sign Up', style: TextStyle(color: Color(0xFF4A90E2), fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Admin Quick Login (Development Only)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔧 Admin Quick Login',
                          style: TextStyle(
                            color: Color(0xFF4A90E2),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Development admin account with saved credentials',
                          style: TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _adminQuickLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A90E2).withOpacity(0.8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.admin_panel_settings, size: 18),
                            label: const Text('Login as Admin', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // ✅ REMOVED: Skip for Testing button - Authentication is now required
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Admin quick login for development
  Future<void> _adminQuickLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Admin credentials for development
      const adminEmail = 'admin@operastudio.io';
      const adminPassword = 'admin123456';

      print('🔧 Admin Quick Login: Attempting to sign in with admin credentials');
      
      // Try to sign in first (always save admin credentials for convenience)
      final signInSuccess = await AuthService.signInWithEmail(adminEmail, adminPassword, saveCredentials: true);
      
      if (signInSuccess) {
        print('✅ Admin Quick Login: Sign in successful');
        
        // Debug: Check authentication state immediately after sign in
        final user = AuthService.getCurrentUser();
        print('🔍 Admin Debug: User after sign in: ${user != null ? "User ID: ${user.id}, Email: ${user.email}" : "null"}');
        
        // Wait for auth state to propagate, then navigate if needed
        print('🔄 Admin Debug: Waiting for auth state change...');
        
        // Wait a moment for the auth state to update
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Force a check of the current auth state
        final currentUser = AuthService.getCurrentUser();
        print('🔍 Admin Debug: After delay, current user: ${currentUser != null ? "Valid" : "null"}');
        
        // The auth state should have updated by now, navigate manually as fallback
        if (mounted) {
          print('🔄 Admin Debug: Navigating to landing screen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LandingScreen()),
          );
        }
        return;
      }
      
      print('🔧 Admin Quick Login: Sign in failed, attempting to create admin account');
      
      // If sign in fails, try to create the admin account
      final signUpResult = await AuthService.signUpWithEmail(adminEmail, adminPassword);
      
      print('🔍 Admin Debug: SignUp result: ${signUpResult['success']}, Error: ${signUpResult['error'] ?? 'none'}');
      
      if (signUpResult['success']) {
        print('✅ Admin Quick Login: Admin account created successfully');
        
        // Add extra credits for admin account
        try {
          await AuthService.addCredits(100); // Give admin 100 credits
          print('✅ Admin Quick Login: Added 100 credits to admin account');
        } catch (e) {
          print('⚠️ Admin Quick Login: Failed to add extra credits: $e');
        }
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin account created with 100 credits! You can now save images.'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 4),
          ),
        );
        
        // Wait for auth state to propagate, then navigate if needed
        print('🔄 Admin Debug: Account created, waiting for auth state change...');
        
        // Wait a moment for the auth state to update
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check if we're still on the login screen (auth listener didn't trigger)
        if (mounted && ModalRoute.of(context)?.settings.name != '/landing') {
          print('🔄 Admin Debug: Auth listener didn\'t trigger, navigating manually');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LandingScreen()),
          );
        } else {
          print('✅ Admin Debug: Auth listener handled navigation automatically');
        }
      } else {
        throw Exception(signUpResult['error'] ?? 'Failed to create admin account');
      }
      
    } catch (e) {
      print('❌ Admin Quick Login failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Admin login failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
