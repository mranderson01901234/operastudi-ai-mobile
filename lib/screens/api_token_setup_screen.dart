import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/replicate_service.dart';
import '../services/debug_service.dart';
import 'package:flutter/foundation.dart';

class ApiTokenSetupScreen extends StatefulWidget {
  const ApiTokenSetupScreen({super.key});

  @override
  State<ApiTokenSetupScreen> createState() => _ApiTokenSetupScreenState();
}

class _ApiTokenSetupScreenState extends State<ApiTokenSetupScreen> {
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final bool _isLoading = false;
  bool _isValidating = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingToken();
  }

  Future<void> _loadExistingToken() async {
    try {
      const storage = FlutterSecureStorage();
      final existingToken = await storage.read(key: 'replicate_api_token');
      if (existingToken != null && existingToken.isNotEmpty) {
        _tokenController.text = existingToken;
        if (kDebugMode) {
          DebugService.log(
            '🔐 Loaded existing API token',
            level: DebugLevel.info,
            tag: 'ApiTokenSetup',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        DebugService.log(
          '❌ Failed to load existing token: $e',
          level: DebugLevel.error,
          tag: 'ApiTokenSetup',
        );
      }
    }
  }

  Future<void> _validateToken() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final token = _tokenController.text.trim();
      await ReplicateService.setApiToken(token);
      
      final isValid = await ReplicateService.validateApiToken();
      
      if (isValid) {
        setState(() {
          _successMessage = 'API token is valid and ready to use!';
          _errorMessage = null;
        });
        
        if (kDebugMode) {
          DebugService.log(
            '✅ API token validation successful',
            level: DebugLevel.info,
            tag: 'ApiTokenSetup',
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid API token. Please check your token and try again.';
          _successMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Validation failed: $e';
        _successMessage = null;
      });
      
      if (kDebugMode) {
        DebugService.log(
          '❌ API token validation failed: $e',
          level: DebugLevel.error,
          tag: 'ApiTokenSetup',
        );
      }
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  Future<void> _clearToken() async {
    try {
      await ReplicateService.clearApiToken();
      _tokenController.clear();
      setState(() {
        _errorMessage = null;
        _successMessage = null;
      });
      
      if (kDebugMode) {
        DebugService.log(
          '🧹 API token cleared',
          level: DebugLevel.info,
          tag: 'ApiTokenSetup',
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API token cleared'),
            backgroundColor: Color(0xFF4A4A4A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear token: $e'),
            backgroundColor: const Color(0xFF4A4A4A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        foregroundColor: Colors.white,
        title: const Text('AI Enhancement Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Replicate API Token',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your Replicate API token to enable AI-powered image enhancement.',
                style: TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _tokenController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'API Token',
                  labelStyle: TextStyle(color: Color(0xFFB0B0B0)),
                  hintText: 'r8_...',
                  hintStyle: TextStyle(color: Color(0xFF707070)),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3A3A3A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF4A90E2)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your API token';
                  }
                  if (!value.trim().startsWith('r8_')) {
                    return 'API token should start with "r8_"';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF6A2A2A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A4A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2A6A2A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF4A90E2)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Color(0xFF4A90E2)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isValidating ? null : _validateToken,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isValidating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Validate Token',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _clearToken,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A4A4A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'How to get your API token:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '1. Go to replicate.com and sign up for an account\n'
                '2. Navigate to your account settings\n'
                '3. Generate a new API token\n'
                '4. Copy the token (starts with "r8_")\n'
                '5. Paste it in the field above and validate',
                style: TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'About AI Enhancement',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This app uses Replicate\'s AI models to enhance your selfies. '
          'Your API token is stored securely on your device and is only used '
          'to make requests to Replicate\'s servers.',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }
}
