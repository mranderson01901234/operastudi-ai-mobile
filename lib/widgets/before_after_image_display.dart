import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class BeforeAfterImageDisplay extends StatefulWidget {
  const BeforeAfterImageDisplay({super.key});

  @override
  State<BeforeAfterImageDisplay> createState() => _BeforeAfterImageDisplayState();
}

class _BeforeAfterImageDisplayState extends State<BeforeAfterImageDisplay> {
  final TransformationController _transformationController = TransformationController();
  
  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final originalImage = appState.selectedImage;
        final processedImage = appState.processedImage;
        
        // If no image is selected, show placeholder
        if (originalImage == null) {
          return _buildPlaceholder();
        }
        
        // If we have both images, automatically show comparison
        if (appState.canCompareImages) {
          // Auto-enable comparison mode when both images are available
          if (!appState.isComparisonMode) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              appState.toggleComparisonMode();
            });
          }
          return _buildComparisonView(originalImage, processedImage!, appState.comparisonSliderValue, appState);
        }
        
        // Otherwise show the display image (processed or original)
        return _buildSingleImage(appState.displayImage!);
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1A1A1A),
      child: Center(
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
      ),
    );
  }

  Widget _buildSingleImage(File imageFile) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1A1A1A),
      child: Container(
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
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: _buildImageWidget(imageFile),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonView(File originalImage, File processedImage, double sliderValue, AppState appState) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1A1A1A),
      child: Container(
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
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 5.0,
            child: _buildSplitView(originalImage, processedImage, sliderValue, appState),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitView(File originalImage, File processedImage, double sliderValue, AppState appState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get current transformation matrix to account for zoom/pan
        final Matrix4 transform = _transformationController.value;
        final double scale = transform.getMaxScaleOnAxis();
        final double translationX = transform.getTranslation().x;
        
        // Calculate split position accounting for zoom and pan
        final double baseSplitPosition = constraints.maxWidth * sliderValue;
        final double adjustedSplitPosition = (baseSplitPosition * scale) + translationX;
        final double clampedSplitPosition = adjustedSplitPosition.clamp(0.0, constraints.maxWidth);
        
        return GestureDetector(
          // Handle double-tap to reset zoom
          onDoubleTap: () {
            _transformationController.value = Matrix4.identity();
          },
          child: Stack(
            children: [
              // Original image (full size, left side visible)
              Positioned(
                left: 0,
                top: 0,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: ClipRect(
                  clipper: LeftSideClipper(clampedSplitPosition),
                  child: _buildImageWidget(originalImage),
                ),
              ),
              
              // Enhanced image (full size, right side visible)
              Positioned(
                left: 0,
                top: 0,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: ClipRect(
                  clipper: RightSideClipper(clampedSplitPosition),
                  child: _buildImageWidget(processedImage),
                ),
              ),
              
              // Divider line
              Positioned(
                left: clampedSplitPosition - 1,
                top: 0,
                width: 2,
                height: constraints.maxHeight,
                child: Container(
                  color: const Color(0xFF4A90E2),
                ),
              ),
              
              // Interactive touch area for slider - now works at all zoom levels
              _buildSliderTouchArea(constraints, appState, scale, translationX),
              
              // Draggable handle with better visibility at all zoom levels
              _buildDraggableHandle(clampedSplitPosition, constraints, scale),
              
              // Labels (always visible)
              _buildLabels(scale),
              
              // Zoom indicator (show current zoom level)
              if (scale > 1.1)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(scale * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              
              // Help indicator for slider usage when zoomed
              if (scale > 1.5)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Tap to adjust slider',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliderTouchArea(BoxConstraints constraints, AppState appState, double scale, double translationX) {
    return Positioned.fill(
      child: GestureDetector(
        onPanUpdate: (details) {
          // Handle horizontal pan gestures for slider with zoom compensation
          if ((details.delta.dx.abs() > details.delta.dy.abs())) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final localPosition = renderBox.globalToLocal(details.globalPosition);
            
            // Compensate for zoom and pan transformations
            final double adjustedX = (localPosition.dx - translationX) / scale;
            final double newValue = (adjustedX / constraints.maxWidth).clamp(0.0, 1.0);
            appState.updateComparisonSlider(newValue);
          }
        },
        onTapDown: (details) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.globalPosition);
          
          // Compensate for zoom and pan transformations
          final double adjustedX = (localPosition.dx - translationX) / scale;
          final double newValue = (adjustedX / constraints.maxWidth).clamp(0.0, 1.0);
          appState.updateComparisonSlider(newValue);
        },
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildDraggableHandle(double splitPosition, BoxConstraints constraints, double scale) {
    // Make handle more visible when zoomed in
    final double handleSize = scale > 2.0 ? 50.0 : 40.0;
    final double iconSize = scale > 2.0 ? 24.0 : 20.0;
    
    return Positioned(
      left: splitPosition - (handleSize / 2),
      top: constraints.maxHeight / 2 - (handleSize / 2),
      child: Container(
        width: handleSize,
        height: handleSize,
        decoration: BoxDecoration(
          color: const Color(0xFF4A90E2),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.drag_handle,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildLabels(double scale) {
    return Stack(
      children: [
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Original',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Enhanced',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget(File imageFile) {
    final imagePath = imageFile.path;
    
    // Handle different image types for web and mobile compatibility
    if (kIsWeb && imagePath.startsWith('data:')) {
      // Data URL for web
      try {
        final base64String = imagePath.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      } catch (e) {
        return _buildErrorWidget();
      }
    } else if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // Network image
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else {
      // Local file
      return Image.file(
        imageFile,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xFF2A2A2A),
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

// Custom clipper for left side of split view
class LeftSideClipper extends CustomClipper<Rect> {
  final double splitPosition;
  
  LeftSideClipper(this.splitPosition);
  
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, splitPosition, size.height);
  }
  
  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return oldClipper is LeftSideClipper && oldClipper.splitPosition != splitPosition;
  }
}

// Custom clipper for right side of split view
class RightSideClipper extends CustomClipper<Rect> {
  final double splitPosition;
  
  RightSideClipper(this.splitPosition);
  
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(splitPosition, 0, size.width - splitPosition, size.height);
  }
  
  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return oldClipper is RightSideClipper && oldClipper.splitPosition != splitPosition;
  }
} 