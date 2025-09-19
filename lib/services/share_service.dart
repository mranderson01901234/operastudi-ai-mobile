import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/share_options_dialog.dart';
import 'gallery_service.dart';
import 'cloud_storage_service.dart';
import 'auth_service.dart';
import '../config/app_logger.dart';

class ShareService {
  /// Main entry point for sharing via different methods
  static Future<bool> shareVia(ShareMethod method, File imageFile) async {
    AppLogger.info('Sharing image via: $method');
    
    try {
      switch (method) {
        case ShareMethod.native:
          return await _shareNative(imageFile);
        case ShareMethod.whatsapp:
          return await _shareToWhatsApp(imageFile);
        case ShareMethod.instagram:
          return await _shareToInstagram(imageFile);
      }
    } catch (e) {
      AppLogger.error('Share failed for method $method', e);
      return false;
    }
  }

  /// Native share using existing GalleryService
  static Future<bool> _shareNative(File imageFile) async {
    return await GalleryService.shareImage(
      imageFile: imageFile,
      text: 'Enhanced with Opera Studio AI',
      subject: 'Check out my enhanced image!',
    );
  }

  /// Share to WhatsApp
  static Future<bool> _shareToWhatsApp(File imageFile) async {
    try {
      AppLogger.info('Attempting WhatsApp share');
      
      // For WhatsApp sharing, we need to upload the image to get a shareable URL
      final shareableUrl = await _getShareableImageUrl(imageFile);
      
      if (shareableUrl == null) {
        // Fallback to native share if we can't get a URL
        AppLogger.info('Could not get shareable URL, falling back to native share');
        return await _shareNative(imageFile);
      }
      
      final message = 'Check out my image enhanced with Opera Studio AI! $shareableUrl';
      final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
      
      final uri = Uri.parse(whatsappUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        AppLogger.info('WhatsApp share URL launched successfully');
        return true;
      } else {
        AppLogger.info('WhatsApp not available, falling back to native share');
        return await _shareNative(imageFile);
      }
      
    } catch (e) {
      AppLogger.error('WhatsApp share failed', e);
      // Fallback to native share
      return await _shareNative(imageFile);
    }
  }

  /// Share to Instagram Stories or Feed
  static Future<bool> _shareToInstagram(File imageFile) async {
    AppLogger.info('Attempting Instagram share');
    
    if (!Platform.isAndroid && !Platform.isIOS) {
      AppLogger.info('Instagram sharing only available on mobile platforms');
      // Fall back to native share for desktop
      return await _shareNative(imageFile);
    }

    try {
      if (Platform.isAndroid) {
        return await _shareToInstagramAndroid(imageFile);
      } else if (Platform.isIOS) {
        return await _shareToInstagramIOS(imageFile);
      }
      return false;
    } catch (e) {
      AppLogger.error('Instagram share failed, falling back to native share', e);
      return await _shareNative(imageFile);
    }
  }

  /// Share to Instagram on Android using Intent
  static Future<bool> _shareToInstagramAndroid(File imageFile) async {
    try {
      // First try Instagram Stories with uploaded image
      final imageUrl = await _getShareableImageUrl(imageFile);
      if (imageUrl != null) {
        final storiesUrl = Uri.parse('instagram-stories://share');
        
        if (await canLaunchUrl(storiesUrl)) {
          AppLogger.info('Opening Instagram Stories');
          final launched = await launchUrl(storiesUrl);
          if (launched) {
            AppLogger.info('Instagram Stories opened successfully');
            return true;
          }
        }
      }
      
      // If Stories failed, try Instagram web create page with helpful context
      final instagramCreateUrl = Uri.parse('https://www.instagram.com/accounts/activity/');
      
      if (await canLaunchUrl(instagramCreateUrl)) {
        AppLogger.info('Opening Instagram web for manual upload');
        final launched = await launchUrl(instagramCreateUrl);
        if (launched) {
          AppLogger.info('Instagram web opened successfully');
          
          // Also copy image URL to clipboard for easy access
          if (imageUrl != null) {
            try {
              await Clipboard.setData(ClipboardData(text: imageUrl));
              AppLogger.info('Image URL copied to clipboard for manual upload');
            } catch (e) {
              AppLogger.info('Image URL for manual upload: $imageUrl');
            }
          }
          return true;
        }
      }
      
      AppLogger.info('Instagram not available, falling back to native share');
      return await _shareNative(imageFile);
      
    } catch (e) {
      AppLogger.error('Android Instagram share failed', e);
      return false;
    }
  }

