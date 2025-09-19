import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/app_state.dart';
import '../services/credit_service.dart';
import '../services/gallery_service.dart';
import '../widgets/editing_footer.dart';
import '../widgets/enhancement/enhancement_progress_widget.dart';
import '../widgets/enhancement/credit_display_widget.dart';
import '../widgets/enhancement/error_display_widget.dart';
import '../widgets/before_after_image_display.dart';
import '../widgets/save_options_dialog.dart';
import '../widgets/share_options_dialog.dart';

import '../services/share_service.dart';
import 'image_history_screen.dart';


class EditingScreen extends StatefulWidget {
  const EditingScreen({super.key});

  @override
  _EditingScreenState createState() => _EditingScreenState();
}

class _EditingScreenState extends State<EditingScreen> {
  String _currentOpenCategory = '';
  String _selectedModel = 'General';

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
      backgroundColor: const Color(0xFF1A1A1A), // Fixed to match other screens
      body: SafeArea(
        child: Column(
          children: [
            // Header with credits
            // Header with credits on same line
            Consumer<AppState>(
              builder: (context, appState, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Back button
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      
                      const Spacer(),
                      
                      // Action buttons (only show when image is enhanced)
                      if (appState.hasEnhancedImage) ...[
                        _buildActionButton(
                          icon: appState.isSaving ? Icons.hourglass_empty : Icons.save_alt,
                          onPressed: appState.isSaving ? null : () => _handleSaveTap(context, appState),
                          tooltip: 'Save Image',
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          icon: appState.isSharing ? Icons.hourglass_empty : Icons.share,
                          onPressed: appState.isSharing ? null : () => _handleShareTap(context, appState),
                          tooltip: 'Share Image',
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          icon: Icons.add_photo_alternate,
                          onPressed: () => _handleNewImageTap(context, appState),
                          tooltip: 'New Image',
                        ),
                        const SizedBox(width: 16),
                      ],
                      
                      // Credits display
                      CreditDisplayWidget(
                        credits: appState.userCredits,
                        subscriptionTier: appState.userProfile?['subscription_tier'] ?? 'free',
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Image display with progress overlay
            Expanded(
              child: Stack(
                children: [
                  // Main image with before/after comparison
                  const BeforeAfterImageDisplay(),
                  
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
                          appState.enhanceImageWithAi(_selectedModel);
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
                  hasEnhancedImage: appState.hasEnhancedImage,
                  isSaving: appState.isSaving,
                  isSharing: appState.isSharing,
                  currentOpenCategory: _currentOpenCategory,
                  selectedModel: _selectedModel,
                  onCategoryTap: (category) {
                    setState(() {
                      _currentOpenCategory = category;
                    });
                  },
                  onModelSelect: (model) {
                    setState(() {
                      _selectedModel = model;
                    });
                  },
                  onEnhanceTap: () => _handleEnhanceTap(context, appState),
                  onSaveTap: () => _handleSaveTap(context, appState),
                  onShareTap: () => _handleShareTap(context, appState),
                  onNewImageTap: () => _handleNewImageTap(context, appState),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleSaveTap(BuildContext context, AppState appState) async {
    if (appState.isSaving || appState.isSharing) return;
    
    // Show save options dialog
    showDialog(
      context: context,
      builder: (context) => SaveOptionsDialog(
        onSave: (location, format, quality) async {
          try {
            await appState.saveImageToGallery(
              location: location,
              format: format,
              jpegQuality: quality,
            );
            
            // Show success message based on save location
            if (mounted) {
              String message = 'Image saved successfully!';
              if (location == SaveLocation.both) {
                message = 'Image saved to downloads! (Gallery save coming soon)';
              } else {
                message = 'Image saved to downloads!';
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: const Color(0xFF4CAF50),
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'View My Images',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ImageHistoryScreen()),
                      );
                    },
                  ),
                ),
              );
            }
          } catch (e) {
            // Handle save errors with helpful messaging
            if (mounted) {
              String errorMessage = 'Failed to save image';
              if (e.toString().contains('sign in')) {
                errorMessage = 'Please sign in to save images';
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Sign In',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _handleShareTap(BuildContext context, AppState appState) async {
    if (appState.isSharing || appState.isSaving) return;
    
    // Show share options dialog
    showDialog(
      context: context,
      builder: (context) => ShareOptionsDialog(
        onShare: (method) async {
          if (appState.processedImage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No enhanced image to share'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }
          
          try {
            // Set sharing state
            appState.setSharing(true);
            
            final success = await ShareService.shareVia(method, appState.processedImage!);
            
            if (success && mounted) {
              String message = _getSuccessMessage(method);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: const Color(0xFF4CAF50),
                  duration: const Duration(seconds: 3),
                ),
              );
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to share via ${_getMethodName(method)}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Share error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Save Instead',
                    textColor: Colors.white,
                    onPressed: () => _handleSaveTap(context, appState),
                  ),
                ),
              );
            }
          } finally {
            appState.setSharing(false);
          }
        },
      ),
    );
  }

  String _getSuccessMessage(ShareMethod method) {
    switch (method) {
      case ShareMethod.native:
        if (Platform.isLinux) {
          return 'Image prepared for sharing! Check your file manager or Downloads folder.';
        }
        return 'Share dialog opened successfully!';
      case ShareMethod.whatsapp:
        return 'WhatsApp share opened successfully!';
      case ShareMethod.instagram:
        if (Platform.isAndroid || Platform.isIOS) {
          return 'Instagram opened! Your image URL has been copied to clipboard for easy sharing.';
        }
        return 'Instagram web opened! Your image URL has been copied to clipboard for manual upload.';
    }
  }

  String _getMethodName(ShareMethod method) {
    switch (method) {
      case ShareMethod.native:
        return 'Native Share';
      case ShareMethod.whatsapp:
        return 'WhatsApp';
      case ShareMethod.instagram:
        return 'Instagram';
    }
  }


  void _handleEnhanceTap(BuildContext context, AppState appState) {
    if (appState.isAiEnhancing) return;
    
    if (appState.userCredits < 1) {
      _showInsufficientCreditsDialog(context);
      return;
    }
    appState.enhanceImageWithAi(_selectedModel);
  }

  void _showInsufficientCreditsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Insufficient Credits', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You need at least 1 credit to enhance an image. Purchase more credits or upgrade your subscription.',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to credit purchase screen
            },
            child: const Text('Get Credits'),
          ),
        ],
      ),
    );
  }

  void _handleNewImageTap(BuildContext context, AppState appState) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        appState.setSelectedImage(File(pickedFile.path));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New image selected'),
            backgroundColor: Color(0xFF4A90E2),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onPressed != null ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF3A3A3A),
            width: 1,
          ),
        ),
        child: IconButton(
          icon: Icon(
            icon,
            color: onPressed != null ? Colors.white : const Color(0xFF6A6A6A),
            size: 18,
          ),
          onPressed: onPressed,
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
