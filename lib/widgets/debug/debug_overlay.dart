import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/debug_service.dart';
import '../../services/camera_service.dart';
import '../../services/image_processor.dart';
import '../../screens/api_test_screen.dart';

class DebugOverlay extends StatefulWidget {
  final Widget child;
  
  const DebugOverlay({
    super.key,
    required this.child,
  });
  
  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  bool _showOverlay = false;
  bool _showLogs = false;
  bool _showStats = false;
  
  @override
  void initState() {
    super.initState();
    _showOverlay = DebugService.showDebugOverlay;
  }
  
  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return widget.child;
    }
    
    return Stack(
      children: [
        widget.child,
        if (_showOverlay) _buildDebugOverlay(),
        _buildDebugToggleButton(),
      ],
    );
  }
  
  Widget _buildDebugToggleButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 10,
      child: GestureDetector(
        onLongPress: () {
          setState(() {
            _showOverlay = !_showOverlay;
          });
          DebugService.log('👁️ Debug overlay toggled: $_showOverlay', 
                          level: DebugLevel.info);
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _showOverlay ? Colors.red.withOpacity(0.8) : Colors.grey.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Icon(
            Icons.bug_report,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
  
  Widget _buildDebugOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      right: 10,
      child: Container(
        width: 300,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDebugHeader(),
            Flexible(
              child: _buildDebugContent(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDebugHeader() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Text(
            'Debug Panel',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Spacer(),
          _buildHeaderButton(
            'Stats',
            _showStats,
            () => setState(() => _showStats = !_showStats),
          ),
          SizedBox(width: 4),
          _buildHeaderButton(
            'Logs',
            _showLogs,
            () => setState(() => _showLogs = !_showLogs),
          ),
          SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _showOverlay = false),
            child: Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeaderButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
  
  Widget _buildDebugContent() {
    if (_showLogs) {
      return _buildLogsView();
    } else if (_showStats) {
      return _buildStatsView();
    } else {
      return _buildSystemInfo();
    }
  }
  
  Widget _buildSystemInfo() {
    final debugInfo = DebugService.debugInfo;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('System', {
            'Platform': debugInfo['platform'] ?? 'Unknown',
            'Debug Mode': debugInfo['isDebugMode']?.toString() ?? 'false',
            'Processors': debugInfo['numberOfProcessors']?.toString() ?? 'N/A',
          }),
          SizedBox(height: 8),
          _buildInfoSection('Camera', {
            'Available': debugInfo['cameraInfo']?['cameraCount']?.toString() ?? '0',
            'Is Emulator': debugInfo['cameraInfo']?['isEmulator']?.toString() ?? 'Unknown',
            'Has Permissions': debugInfo['cameraInfo']?['hasPermissions']?.toString() ?? 'Unknown',
          }),
          SizedBox(height: 8),
          FutureBuilder<Map<String, dynamic>>(
            future: _getImageProcessorStats(),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? {};
              return _buildInfoSection('Image Processor', {
                'Total Processed': stats['totalProcessed']?.toString() ?? '0',
                'Cache Size': stats['cacheSize']?.toString() ?? '0',
                'Avg Time (ms)': stats['averageProcessingTime']?.toString() ?? '0',
              });
            },
          ),
          SizedBox(height: 8),
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  Future<Map<String, dynamic>> _getImageProcessorStats() async {
    final stats = ImageProcessor.getProcessingStats();
    final cacheSize = await ImageProcessor.getCacheSize();
    stats['cacheSizeMB'] = cacheSize.toStringAsFixed(2);
    return stats;
  }
  
  Widget _buildInfoSection(String title, Map<String, String> info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.yellow,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        SizedBox(height: 4),
        ...info.entries.map((entry) => Padding(
          padding: EdgeInsets.only(left: 8, bottom: 2),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  '${entry.key}:',
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 10),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  entry.value,
                  style: TextStyle(color: Colors.white, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        _buildActionButton('Clear Cache', () async {
          await ImageProcessor.clearCache();
          DebugService.log('🧹 Cache cleared from debug panel', level: DebugLevel.info);
        }),
        SizedBox(width: 8),
        _buildActionButton('API Test', () async {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ApiTestScreen()),
          );
        }),
        SizedBox(width: 8),
        _buildActionButton('Export Logs', () async {
          final file = await DebugService.exportLogs();
          if (file != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Logs exported to ${file.path}')),
            );
          }
        }),
      ],
    );
  }
  
  Widget _buildActionButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogsView() {
    final logs = DebugService.getRecentLogs(count: 100);
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              Text(
                'Recent Logs (${logs.length})',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
              Spacer(),
              GestureDetector(
                onTap: () {
                  DebugService.clearLogs();
                  setState(() {});
                },
                child: Text(
                  'Clear',
                  style: TextStyle(color: Colors.red, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: logs.length,
            reverse: true,
            itemBuilder: (context, index) {
              final log = logs[logs.length - 1 - index];
              return _buildLogEntry(log);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildLogEntry(DebugLog log) {
    Color levelColor;
    String levelIcon;
    
    switch (log.level) {
      case DebugLevel.error:
        levelColor = Colors.red;
        levelIcon = '🔴';
        break;
      case DebugLevel.warning:
        levelColor = Colors.orange;
        levelIcon = '🟡';
        break;
      case DebugLevel.info:
        levelColor = Colors.blue;
        levelIcon = '🔵';
        break;
      case DebugLevel.debug:
        levelColor = Colors.grey;
        levelIcon = '⚪';
        break;
      case DebugLevel.verbose:
        levelColor = Colors.grey.shade600;
        levelIcon = '⚫';
        break;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade800, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(levelIcon, style: TextStyle(fontSize: 8)),
              SizedBox(width: 4),
              if (log.tag != null) ...[
                Text(
                  '[${log.tag}]',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
              ],
              Text(
                log.timestamp.toString().substring(11, 19),
                style: TextStyle(color: Colors.grey, fontSize: 8),
              ),
            ],
          ),
          Text(
            log.message,
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (log.data != null && log.data!.isNotEmpty)
            Text(
              'Data: ${log.data.toString()}',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 8,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
  
  Widget _buildStatsView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Stats',
            style: TextStyle(
              color: Colors.yellow,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          SizedBox(height: 8),
          FutureBuilder<Map<String, dynamic>>(
            future: _getDetailedStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              
              final stats = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCard('Image Processing', {
                    'Total Processed': stats['totalProcessed']?.toString() ?? '0',
                    'Average Time': '${stats['averageProcessingTime'] ?? 0}ms',
                    'Cache Size': '${stats['cacheSizeMB'] ?? 0} MB',
                    'Cache Entries': stats['cacheSize']?.toString() ?? '0',
                  }),
                  SizedBox(height: 8),
                  _buildStatCard('Memory', {
                    'Cache Usage': '${stats['cacheSizeMB'] ?? 0} MB',
                    'Log Entries': stats['logCount']?.toString() ?? '0',
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
  
  Future<Map<String, dynamic>> _getDetailedStats() async {
    final imageStats = ImageProcessor.getProcessingStats();
    final cacheSize = await ImageProcessor.getCacheSize();
    
    return {
      ...imageStats,
      'cacheSizeMB': cacheSize.toStringAsFixed(2),
      'logCount': DebugService.getRecentLogs().length,
    };
  }
  
  Widget _buildStatCard(String title, Map<String, String> stats) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade600, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.yellow,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          SizedBox(height: 4),
          ...stats.entries.map((entry) => Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 9),
                ),
                Text(
                  entry.value,
                  style: TextStyle(color: Colors.white, fontSize: 9),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
