import 'package:flutter/material.dart';

class EditingFooter extends StatelessWidget {
  final bool isImageLoaded;
  final bool isProcessing;
  final bool isAiEnhancing;
  final bool hasEnhancedImage;
  final bool isSaving;
  final bool isSharing;
  final String? currentOpenCategory;
  final Function(String) onCategoryTap;
  final VoidCallback onEnhanceTap;
  final VoidCallback? onSaveTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onNewImageTap;
  final Function(String)? onModelSelect;
  final String selectedModel;

  const EditingFooter({
    super.key,
    required this.isImageLoaded,
    required this.isProcessing,
    required this.isAiEnhancing,
    required this.hasEnhancedImage,
    required this.isSaving,
    required this.isSharing,
    required this.currentOpenCategory,
    required this.onCategoryTap,
    required this.onEnhanceTap,
    this.onSaveTap,
    this.onShareTap,
    this.onNewImageTap,
    this.onModelSelect,
    required this.selectedModel,
  });

  @override
  Widget build(BuildContext context) {
    if (!isImageLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A2A), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: hasEnhancedImage && !isAiEnhancing
              ? _buildStage2Layout() // Post-enhancement: Full editing categories
              : _buildStage1Layout(), // Pre-enhancement: Enhance + AI models
        ),
      ),
    );
  }

  // Stage 1: Pre-Enhancement (Enhance button + AI model selection)
  Widget _buildStage1Layout() {
    return Row(
      children: [
        // Fixed Enhance button (always blue theme)
        Container(
          width: 120,
          height: 44,
          decoration: BoxDecoration(
            gradient: isAiEnhancing
                ? const LinearGradient(
                    colors: [Color(0xFF2A4A8A), Color(0xFF1A3A7A)], // Darker blue when processing
                  )
                : const LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF3A80D2)], // Blue theme
                  ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isAiEnhancing ? const Color(0xFF5A6A9A) : const Color(0xFF5AA0F2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A90E2).withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: isAiEnhancing ? null : onEnhanceTap,
              child: Center(
                child: isAiEnhancing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Enhance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Scrollable AI model selection
        Expanded(
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _buildModelButtons(),
            ),
          ),
        ),
      ],
    );
  }

  // Stage 2: Post-Enhancement (Full editing categories only)
  Widget _buildStage2Layout() {
    return SizedBox(
      height: 56, // Fixed height for categories
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _buildCategoryButtons(),
      ),
    );
  }

  List<Widget> _buildModelButtons() {
    final models = [
      {'name': 'General', 'available': true},
      {'name': 'Portrait', 'available': true},
      {'name': 'Real-ESRGAN', 'available': false},
      {'name': 'GFPGAN', 'available': false},
    ];

    return models.map((model) {
      final isSelected = selectedModel == model['name'];
      final isAvailable = model['available'] as bool;
      
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF4A4A4A) // Lighter background for selected
                : const Color(0xFF2A2A2A), // Standard background for unselected
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF6A6A6A) // Lighter border for selected
                  : const Color(0xFF3A3A3A), // Standard border for unselected
              width: isSelected ? 2 : 1, // Thicker border for selected
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ] : null, // Subtle shadow for selected state
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: isAvailable && onModelSelect != null 
                  ? () => onModelSelect!(model['name'] as String)
                  : null,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selection indicator dot for selected model
                    if (isSelected && isAvailable) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      model['name'] as String,
                      style: TextStyle(
                        color: isSelected && isAvailable 
                            ? Colors.white 
                            : isAvailable 
                                ? const Color(0xFFB0B0B0) 
                                : const Color(0xFF6A6A6A),
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    if (!isAvailable) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.lock,
                        color: Color(0xFF6A6A6A),
                        size: 14,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildCategoryButtons() {
    final categories = ['AI', 'Filters', 'Light', 'Color', 'Effects', 'Crop'];
    
    return categories.map((category) {
      final isSelected = currentOpenCategory == category;
      
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF3A3A3A)
                : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF5A5A5A)
                  : const Color(0xFF3A3A3A),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onCategoryTap(category),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF9A9A9A),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
