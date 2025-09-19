import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/app_state.dart';
import '../services/cloud_storage_service.dart';
import '../services/auth_service.dart';

class ImageHistoryScreen extends StatefulWidget {
  const ImageHistoryScreen({super.key});

  @override
  _ImageHistoryScreenState createState() => _ImageHistoryScreenState();
}

class _ImageHistoryScreenState extends State<ImageHistoryScreen> {
  List<Map<String, dynamic>> _imageHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImageHistory();
  }

  Future<void> _loadImageHistory() async {
    try {
      print('🔍 ImageHistory Debug: Loading image history...');
      final user = AuthService.getCurrentUser();
      print('🔍 ImageHistory Debug: getCurrentUser() returned: ${user != null ? "User ID: ${user.id}" : "null"}');
      
      if (user != null) {
        print('🔍 ImageHistory Debug: Fetching history for user: ${user.id}');
        final history = await CloudStorageService.getUserImageHistory(user.id);
        print('🔍 ImageHistory Debug: Found ${history.length} images');
        setState(() {
          _imageHistory = history;
          _isLoading = false;
        });
      } else {
        print('❌ ImageHistory Debug: No authenticated user, cannot load history');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ ImageHistory Debug: Error loading history: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading image history: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'Image History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF23272A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4A90E2),
              ),
            )
          : _imageHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        color: Color(0xFF4A90E2),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No images saved yet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enhanced images will appear here after saving',
                        style: TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Go back to main screen
                        },
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Enhance Images'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _imageHistory.length,
                  itemBuilder: (context, index) {
                    final image = _imageHistory[index];
                    return Card(
                      color: const Color(0xFF2A2A2A),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: _buildImageThumbnail(image),
                        title: Text(
                          image['original_filename'] ?? 'Enhanced Image',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Size: ${_formatFileSize(image['file_size'] ?? 0)}',
                              style: const TextStyle(color: Color(0xFFB0B0B0)),
                            ),
                            Text(
                              'Created: ${_formatDate(image['created_at'])}',
                              style: const TextStyle(color: Color(0xFFB0B0B0)),
                            ),
                            Text(
                              'Credits: ${image['credits_consumed'] ?? 1}',
                              style: const TextStyle(color: Color(0xFF4A90E2)),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.download,
                            color: Color(0xFF4A90E2),
                          ),
                          onPressed: () => _downloadImage(image),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _downloadImage(Map<String, dynamic> image) async {
    try {
      // Show loading message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading image...'),
          backgroundColor: Color(0xFF4A90E2),
          duration: Duration(seconds: 1),
        ),
      );

      // Download image bytes from cloud storage
      final storagePath = image['storage_path'] as String?;
      if (storagePath == null) {
        throw Exception('Image storage path not found');
      }

      final imageBytes = await CloudStorageService.downloadImage(storagePath);
      if (imageBytes == null) {
        throw Exception('Failed to download image from cloud storage');
      }

      // Get downloads directory
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Could not access downloads directory');
      }

      // Create filename
      final originalFilename = image['original_filename'] as String? ?? 'enhanced_image';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${originalFilename}_$timestamp.png';
      
      // Save file
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(imageBytes);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved to Downloads: $filename'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildImageThumbnail(Map<String, dynamic> image) {
    final storagePath = image['storage_path'] as String?;
    
    if (storagePath == null) {
      return const Icon(
        Icons.image,
        color: Color(0xFF4A90E2),
        size: 32,
      );
    }

    // Get public URL for the image
    final publicUrl = Supabase.instance.client.storage
        .from('user-images')
        .getPublicUrl(storagePath);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF23272A),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          publicUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF4A90E2),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.image,
              color: Color(0xFF4A90E2),
              size: 32,
            );
          },
        ),
      ),
    );
  }
}
