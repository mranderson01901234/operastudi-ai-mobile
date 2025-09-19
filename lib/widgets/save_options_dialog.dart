import 'package:flutter/material.dart';
import '../services/gallery_service.dart';

class SaveOptionsDialog extends StatefulWidget {
  final Function(SaveLocation location, ExportFormat format, int quality) onSave;
  
  const SaveOptionsDialog({
    super.key,
    required this.onSave,
  });

  @override
  State<SaveOptionsDialog> createState() => _SaveOptionsDialogState();
}

class _SaveOptionsDialogState extends State<SaveOptionsDialog> {
  SaveLocation _selectedLocation = SaveLocation.downloads;
  ExportFormat _selectedFormat = ExportFormat.png;
  double _jpegQuality = 90.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Text(
        'Save Options',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Save Location
            const Text(
              'Save Location',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildLocationOptions(),
            
            const SizedBox(height: 20),
            
            // Export Format
            const Text(
              'Export Format',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildFormatOptions(),
            
            // JPEG Quality (only show if JPEG is selected)
            if (_selectedFormat == ExportFormat.jpeg) ...[
              const SizedBox(height: 20),
              const Text(
                'JPEG Quality',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildQualitySlider(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF9E9E9E)),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_selectedLocation, _selectedFormat, _jpegQuality.round());
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildLocationOptions() {
    return Column(
      children: [
        _buildLocationTile(
          SaveLocation.downloads,
          'Downloads Folder',
          'Save to downloads folder (accessible via file manager)',
          Icons.download,
        ),
        _buildLocationTile(
          SaveLocation.both,
          'Gallery & Downloads (Coming Soon)',
          'Gallery save will be available in a future update',
          Icons.photo_library,
          isDisabled: true,
        ),
      ],
    );
  }

  Widget _buildLocationTile(SaveLocation location, String title, String subtitle, IconData icon, {bool isDisabled = false}) {
    final isSelected = _selectedLocation == location;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDisabled 
            ? const Color(0xFF2A2A2A) 
            : isSelected 
                ? const Color(0xFF4CAF50).withOpacity(0.2) 
                : const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(8),
        border: isSelected && !isDisabled ? Border.all(color: const Color(0xFF4CAF50)) : null,
      ),
      child: ListTile(
        leading: Icon(
          icon, 
          color: isDisabled 
              ? Colors.white30 
              : isSelected 
                  ? const Color(0xFF4CAF50) 
                  : Colors.white70
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDisabled 
                ? Colors.white30 
                : isSelected 
                    ? const Color(0xFF4CAF50) 
                    : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDisabled 
                ? Colors.white30 
                : isSelected 
                    ? const Color(0xFF4CAF50).withOpacity(0.8) 
                    : Colors.white60,
            fontSize: 12,
          ),
        ),
        onTap: isDisabled ? null : () {
          setState(() {
            _selectedLocation = location;
          });
        },
      ),
    );
  }

  Widget _buildFormatOptions() {
    return Row(
      children: [
        Expanded(
          child: _buildFormatTile(
            ExportFormat.png,
            'PNG',
            'Lossless, larger file',
            Icons.image,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFormatTile(
            ExportFormat.jpeg,
            'JPEG',
            'Compressed, smaller file',
            Icons.photo,
          ),
        ),
      ],
    );
  }

  Widget _buildFormatTile(ExportFormat format, String title, String subtitle, IconData icon) {
    final isSelected = _selectedFormat == format;
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2196F3).withOpacity(0.2) : const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: const Color(0xFF2196F3)) : null,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFormat = format;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF2196F3) : Colors.white70,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF2196F3) : Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF2196F3).withOpacity(0.8) : Colors.white60,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQualitySlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quality',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '${_jpegQuality.round()}%',
                style: const TextStyle(
                  color: Color(0xFF2196F3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF2196F3),
              inactiveTrackColor: const Color(0xFF5A5A5A),
              thumbColor: const Color(0xFF2196F3),
              overlayColor: const Color(0xFF2196F3).withOpacity(0.2),
            ),
            child: Slider(
              value: _jpegQuality,
              min: 50,
              max: 100,
              divisions: 10,
              onChanged: (value) {
                setState(() {
                  _jpegQuality = value;
                });
              },
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Smaller file',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Text(
                'Better quality',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 