import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../config/opera_studio_config.dart';
import '../services/web_api_service.dart';
import '../services/processing_history_service.dart';
import '../exceptions/custom_exceptions.dart';
import 'cloud_storage_service.dart';
import 'auth_service.dart';
import 'gallery_service.dart';
import '../services/replicate_service.dart'; // Added import for ReplicateService

class AppState extends ChangeNotifier {
  // Image state
  File? _selectedImage;
  File? _processedImage;
  
  // Processing states
  bool _isProcessing = false;
  bool _isAiEnhancing = false;
  double _processingProgress = 0.0;
  String _processingStatus = '';
  
  // User state
  int _userCredits = 0;
  Map<String, dynamic>? _userProfile;
  
  // Error state
  String? _error;

  // Image editing properties
  String? _selectedFilter;
  double _brightness = 0.0;
  double _contrast = 0.0;
  double _saturation = 0.0;
  double _warmth = 0.0;

  // Comparison functionality
  bool _isComparisonMode = false;
  double _comparisonSliderValue = 0.5;

  // Save functionality
  bool _isSaving = false;
  int _savedImagesCount = 0;

  // Constructor - initialize user data
  AppState() {
    _initializeUserData();
  }

  // ✅ ENHANCED: Initialize user data from authentication
  Future<void> _initializeUserData() async {
    try {
      final userProfile = await AuthService.getUserProfile();
      if (userProfile != null) {
        _userProfile = userProfile;
        _userCredits = userProfile['credits_remaining'] ?? 10;
      } else {
        // Fallback for development
        _userCredits = 10;
      }
      
      // Load saved images count
      await _loadSavedImagesCount();
    } catch (e) {
      // Fallback for development
      _userCredits = 10;
    }
    notifyListeners();
  }

  // ✅ NEW: Load saved images count
  Future<void> _loadSavedImagesCount() async {
    try {
      final user = AuthService.getCurrentUser();
      if (user != null) {
        final imageHistory = await CloudStorageService.getUserImageHistory(user.id);
        _savedImagesCount = imageHistory.length;
      }
    } catch (e) {
      print('❌ Error loading saved images count: $e');
      _savedImagesCount = 0;
    }
  }

  // ✅ NEW: Refresh saved images count (call after saving)
  Future<void> refreshSavedImagesCount() async {
    await _loadSavedImagesCount();
    notifyListeners();
  }

  // ✅ NEW: Refresh user data when authentication changes
  Future<void> refreshUserData() async {
    print('🔄 AppState: Refreshing user data after auth change');
    await _initializeUserData();
  }

  // Getters
  File? get selectedImage => _selectedImage;
  File? get processedImage => _processedImage;
  bool get isProcessing => _isProcessing;
  bool get isAiEnhancing => _isAiEnhancing;
  double get processingProgress => _processingProgress;
  String get processingStatus => _processingStatus;
  int get userCredits => _userCredits;
  Map<String, dynamic>? get userProfile => _userProfile;
  String? get error => _error;
  bool get isImageLoaded => _selectedImage != null;
  bool get isSaving => _isSaving;
  bool get hasEnhancedImage => _processedImage != null;
  int get savedImagesCount => _savedImagesCount;

  // Image editing getters
  String? get selectedFilter => _selectedFilter;
  double get brightness => _brightness;
  double get contrast => _contrast;
  double get saturation => _saturation;
  double get warmth => _warmth;

  // Comparison getters
  bool get canCompareImages => _selectedImage != null && _processedImage != null;
  bool get isComparisonMode => _isComparisonMode;
  double get comparisonSliderValue => _comparisonSliderValue;
  
  // Computed properties
  File? get displayImage => _processedImage ?? _selectedImage;
  bool get hasAnyAdjustments => _brightness != 0.0 || _contrast != 0.0 || _saturation != 0.0 || _warmth != 0.0 || _selectedFilter != null;
  String? get errorMessage => _error;

  // Image management
  void setSelectedImage(File image) {
    _selectedImage = image;
    _processedImage = null;
    _error = null;
    notifyListeners();
  }

