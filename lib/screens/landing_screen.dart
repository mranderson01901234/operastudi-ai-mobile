import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import 'editing_screen.dart';
import 'api_test_screen.dart';
import '../widgets/upload_option_card.dart';

class LandingScreen extends StatefulWidget {
  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF181A1B), // Force dark background
      appBar: AppBar(
        title: Text(
          'Selfie Editor',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF23272A),
        elevation: 0,
        actions: [
          // Debug button
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ApiTestScreen()),
              );
            },
            child: Text(
              'Debug',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(width: 8),
          // Sign out button
          IconButton(
            onPressed: () async {
              await AuthService.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return Container(
            color: Color(0xFF181A1B), // Force dark background
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Credits Display
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF23272A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Credits: ${appState.userCredits}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Add test credits button
                      OutlinedButton.icon(
                        onPressed: () {
                          appState.addTestCredits(5);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Added 5 test credits!"),
                              backgroundColor: Color(0xFF4A90E2),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: Icon(Icons.add, color: Color(0xFF4A90E2)),
                        label: Text(
                          'Add 5 Credits',
                          style: TextStyle(color: Color(0xFF4A90E2)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Color(0xFF4A90E2)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Upload Options
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Choose an image to enhance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      UploadOptionCard(
                        icon: Icons.camera_alt,
                        title: 'Take Photo',
                        subtitle: 'Capture a new photo',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                      SizedBox(height: 16),
                      
                      UploadOptionCard(
                        icon: Icons.photo_library,
                        title: 'Choose from Gallery',
                        subtitle: 'Select from your photos',
                        onTap: () => _pickImage(ImageSource.gallery),
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null) {
        final appState = Provider.of<AppState>(context, listen: false);
        appState.setSelectedImage(File(pickedFile.path));
        
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditingScreen()),
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