  /// Share to Instagram on iOS using URL scheme
  static Future<bool> _shareToInstagramIOS(File imageFile) async {
    try {
      // Upload image first for web fallback
      final imageUrl = await _getShareableImageUrl(imageFile);
      
      // Try Instagram Stories URL scheme
      final storiesUrl = Uri.parse('instagram-stories://share');
      
      if (await canLaunchUrl(storiesUrl)) {
        AppLogger.info('Opening Instagram Stories on iOS');
        final launched = await launchUrl(storiesUrl);
        if (launched) {
          AppLogger.info('Instagram Stories opened successfully on iOS');
          return true;
        }
      }
      
      // Try Instagram create story URL
      final createStoryUrl = Uri.parse('https://www.instagram.com/create/story');
      
      if (await canLaunchUrl(createStoryUrl)) {
        AppLogger.info('Opening Instagram create story on iOS');
        final launched = await launchUrl(createStoryUrl);
        if (launched) {
          AppLogger.info('Instagram create story opened successfully on iOS');
          
          // Copy image URL to clipboard for manual upload
          if (imageUrl != null) {
            try {
              await Clipboard.setData(ClipboardData(text: imageUrl));
              AppLogger.info('Image URL copied to clipboard for manual upload');
            } catch (e) {
              AppLogger.info('Image URL for manual upload: $imageUrl');
            }
          }
          return true;
        }
      }
      
      // Fall back to regular Instagram
      final instagramUrl = Uri.parse('https://www.instagram.com/');
      
      if (await canLaunchUrl(instagramUrl)) {
        AppLogger.info('Opening Instagram web on iOS');
        final launched = await launchUrl(instagramUrl);
        if (launched) {
          AppLogger.info('Instagram web opened successfully on iOS');
          return true;
        }
      }
      
      AppLogger.info('Instagram not available on iOS, falling back to native share');
      return await _shareNative(imageFile);
      
    } catch (e) {
      AppLogger.error('iOS Instagram share failed', e);
      return false;
    }
  }

  /// Get a shareable URL for the image by uploading to cloud storage
  static Future<String?> _getShareableImageUrl(File imageFile) async {
    try {
      final user = AuthService.getCurrentUser();
      if (user == null) {
        AppLogger.info('No user logged in, cannot upload for sharing');
        return null;
      }
      
      // Upload to cloud storage with a temporary share prefix
      final fileName = 'share_${DateTime.now().millisecondsSinceEpoch}.png';
      final uploadResult = await CloudStorageService.uploadImage(
        imageFile, 
        user.id,
        customFileName: fileName,
      );
      
      final imageUrl = uploadResult['publicUrl'];
      AppLogger.info('Image uploaded for sharing: $imageUrl');
      return imageUrl;
      
    } catch (e) {
      AppLogger.error('Failed to upload image for sharing', e);
      return null;
    }
  }

  /// Check if a specific share method is available on this platform
  static Future<bool> isShareMethodAvailable(ShareMethod method) async {
    switch (method) {
      case ShareMethod.native:
        return true; // Always available with our Linux fallback
        
      case ShareMethod.whatsapp:
        // Check if we can launch WhatsApp URLs
        try {
          final uri = Uri.parse('https://wa.me/');
          return await canLaunchUrl(uri);
        } catch (e) {
          return false;
        }
        
      case ShareMethod.instagram:
        // Instagram is available on mobile platforms
        if (Platform.isAndroid || Platform.isIOS) {
          try {
            final uri = Uri.parse('https://www.instagram.com/');
            return await canLaunchUrl(uri);
          } catch (e) {
            return false;
          }
        }
        return true; // Fallback to native share on desktop
    }
  }
} 