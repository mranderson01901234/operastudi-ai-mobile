import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class ImageDisplay extends StatelessWidget {
  final File? imageFile;
  final bool isImageLoaded;

  const ImageDisplay({
    super.key,
    required this.imageFile,
    required this.isImageLoaded,
  });

  @override
  Widget build(BuildContext context) {
    print('🖼️ ImageDisplay: build called');
    print('🖼️ ImageDisplay: imageFile: ${imageFile?.path}');
    print('🖼️ ImageDisplay: isImageLoaded: $isImageLoaded');
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1A1A1A),
      child: isImageLoaded && imageFile != null
          ? _buildImagePreview(context)
          : _buildPlaceholder(),
    );
  }
  
  Widget _buildImagePreview(BuildContext context) {
    print('🖼️ ImageDisplay: _buildImagePreview called');
    
    return Stack(
      children: [
        // Main image display - now uses Consumer to get the display image
        Consumer<AppState>(
          builder: (context, appState, child) {
            final displayImage = appState.displayImage;
            print('🖼️ ImageDisplay: Consumer builder called');
            print('🖼️ ImageDisplay: displayImage: ${displayImage?.path}');
            print('🖼️ ImageDisplay: selectedImage: ${appState.selectedImage?.path}');
            print('🖼️ ImageDisplay: processedImage: ${appState.processedImage?.path}');
            print('🖼️ ImageDisplay: hasAnyAdjustments: ${appState.hasAnyAdjustments}');
            print('🖼️ ImageDisplay: isProcessing: ${appState.isProcessing}');
            
            return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImage(displayImage),
              ),
            );
          },
        ),
        
        // Processing indicator
        Consumer<AppState>(
          builder: (context, appState, child) {
            if (!appState.isProcessing) return const SizedBox.shrink();
            
            print('⏳ ImageDisplay: Showing processing indicator');
            
            return Positioned(
              top: 32,
              right: 32,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Processing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        // Adjustments indicator
        Consumer<AppState>(
          builder: (context, appState, child) {
            if (!appState.hasAnyAdjustments) return const SizedBox.shrink();
            
            print('🎨 ImageDisplay: Showing adjustments indicator');
            
            return Positioned(
              top: 32,
              left: 32,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.tune,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Edited',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        // Error indicator
        Consumer<AppState>(
          builder: (context, appState, child) {
            if (appState.errorMessage == null) return const SizedBox.shrink();
            
            print('❌ ImageDisplay: Showing error indicator: ${appState.errorMessage}');
            
            return Positioned(
              bottom: 32,
              left: 32,
              right: 32,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appState.errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildImage(File? imageFile) {
    print('🖼️ ImageDisplay: _buildImage called with: ${imageFile?.path}');
    
    if (imageFile == null) {
      print('❌ ImageDisplay: imageFile is null, showing error widget');
      return _buildErrorWidget();
    }
    
    final imagePath = imageFile.path;
    print('🖼️ ImageDisplay: Image path: $imagePath');
    
    // Check if it's a data URL (for web)
    if (imagePath.startsWith('data:')) {
      print('🖼️ ImageDisplay: Processing data URL image');
      try {
        final base64String = imagePath.split(',')[1];
        final bytes = base64Decode(base64String);
        print('✅ ImageDisplay: Data URL decoded successfully, ${bytes.length} bytes');
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            print('❌ ImageDisplay: Error loading memory image: $error');
            return _buildErrorWidget();
          },
        );
      } catch (e) {
        print('❌ ImageDisplay: Error decoding base64: $e');
        return _buildErrorWidget();
      }
    } 
    // Check if it's a network URL
    else if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      print('🖼️ ImageDisplay: Processing network image');
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('❌ ImageDisplay: Error loading network image: $error');
          return _buildErrorWidget();
        },
      );
    }
    // It's a local file path
    else {
      print('🖼️ ImageDisplay: Processing local file image');
      return Image.file(
        imageFile,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('❌ ImageDisplay: Error loading local file: $error');
          return _buildErrorWidget();
        },
      );
    }
  }
  
  Widget _buildPlaceholder() {
    print('🖼️ ImageDisplay: _buildPlaceholder called');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.image_outlined,
              size: 64,
              color: Color(0xFF707070),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Image Selected',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB0B0B0),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose an image to start editing',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF707070),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    print('❌ ImageDisplay: _buildErrorWidget called');
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFEF4444),
            ),
            SizedBox(height: 16),
            Text(
              'Failed to load image',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
