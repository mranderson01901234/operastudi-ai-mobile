import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static final ImagePicker _picker = ImagePicker();
  static List<CameraDescription>? _cachedCameras;
  static bool _isEmulator = false;
  static bool _emulatorChecked = false;
  
  /// Check if running on Android emulator
  static Future<bool> _checkIfEmulator() async {
    if (_emulatorChecked) return _isEmulator;
    
    try {
      if (kIsWeb) {
        _isEmulator = false;
      } else if (Platform.isAndroid) {
        // Check various indicators that suggest emulator
        final result = await Process.run('getprop', ['ro.kernel.qemu']);
        _isEmulator = result.stdout.toString().trim() == '1';
        
        if (!_isEmulator) {
          // Additional checks for different emulator types
          final buildFingerprint = await Process.run('getprop', ['ro.build.fingerprint']);
          final fingerprint = buildFingerprint.stdout.toString().toLowerCase();
          _isEmulator = fingerprint.contains('generic') || 
                       fingerprint.contains('emulator') ||
                       fingerprint.contains('genymotion');
        }
      }
      
      _emulatorChecked = true;
      print('🔍 CameraService: Emulator detection - isEmulator: $_isEmulator');
    } catch (e) {
      print('⚠️ CameraService: Could not detect emulator status: $e');
      _isEmulator = false;
      _emulatorChecked = true;
    }
    
    return _isEmulator;
  }
  
  /// Check and request camera permissions
  static Future<bool> _checkCameraPermissions() async {
    try {
      print('🔐 CameraService: Checking camera permissions');
      
      if (kIsWeb) {
        print('🌐 CameraService: Web platform - no permission check needed');
        return true;
      }
      
      final cameraPermission = await Permission.camera.status;
      final storagePermission = await Permission.storage.status;
      
      print('🔐 CameraService: Camera permission: $cameraPermission');
      print('🔐 CameraService: Storage permission: $storagePermission');
      
      if (cameraPermission != PermissionStatus.granted) {
        print('🔐 CameraService: Requesting camera permission');
        final result = await Permission.camera.request();
        if (result != PermissionStatus.granted) {
          print('❌ CameraService: Camera permission denied');
          return false;
        }
      }
      
      if (storagePermission != PermissionStatus.granted) {
        print('🔐 CameraService: Requesting storage permission');
        final result = await Permission.storage.request();
        if (result != PermissionStatus.granted) {
          print('⚠️ CameraService: Storage permission denied, but continuing');
        }
      }
      
      print('✅ CameraService: Permissions granted');
      return true;
    } catch (e) {
      print('❌ CameraService: Permission check failed: $e');
      return false;
    }
  }
  
  /// Get available cameras with caching and emulator handling
  static Future<List<CameraDescription>> getAvailableCameras() async {
    if (kIsWeb) {
      print('🌐 CameraService: Web platform - no cameras available');
      return [];
    }
    
    if (_cachedCameras != null) {
      print('💾 CameraService: Using cached cameras: ${_cachedCameras!.length}');
      return _cachedCameras!;
    }
    
    try {
      print('📷 CameraService: Getting available cameras');
      final cameras = await availableCameras();
      _cachedCameras = cameras;
      
      print('✅ CameraService: Found ${cameras.length} cameras');
      for (int i = 0; i < cameras.length; i++) {
        final camera = cameras[i];
        print('�� Camera $i: ${camera.name} - ${camera.lensDirection}');
      }
      
      return cameras;
    } catch (e) {
      print('❌ CameraService: Failed to get cameras: $e');
      _cachedCameras = [];
      return [];
    }
  }
  
  /// Take photo with enhanced emulator support
  static Future<File?> takePhoto({bool useFrontCamera = true}) async {
    try {
      print('📸 CameraService: takePhoto called');
      print('📸 CameraService: Platform - kIsWeb: $kIsWeb, Android: ${!kIsWeb && Platform.isAndroid}');
      
      if (kIsWeb) {
        print('🌐 CameraService: Web detected, using gallery picker');
        return await pickFromGallery();
      }
      
      // Check if running on emulator
      final isEmulator = await _checkIfEmulator();
      if (isEmulator) {
        print('🤖 CameraService: Emulator detected - using gallery picker as fallback');
        return await pickFromGallery();
      }
      
      // Check permissions
      final hasPermissions = await _checkCameraPermissions();
      if (!hasPermissions) {
        print('❌ CameraService: Camera permissions not granted');
        throw Exception('Camera permissions not granted. Please enable camera access in settings.');
      }
      
      final cameras = await getAvailableCameras();
      if (cameras.isEmpty) {
        print('❌ CameraService: No cameras available, falling back to gallery');
        return await pickFromGallery();
      }
      
      print('📸 CameraService: Attempting to take photo with camera');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: useFrontCamera 
            ? CameraDevice.front 
            : CameraDevice.rear,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      
      if (image == null) {
        print('📸 CameraService: No photo taken');
        return null;
      }
      
      print('✅ CameraService: Photo taken successfully: ${image.path}');
      return File(image.path);
      
    } catch (e) {
      print('❌ CameraService: Camera error: $e');
      
      // Fallback to gallery if camera fails
      print('🔄 CameraService: Falling back to gallery picker');
      try {
        return await pickFromGallery();
      } catch (galleryError) {
        print('❌ CameraService: Gallery fallback also failed: $galleryError');
        throw Exception('Unable to access camera or gallery. Error: $e');
      }
    }
  }
  
  /// Pick image from gallery with enhanced error handling
  static Future<File?> pickFromGallery() async {
    try {
      print('📸 CameraService: pickFromGallery called');
      print('📸 CameraService: Platform - kIsWeb: $kIsWeb');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 4096,
        maxHeight: 4096,
      );
      
      if (image == null) {
        print('📸 CameraService: No image selected from gallery');
        return null;
      }
      
      print('📸 CameraService: Image selected from gallery: ${image.name}');
      print('📸 CameraService: Image path: ${image.path}');
      
      if (kIsWeb) {
        // For web, create a File from the bytes
        print('🌐 CameraService: Web detected, creating web file');
        final bytes = await image.readAsBytes();
        print('📸 CameraService: Image bytes: ${bytes.length} bytes');
        final webFile = _createWebFile(bytes, image.name);
        print('✅ CameraService: Web file created: ${webFile.path}');
        return webFile;
      }
      
      final file = File(image.path);
      final exists = await file.exists();
      final fileSize = exists ? await file.length() : 0;
      
      print('✅ CameraService: Mobile file created');
      print('�� CameraService: File exists: $exists, size: $fileSize bytes');
      
      return file;
      
    } catch (e) {
      print('❌ CameraService: Failed to pick image from gallery: $e');
      throw Exception('Failed to access gallery: $e');
    }
  }
  
  /// Create sample images for testing in emulator
  static Future<File?> createSampleImage() async {
    try {
      print('🎨 CameraService: Creating sample image for testing');
      
      // Create a simple colored rectangle as sample image
      final bytes = await rootBundle.load('assets/images/sample_selfie.jpg');
      final file = File('${Directory.systemTemp.path}/sample_selfie_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      
      print('✅ CameraService: Sample image created: ${file.path}');
      return file;
      
    } catch (e) {
      print('❌ CameraService: Failed to create sample image: $e');
      return null;
    }
  }
  
  /// Create a web-compatible File object
  static File _createWebFile(Uint8List bytes, String name) {
    print('🌐 CameraService: _createWebFile called with ${bytes.length} bytes');
    // For web, we'll create a File with a data URL
    final base64 = base64Encode(bytes);
    final dataUrl = 'data:image/jpeg;base64,$base64';
    print('✅ CameraService: Data URL created, length: ${dataUrl.length}');
    return File(dataUrl);
  }
  
  /// Get camera info for debugging
  static Future<Map<String, dynamic>> getCameraInfo() async {
    final info = <String, dynamic>{};
    
    try {
      info['isWeb'] = kIsWeb;
      info['isEmulator'] = await _checkIfEmulator();
      info['hasPermissions'] = await _checkCameraPermissions();
      
      if (!kIsWeb) {
        info['platform'] = Platform.operatingSystem;
        final cameras = await getAvailableCameras();
        info['cameraCount'] = cameras.length;
        info['cameras'] = cameras.map((c) => {
          'name': c.name,
          'lensDirection': c.lensDirection.toString(),
        }).toList();
      }
      
    } catch (e) {
      info['error'] = e.toString();
    }
    
    return info;
  }
  
  /// Clear cached camera data
  static void clearCache() {
    _cachedCameras = null;
    _emulatorChecked = false;
    print('🧹 CameraService: Cache cleared');
  }
}
