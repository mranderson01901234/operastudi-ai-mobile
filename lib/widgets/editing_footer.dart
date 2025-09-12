import 'package:flutter/material.dart';

class EditingFooter extends StatelessWidget {
  final bool isImageLoaded;
  final bool isProcessing;
  final bool isAiEnhancing;
  final String? currentOpenCategory;
  final Function(String) onCategoryTap;
  final VoidCallback onEnhanceTap;

  const EditingFooter({
    super.key,
    required this.isImageLoaded,
    required this.isProcessing,
    required this.isAiEnhancing,
    required this.currentOpenCategory,
    required this.onCategoryTap,
    required this.onEnhanceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140, // Increased height to prevent overflow
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF181A1B),
        border: Border(
          top: BorderSide(
            color: Color(0xFF3A3A3A),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Categories row with better spacing
          Expanded(
            child: _buildCategoriesList(),
          ),
          
          // Enhance button with more space
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isImageLoaded && !isProcessing && !isAiEnhancing ? onEnhanceTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isImageLoaded && !isProcessing && !isAiEnhancing 
                    ? const Color(0xFF4A90E2) 
                    : const Color(0xFF4A4A4A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_fix_high,
                    size: 18,
                    color: isImageLoaded && !isProcessing && !isAiEnhancing ? Colors.white : const Color(0xFF707070),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAiEnhancing ? 'AI Enhancing...' : (isProcessing ? 'Processing...' : 'Enhance'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoriesList() {
    final categories = [
      {'name': 'AI', 'icon': Icons.psychology, 'description': 'AI-powered enhancements'},
      {'name': 'Filters', 'icon': Icons.filter_list, 'description': 'Apply filters'},
      {'name': 'Light', 'icon': Icons.wb_sunny, 'description': 'Adjust brightness & contrast'},
      {'name': 'Color', 'icon': Icons.palette, 'description': 'Modify colors & saturation'},
      {'name': 'Effects', 'icon': Icons.auto_awesome, 'description': 'Add special effects'},
      {'name': 'Crop', 'icon': Icons.crop, 'description': 'Crop & rotate'},
    ];
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isEnabled = isImageLoaded;
        final isSelected = currentOpenCategory == category['name'];
        
        print('�� EditingFooter: Building button for ${category['name']} - isSelected: $isSelected, currentOpenCategory: $currentOpenCategory');
        
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _buildCategoryButton(
            name: category['name'] as String,
            icon: category['icon'] as IconData,
            description: category['description'] as String,
            isEnabled: isEnabled,
            isSelected: isSelected,
            onTap: () {
              print('🎯 EditingFooter: Button tapped for ${category['name']}');
              onCategoryTap(category['name'] as String);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildCategoryButton({
    required String name,
    required IconData icon,
    required String description,
    required bool isEnabled,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 70, // Reduced width to fit better
        height: 60, // Increased height for better proportions
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF4A90E2)
              : isEnabled 
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFF181A1B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF4A90E2)
                : const Color(0xFF3A3A3A),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isEnabled 
                  ? (isSelected ? Colors.white : const Color(0xFFB0B0B0))
                  : const Color(0xFF707070),
              size: 18, // Reduced icon size to fit better
            ),
            const SizedBox(height: 2), // Reduced spacing
            Text(
              name,
              style: TextStyle(
                color: isEnabled 
                    ? (isSelected ? Colors.white : const Color(0xFFB0B0B0))
                    : const Color(0xFF707070),
                fontSize: 10, // Reduced font size to fit better
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