  void resetImage() {
    _selectedImage = null;
    _processedImage = null;
    _error = null;
    notifyListeners();
  }

  void setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void updateUserCredits(int credits) {
    _userCredits = credits;
    notifyListeners();
  }

  // Add test credits for development
  void addTestCredits(int credits) {
    _userCredits += credits;
    notifyListeners();
  }

  // Image editing methods
  void setSelectedFilter(String? filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setBrightness(double brightness) {
    _brightness = brightness;
    notifyListeners();
  }

  void setContrast(double contrast) {
    _contrast = contrast;
    notifyListeners();
  }

  void setSaturation(double saturation) {
    _saturation = saturation;
    notifyListeners();
  }

  void setWarmth(double warmth) {
    _warmth = warmth;
    notifyListeners();
  }

  // Comparison methods
  void toggleComparisonMode() {
    _isComparisonMode = !_isComparisonMode;
    notifyListeners();
  }
  
  void updateComparisonSlider(double value) {
    _comparisonSliderValue = value;
    notifyListeners();
  }

  // ✅ ENHANCED: AI processing workflow with proper authentication
  Future<void> enhanceImageWithAi(String modelName) async {
    if (_selectedImage == null) {
      setError('No image selected for AI enhancement');
      return;
    }

    try {
      _isAiEnhancing = true;
      _processingProgress = 0.0;
      _processingStatus = 'Preparing image...';
      notifyListeners();

      // Step 1: Validate image and check credits
      await _validateImageAndCredits();
      _processingProgress = 0.1;
      _processingStatus = 'Checking credits...';
      notifyListeners();

      // Step 2: Upload image and create prediction
      _processingProgress = 0.2;
      _processingStatus = 'Uploading image...';
      notifyListeners();

      Map<String, dynamic> predictionResult;
      String? predictionId;
      if (modelName == 'General') {
        // FIXED: Use WebAPIService to call our API server (not direct Replicate)
        predictionResult = await WebAPIService.enhanceGeneral(_selectedImage!);
        predictionId = predictionResult['id'];
      } else if (modelName == 'Portrait') {
        // FIXED: Use WebAPIService for portrait model too
        predictionResult = await WebAPIService.enhanceGeneral(_selectedImage!);
        predictionId = predictionResult['id'];
      } else {
        setError('Unknown model selected');
        return;
      }

      // Step 3: Poll for completion with progress updates
      _processingProgress = 0.3;
      _processingStatus = 'Processing with AI...';
      notifyListeners();

      if (predictionId == null) {
        setError('Failed to create prediction. Please try again.');
        return;
      }
      // FIXED: Pass model name to use correct status checking service
      final completedResult = await _pollForResultWithProgress(predictionId, modelName);

      // Step 4: Download and save result
      _processingProgress = 0.8;
      _processingStatus = 'Downloading result...';
      notifyListeners();

      await _processEnhancedResult(completedResult);

      // Step 5: Update credits and history
      _processingProgress = 0.95;
      _processingStatus = 'Updating account...';
      notifyListeners();

      await _updateUserCreditsAndHistory();

      _processingProgress = 1.0;
      _processingStatus = 'Complete!';
      Future.delayed(const Duration(seconds: 2), () {
        _processingStatus = '';
        notifyListeners();
      });
    } catch (e) {
      setError(_handleProcessingError(e));
    } finally {
      _isAiEnhancing = false;
      _processingProgress = 0.0;
      notifyListeners();
    }
  }

  Future<void> _validateImageAndCredits() async {
    // Validate file size
    final fileSize = await _selectedImage!.length();
    if (fileSize > OperaStudioConfig.maxFileSizeBytes) {
      throw Exception('Image too large. Maximum size is ${OperaStudioConfig.maxFileSizeBytes ~/ (1024 * 1024)}MB');
    }

    // Check credits - get fresh data from server
    final userProfile = await AuthService.getUserProfile();
    if (userProfile != null) {
      _userCredits = userProfile['credits_remaining'] ?? 0;
    }
    
    if (_userCredits < 1) {
      throw InsufficientCreditsException('You need 1 credit to enhance this image. You have $_userCredits credits remaining.');
    }
  }

  Future<Map<String, dynamic>> _pollForResultWithProgress(String predictionId, String modelName) async {
    const maxAttempts = 60;
    int attempts = 0;
    final startTime = DateTime.now();
    
    while (attempts < maxAttempts) {
      // FIXED: Always use WebAPIService for status checking (both General and Portrait)
      Map<String, dynamic> result = await WebAPIService.checkStatus(predictionId);
      final status = result['status'] as String;
      
      // Update progress based on status
      if (status == 'starting') {
        _processingProgress = 0.1;
      } else if (status == 'processing') {
        final elapsed = DateTime.now().difference(startTime).inSeconds;
        _processingProgress = 0.2 + (elapsed / 120.0) * 0.7; // 20% + time-based
      }
      notifyListeners();
      
      // Check completion
      if (status == 'succeeded') return result;
      if (status == 'failed') throw ProcessingException('Processing failed');
      
      // Dynamic delay: 1s for starting, 2s for processing
      final delay = status == 'starting' ? 1 : 2;
      await Future.delayed(Duration(seconds: delay));
      attempts++;
    }
    
    throw TimeoutException('Processing timeout');
  }

  Future<void> _processEnhancedResult(Map<String, dynamic> result) async {
    print('🟢 _processEnhancedResult: result = ' + result.toString());
    if (result['output'] == null) {
      throw ProcessingException('No enhanced image received');
    }
    // Handle the correct data structure from API
    dynamic output = result['output'];
    String? imageUrl;
    if (output is String) {
      imageUrl = output;
    } else if (output is Map && output.containsKey('denoised_image')) {
      imageUrl = output['denoised_image'];
    } else if (output is List && output.isNotEmpty) {
      imageUrl = output.first;
    } else {
      throw ProcessingException('Unexpected output format: ' + output.toString());
    }
    if (imageUrl == null) {
      throw ProcessingException('No enhanced image URL found');
    }
    print('🟢 _processEnhancedResult: imageUrl = ' + imageUrl);
    final enhancedBytes = await WebAPIService.downloadImage(imageUrl);
    // Save to temporary file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(enhancedBytes);
    _processedImage = tempFile;
    // Replace the original image with the enhanced version
    _selectedImage = tempFile;
  }

  Future<void> _updateUserCreditsAndHistory() async {
    // Update user statistics in database
    await AuthService.updateUserStats(
      enhancementsIncrement: 1,
    );
    
    // Update local credits
    _userCredits -= 1;
    
    // Add to processing history
    await ProcessingHistoryService.addProcessingRecord(
      processingType: 'general_enhancement',
      creditsConsumed: 1,
      status: 'completed',
      resultUrl: _processedImage?.path,
    );
  }

  String _handleProcessingError(dynamic error) {
    if (error is InsufficientCreditsException) {
      return error.message;
    } else if (error is ProcessingException) {
      return error.message;
    } else if (error is TimeoutException) {
      return 'Processing timed out. Please check your connection and try again.';
    } else if (error.toString().contains('401')) {
      return 'Session expired. Please sign in again.';
    } else if (error.toString().contains('429')) {
      return 'Too many requests. Please wait a moment and try again.';
    } else {
      return 'Enhancement failed. Please try again.';
    }
  }

  // ✅ FIXED: Save functionality with proper authentication
  Future<void> saveImageToGallery({
    SaveLocation location = SaveLocation.both,
    ExportFormat format = ExportFormat.png,
    int jpegQuality = 90,
  }) async {
    if (_processedImage == null) {
      setError('No enhanced image to save');
      return;
    }

    _isSaving = true;
    notifyListeners();

    try {
      // ✅ DEBUG: Check authentication state
      final user = AuthService.getCurrentUser();
      print('🔍 Save Debug: getCurrentUser() returned: ${user != null ? "User ID: ${user.id}" : "null"}');
      
      if (user == null) {
        print('❌ Save Debug: No authenticated user found');
        throw Exception('Please sign in to save images.');
      }

      print('✅ Save Debug: User authenticated, proceeding with save');
      // Get fresh user data (using the already verified user)  
      final currentUser = user;

      // Upload to cloud storage
      final uploadResult = await CloudStorageService.uploadImage(
        _processedImage!,
        currentUser.id,
        customFileName: 'enhanced_image_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      if (!uploadResult['success']) {
        throw Exception('Failed to upload to cloud storage: ${uploadResult['error']}');
      }

      // Save metadata to database
      final metadataSaved = await CloudStorageService.saveImageMetadata(
        userId: currentUser.id,
        originalFilename: uploadResult['fileName'],
        storagePath: uploadResult['storagePath'],
        fileSize: uploadResult['fileSize'],
        mimeType: 'image/png',
        processingType: 'general_enhancement',
        creditsConsumed: 1,
      );

      if (!metadataSaved) {
        print('⚠️ Warning: Failed to save image metadata, but continuing...');
      }

      // Add to processing history (non-blocking - don't let this break the main flow)
      try {
        await ProcessingHistoryService.addProcessingRecord(
          processingType: 'general_enhancement',
          creditsConsumed: 1,
          status: 'completed',
          resultUrl: uploadResult['publicUrl'],
          originalImageUrl: _selectedImage?.path,
          enhancementSettings: {
            'scale': 2,
            'sharpen': 37,
            'denoise': 25,
            'face_recovery': false,
          },
        );
        print('✅ Processing history record added successfully');
      } catch (e) {
        print('⚠️ Warning: Failed to add processing history record: $e');
        // Continue with the save process - this is not critical
      }

      // Update user statistics
      await AuthService.updateUserStats(
        storageIncrement: uploadResult['fileSize'] / (1024 * 1024), // Convert to MB
      );

      // Save to specified locations using new GalleryService
      final galleryResult = await GalleryService.saveImage(
        imageFile: _processedImage!,
        location: location,
        format: format,
        jpegQuality: jpegQuality,
        customFileName: uploadResult['fileName'].toString().replaceAll('.png', ''),
      );

      if (galleryResult['success']) {
        if (galleryResult['galleryPath'] != null) {
          print('✅ Image saved to gallery: ${galleryResult['galleryPath']}');
        }
        if (galleryResult['downloadsPath'] != null) {
          print('✅ Image saved to downloads: ${galleryResult['downloadsPath']}');
        }
      } else {
        print('⚠️ Gallery save failed: ${galleryResult['error']}');
        // Continue anyway - cloud save succeeded
      }

      print('✅ Image saved to cloud storage: ${uploadResult['publicUrl']}');
      clearError(); // Clear any previous error
      
      // Refresh saved images count
      await refreshSavedImagesCount();
      
    } catch (e) {
      print('❌ Error saving image: $e');
      setError('Failed to save image: $e');
      rethrow; // Re-throw so the UI can handle it
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Share functionality
  bool _isSharing = false;
  bool get isSharing => _isSharing;

  void setSharing(bool sharing) {
    _isSharing = sharing;
    notifyListeners();
  }

  Future<bool> shareImage() async {
    if (_processedImage == null) {
      setError('No enhanced image to share');
      return false;
    }

    _isSharing = true;
    notifyListeners();

    try {
      final success = await GalleryService.shareImage(
        imageFile: _processedImage!,
        text: 'Enhanced with Opera Studio AI',
        subject: 'Check out my enhanced image!',
      );

      if (!success) {
        throw Exception('Failed to open share dialog');
      }

      print('✅ Share dialog opened successfully');
      clearError();
      return true;
      
    } catch (e) {
      print('❌ Error sharing image: $e');
      setError('Failed to share image: $e');
      return false;
    } finally {
      _isSharing = false;
      notifyListeners();
    }
  }
}
