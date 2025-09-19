import '../config/app_logger.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageProcessor {
  static final Map<String, File> _imageCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static final Map<String, int> _processingTimes = {};
  static int _totalProcessedImages = 0;

  /// Process image with adjustments
  static Future<File?> processImage({
    required File originalImage,
    double brightness = 0.0,
    double contrast = 0.0,
    double saturation = 0.0,
    double warmth = 0.0,
    String filter = 'none',
    bool isPreview = false,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Generate cache key
      final cacheKey = '${originalImage.path}_${brightness}_${contrast}_${saturation}_${warmth}_${filter}_$isPreview';
      
      // Check cache
      if (_imageCache.containsKey(cacheKey)) {
        final cachedFile = _imageCache[cacheKey]!;
        if (await cachedFile.exists()) {
          return cachedFile;
        }
      }
      
      // Load image
      final imageBytes = await originalImage.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Apply adjustments
      if (brightness != 0.0) {
        image = _adjustBrightness(image, brightness);
      }
      
      if (contrast != 0.0) {
        image = _adjustContrast(image, contrast);
      }
      
      if (saturation != 0.0) {
        image = _adjustSaturation(image, saturation);
      }
      
      if (warmth != 0.0) {
        image = _adjustWarmth(image, warmth);
      }
      
      // Save processed image
      final processedFile = await _saveProcessedImage(image, cacheKey, isPreview);
      
      // Cache the result
      _imageCache[cacheKey] = processedFile;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      stopwatch.stop();
      _processingTimes[cacheKey] = stopwatch.elapsedMilliseconds;
      _totalProcessedImages++;
      
      return processedFile;
    } catch (e) {
      AppLogger.error('ImageProcessor: Processing error', e);
      return null;
    }
  }

  /// Adjust brightness
  static img.Image _adjustBrightness(img.Image image, double brightness) {
    if (brightness == 0.0) return image;
    
    final adjustment = brightness / 100.0;
    return img.colorOffset(image, red: adjustment.round(), green: adjustment.round(), blue: adjustment.round());
  }

  /// Adjust contrast
  static img.Image _adjustContrast(img.Image image, double contrast) {
    if (contrast == 0.0) return image;
    
    final adjustment = contrast / 100.0;
    return img.adjustColor(image, contrast: adjustment);
  }

  /// Adjust saturation
  static img.Image _adjustSaturation(img.Image image, double saturation) {
    if (saturation == 0.0) return image;
    
    final adjustment = saturation / 100.0;
    return img.adjustColor(image, saturation: adjustment);
  }

  /// Adjust warmth
  static img.Image _adjustWarmth(img.Image image, double warmth) {
    if (warmth == 0.0) return image;
    
    final adjustment = warmth / 100.0;
    return img.colorOffset(
      image, 
      red: adjustment > 0 ? (adjustment * 30).round() : (adjustment * 20).round(), 
      green: adjustment > 0 ? (adjustment * 15).round() : (adjustment * 10).round(), 
      blue: adjustment > 0 ? -(adjustment * 20).round() : -(adjustment * 30).round()
    );
  }

  /// Save processed image to temporary directory
  static Future<File> _saveProcessedImage(
    img.Image image,
    String cacheKey,
    bool isPreview,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = '${cacheKey}_${isPreview ? 'preview' : 'full'}.jpg';
    final file = File(path.join(tempDir.path, fileName));
    
    final quality = isPreview ? 75 : 85;
    final jpegBytes = img.encodeJpg(image, quality: quality);
    await file.writeAsBytes(jpegBytes);
    
    return file;
  }

  /// Clear all cached images
  static Future<void> clearCache() async {
    try {
      for (final file in _imageCache.values) {
        if (await file.exists()) {
          await file.delete();
        }
      }
      _imageCache.clear();
      _cacheTimestamps.clear();
      _processingTimes.clear();
    } catch (e) {
      AppLogger.error('Error clearing image cache', e);
    }
  }

  /// Get cache size in MB
  static Future<double> getCacheSize() async {
    double totalSize = 0.0;
    for (final file in _imageCache.values) {
      if (await file.exists()) {
        totalSize += await file.length();
      }
    }
    return totalSize / (1024 * 1024);
  }

  /// Get processing statistics
  static Map<String, dynamic> getProcessingStats() {
    final stats = <String, dynamic>{
      'totalProcessedImages': _totalProcessedImages,
      'cacheSize': _imageCache.length,
    };
    
    if (_processingTimes.isNotEmpty) {
      final totalTime = _processingTimes.values.reduce((a, b) => a + b);
      stats['averageProcessingTime'] = (totalTime / _processingTimes.length).round();
    }
    
    return stats;
  }
}
