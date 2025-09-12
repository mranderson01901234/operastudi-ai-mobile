import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/app_state.dart';
import '../services/credit_service.dart';
import '../widgets/editing_footer.dart';
import '../widgets/enhancement/enhancement_progress_widget.dart';
import '../widgets/enhancement/credit_display_widget.dart';
import '../widgets/enhancement/error_display_widget.dart';

class EditingScreen extends StatefulWidget {
  @override
  _EditingScreenState createState() => _EditingScreenState();
}

class _EditingScreenState extends State<EditingScreen> {
  String _currentOpenCategory = '';

  @override
  void initState() {
    super.initState();
    _loadUserCredits();
  }

  void _loadUserCredits() async {
    try {
      final creditInfo = await CreditService.getUserCredits();
      context.read<AppState>().updateUserCredits(creditInfo['credits_remaining']);
    } catch (e) {
      // Handle error silently or show minimal error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF181A1B),
      body: SafeArea(
        child: Column(
          children: [
            // Header with credits
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Edit Photo',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Consumer<AppState>(
                    builder: (context, appState, child) {
                      return CreditDisplayWidget(
                        credits: appState.userCredits,
                        subscriptionTier: appState.userProfile?['subscription_tier'] ?? 'free',
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Image display with progress overlay
            Expanded(
              child: Stack(
                children: [
                  // Main image
                  Selector<AppState, File?>(
                    selector: (context, appState) => appState.processedImage ?? appState.selectedImage,
                    builder: (context, image, child) {
                      if (image == null) {
                        return Center(child: Text('No image selected', style: TextStyle(color: Colors.white)));
                      }
                      return InteractiveViewer(
                        child: Image.file(image, fit: BoxFit.contain),
                      );
                    },
                  ),
                  
                  // Processing overlay
                  Consumer<AppState>(
                    builder: (context, appState, child) {
                      return EnhancementProgressWidget(
                        isProcessing: appState.isAiEnhancing,
                        progress: appState.processingProgress,
                        status: appState.processingStatus,
                      );
                    },
                  ),
                  
                  // Error overlay
                  Consumer<AppState>(
                    builder: (context, appState, child) {
                      return ErrorDisplayWidget(
                        error: appState.error,
                        onRetry: () {
                          appState.clearError();
                          appState.enhanceImageWithAi();
                        },
                        onDismiss: () => appState.clearError(),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Footer with enhance button
            Consumer<AppState>(
              builder: (context, appState, child) {
                return EditingFooter(
                  isAiEnhancing: appState.isAiEnhancing,
                  isImageLoaded: appState.isImageLoaded,
                  isProcessing: appState.isProcessing,
                  currentOpenCategory: _currentOpenCategory,
                  onCategoryTap: (category) {
                    setState(() {
                      _currentOpenCategory = category;
                    });
                  },
                  onEnhanceTap: () => _handleEnhanceTap(context, appState),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleEnhanceTap(BuildContext context, AppState appState) {
    if (appState.isAiEnhancing) return;
    
    if (appState.userCredits < 1) {
      _showInsufficientCreditsDialog(context);
      return;
    }
    
    appState.enhanceImageWithAi();
  }

  void _showInsufficientCreditsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2A2A),
        title: Text('Insufficient Credits', style: TextStyle(color: Colors.white)),
        content: Text(
          'You need at least 1 credit to enhance an image. Purchase more credits or upgrade your subscription.',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to credit purchase screen
            },
            child: Text('Get Credits'),
          ),
        ],
      ),
    );
  }
}
