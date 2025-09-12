import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/web_api_service_test.dart';

class ApiTestScreen extends StatefulWidget {
  @override
  _ApiTestScreenState createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String _testResult = '';
  bool _isTesting = false;
  File? _testImage;
  double _progress = 0.0;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API Test'),
        backgroundColor: Color(0xFF181A1B),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Color(0xFF181A1B),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Image Selection
            Card(
              color: Color(0xFF23272A),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    if (_testImage == null)
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: Text('Select Test Image'),
                      )
                    else
                      Column(
                        children: [
                          Text(
                            'Selected: ${_testImage!.path.split('/').last}',
                            style: TextStyle(color: Colors.white70),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _pickImage,
                                child: Text('Change Image'),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _testImage != null ? _runCompleteTest : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF181A1B),
                                ),
                                child: Text('Run Complete Test'),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Progress Indicator
            if (_isTesting) ...[
              Card(
                color: Color(0xFF23272A),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _progress / 100,
                        backgroundColor: Color(0xFF3A3A3A),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '$_status',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '${_progress.toStringAsFixed(1)}%',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
            
            // Test Results
            Expanded(
              child: Card(
                color: Color(0xFF23272A),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _testResult.isEmpty ? 'No test results yet' : _testResult,
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          _testImage = File(pickedFile.path);
        });
        _addResult('✅ Image selected: ${pickedFile.path}');
      }
    } catch (e) {
      _addResult('❌ Error picking image: $e');
    }
  }

  Future<void> _runCompleteTest() async {
    if (_testImage == null) {
      _addResult('❌ No image selected');
      return;
    }

    setState(() {
      _isTesting = true;
      _progress = 0.0;
      _status = 'Starting test...';
      _testResult = '';
    });

    try {
      _addResult('🚀 Starting complete API test...');
      _addResult('📁 Test image: ${_testImage!.path}');
      _addResult('📏 Image size: ${await _testImage!.length()} bytes');
      
      // Step 1: Test API call
      _addResult('\\n🔗 Step 1: Testing API call...');
      _updateProgress(10, 'Calling enhancement API...');
      
      final result = await WebAPIServiceTest.enhanceGeneral(_testImage!);
      _addResult('✅ API call successful!');
      _addResult('📊 Response: ${json.encode(result)}');
      
      // Step 2: Check if we got a prediction ID
      final predictionId = result['id'];
      if (predictionId == null) {
        _addResult('❌ No prediction ID in response');
        return;
      }
      
      _addResult('\\n🔄 Step 2: Polling for results...');
      _updateProgress(20, 'Polling for enhancement...');
      
      // Step 3: Poll for completion
      final finalResult = await WebAPIServiceTest.pollForResult(
        predictionId,
        (progress, status) {
          _updateProgress(20 + (progress * 0.7), status);
        },
      );
      
      _addResult('✅ Enhancement completed!');
      _addResult('📊 Final result: ${json.encode(finalResult)}');
      
      // Step 4: Test image download
      final outputUrl = finalResult['output'];
      if (outputUrl != null && outputUrl is List && outputUrl.isNotEmpty) {
        _addResult('\\n📥 Step 3: Testing image download...');
        _updateProgress(90, 'Downloading enhanced image...');
        
        final imageBytes = await WebAPIServiceTest.downloadImage(outputUrl[0]);
        _addResult('✅ Image downloaded successfully!');
        _addResult('📏 Enhanced image size: ${imageBytes.length} bytes');
        
        // Save the enhanced image
        final directory = await getApplicationDocumentsDirectory();
        final enhancedImagePath = '${directory.path}/enhanced_test_image.jpg';
        final enhancedImageFile = File(enhancedImagePath);
        await enhancedImageFile.writeAsBytes(imageBytes);
        
        _addResult('💾 Enhanced image saved to: $enhancedImagePath');
      }
      
      _updateProgress(100, 'Test completed successfully!');
      _addResult('\\n�� Complete API test successful!');
      
    } catch (e) {
      _addResult('\\n❌ Test failed: $e');
      _updateProgress(0, 'Test failed');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  void _addResult(String result) {
    setState(() {
      _testResult += '$result\\n';
    });
  }

  void _updateProgress(double progress, String status) {
    setState(() {
      _progress = progress;
      _status = status;
    });
  }
}
