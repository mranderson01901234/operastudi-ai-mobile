import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import 'editing_screen.dart';

import 'image_history_screen.dart';
import '../widgets/upload_option_card.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh user data when landing screen loads (after authentication)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔍 LandingScreen: initState - checking auth and refreshing user data');
      
      // Debug: Check auth state when landing screen loads
      final currentUser = AuthService.getCurrentUser();
      print('🔍 LandingScreen: Auth check - ${currentUser != null ? "User authenticated" : "No auth"}');
      
      final appState = Provider.of<AppState>(context, listen: false);
      print('🔍 LandingScreen: AppState provider found, refreshing user data');
      appState.refreshUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Correct background color
      appBar: AppBar(
        title: const Text(
          'opera',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF23272A),
        elevation: 0,
        actions: [
          // My Images button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ImageHistoryScreen()),
              );
            },
            icon: const Icon(Icons.photo_library, color: Colors.white),
            tooltip: 'My Images',
          ),
          // Debug button
          TextButton(
            onPressed: () {
              // Show debug info in a snackbar instead
              final user = AuthService.getCurrentUser();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    user != null 
                      ? 'Auth: ✅ ${user.email}' 
                      : 'Auth: ❌ Not signed in'
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Debug',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sign out button with options
          PopupMenuButton<String>(
            onSelected: (String result) async {
              if (result == 'logout') {
                await _showLogoutDialog();
              }
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return Container(
            color: const Color(0xFF1A1A1A), // Correct background color
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Credits Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF23272A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Credits: ${appState.userCredits}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Upload Options
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Choose an image to enhance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      UploadOptionCard(
                        icon: Icons.camera_alt,
                        title: 'Take Photo',
                        subtitle: 'Capture a new photo',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                      const SizedBox(height: 16),
                      
                      UploadOptionCard(
                        icon: Icons.photo_library,
                        title: 'Choose from Gallery',
                        subtitle: 'Select from your photos',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                      const SizedBox(height: 16),
                      
                      // My Images card
                      Consumer<AppState>(
                        builder: (context, appState, child) {
                          final count = appState.savedImagesCount;
                          final countText = count > 0 ? ' ($count)' : '';
                          return UploadOptionCard(
                            icon: Icons.collections,
                            title: 'My Images$countText',
                            subtitle: count > 0 
                                ? 'View your $count saved enhanced images'
                                : 'No saved images yet',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ImageHistoryScreen()),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Add test credits button - MOVED HERE under gallery option
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            appState.addTestCredits(5);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added 5 test credits!'),
                                backgroundColor: Color(0xFF4A90E2),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, color: Color(0xFF4A90E2)),
                          label: const Text(
                            'Add 5 Test Credits',
                            style: TextStyle(color: Color(0xFF4A90E2)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF4A90E2)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Show logout confirmation dialog with options
  Future<void> _showLogoutDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Sign Out',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Do you want to keep your login information saved for next time?',
            style: TextStyle(color: Color(0xFFB0B0B0)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFFB0B0B0)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('keep_credentials'),
              child: const Text(
                'Keep Login Info',
                style: TextStyle(color: Color(0xFF4A90E2)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('clear_credentials'),
              child: const Text(
                'Clear All Data',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (result != null && result != 'cancel') {
      await _performLogout(result == 'clear_credentials');
    }
  }

  /// Perform logout with optional credential clearing
  Future<void> _performLogout(bool clearCredentials) async {
    print('🚪 _performLogout: Starting logout process');
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF4A90E2)),
            const SizedBox(width: 16),
            const Text(
              'Signing out...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    try {
      // Give the dialog time to show, then dismiss it before auth state change
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('🚪 _performLogout: Dismissing loading dialog');
      // Dismiss the loading dialog before performing logout
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Small delay to ensure modal dismissal completes
      await Future.delayed(const Duration(milliseconds: 100));
      
      print('🚪 _performLogout: Calling AuthService.signOut');
      // Perform logout - this will trigger auth state change and navigation
      await AuthService.signOut(clearSavedCredentials: clearCredentials);
      
      print('🚪 _performLogout: Sign-out completed successfully');
      // The ImprovedAuthWrapper's StreamBuilder should automatically detect the auth state change
      // and navigate to LoginScreen. No manual navigation needed.
      
    } catch (e) {
      print('❌ _performLogout: Error during logout: $e');
      // Close loading dialog on error
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null) {
        final appState = Provider.of<AppState>(context, listen: false);
        appState.setSelectedImage(File(pickedFile.path));
        
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditingScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
