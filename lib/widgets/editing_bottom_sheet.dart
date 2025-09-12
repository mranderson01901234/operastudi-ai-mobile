import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class EditingBottomSheet extends StatelessWidget {
  final String category;

  const EditingBottomSheet({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    print('📱 EditingBottomSheet: build called for category: $category');
    
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.5; // Reduced height to show more image
    
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          minHeight: 250,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A), // Removed opacity - fully opaque
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: const Border(
              top: BorderSide(
                color: Color(0xFF3A3A3A),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clickable top area to retract
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF707070),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Category title
                      Text(
                        category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Scrollable category-specific controls
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _buildCategoryControls(context),
                ),
              ),
              
              // Bottom padding for safe area
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCategoryControls(BuildContext context) {
    print('🎛️ EditingBottomSheet: _buildCategoryControls called for: ${category.toLowerCase()}');
    
    switch (category.toLowerCase()) {
      case 'filters':
        return _buildFiltersControls(context);
      case 'light':
        return _buildLightControls(context);
      case 'color':
        return _buildColorControls(context);
      case 'effects':
        return _buildEffectsControls(context);
      case 'crop':
        return _buildCropControls(context);
      default:
        return _buildDefaultControls(context);
    }
  }
  
  Widget _buildFiltersControls(BuildContext context) {
    final filters = [
      'None', 'Vintage', 'Black & White', 'Sepia', 'Dramatic', 'Portrait'
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 180, // Reduced height
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = context.watch<AppState>().selectedFilter == filter.toLowerCase();
              
              return GestureDetector(
                onTap: () {
                  print('🎨 EditingBottomSheet: FILTER TAPPED: $filter');
                  context.read<AppState>().setSelectedFilter(filter.toLowerCase());
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF4A4A4A)
                        : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? Colors.white
                          : const Color(0xFF3A3A3A),
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected 
                            ? Colors.white
                            : const Color(0xFFB0B0B0),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildLightControls(BuildContext context) {
    print('🔆 EditingBottomSheet: _buildLightControls called');
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Auto button and reset button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF3A3A3A)),
              ),
              child: const Text(
                'AUTO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Consumer<AppState>(
              builder: (context, appState, child) {
                final hasAdjustments = appState.brightness != 0 || appState.contrast != 0;
                return GestureDetector(
                  onTap: hasAdjustments ? () {
                    print('🔄 EditingBottomSheet: RESET LIGHT ADJUSTMENTS');
                    appState.setBrightness(0);
                    appState.setContrast(0);
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasAdjustments ? const Color(0xFF4A4A4A) : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF3A3A3A)),
                    ),
                    child: Text(
                      'RESET',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: hasAdjustments ? Colors.white : const Color(0xFF707070),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Brightness slider (labeled as Exposure for UI)
        Selector<AppState, double>(
          selector: (context, appState) => appState.brightness,
          builder: (context, brightness, child) {
            print('🔆 EditingBottomSheet: Building brightness slider with value: $brightness');
            return _buildSliderControl(
              context: context,
              label: 'Exposure',
              value: brightness,
              onChanged: (value) {
                print('🔆 EditingBottomSheet: BRIGHTNESS SLIDER CHANGED TO: $value');
                context.read<AppState>().setBrightness(value);
              },
              min: -100,
              max: 100,
            );
          },
        ),
        const SizedBox(height: 16),
        
        // Contrast slider
        Selector<AppState, double>(
          selector: (context, appState) => appState.contrast,
          builder: (context, contrast, child) {
            print('🔲 EditingBottomSheet: Building contrast slider with value: $contrast');
            return _buildSliderControl(
              context: context,
              label: 'Contrast',
              value: contrast,
              onChanged: (value) {
                print('🔲 EditingBottomSheet: CONTRAST SLIDER CHANGED TO: $value');
                context.read<AppState>().setContrast(value);
              },
              min: -100,
              max: 100,
            );
          },
        ),
        
        const SizedBox(height: 12),
      ],
    );
  }
  
  Widget _buildColorControls(BuildContext context) {
    print('🌈 EditingBottomSheet: _buildColorControls called');
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reset button for color adjustments
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Consumer<AppState>(
              builder: (context, appState, child) {
                final hasColorAdjustments = appState.saturation != 0 || appState.warmth != 0;
                return GestureDetector(
                  onTap: hasColorAdjustments ? () {
                    print('🔄 EditingBottomSheet: RESET COLOR ADJUSTMENTS');
                    appState.setSaturation(0);
                    appState.setWarmth(0);
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasColorAdjustments ? const Color(0xFF4A4A4A) : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF3A3A3A)),
                    ),
                    child: Text(
                      'RESET',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: hasColorAdjustments ? Colors.white : const Color(0xFF707070),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Selector<AppState, double>(
          selector: (context, appState) => appState.saturation,
          builder: (context, saturation, child) {
            print('🌈 EditingBottomSheet: Building saturation slider with value: $saturation');
            return _buildSliderControl(
              context: context,
              label: 'Saturation',
              value: saturation,
              onChanged: (value) {
                print('🌈 EditingBottomSheet: SATURATION SLIDER CHANGED TO: $value');
                context.read<AppState>().setSaturation(value);
              },
              min: -100,
              max: 100,
            );
          },
        ),
        const SizedBox(height: 16),
        Selector<AppState, double>(
          selector: (context, appState) => appState.warmth,
          builder: (context, warmth, child) {
            print('🌡️ EditingBottomSheet: Building warmth slider with value: $warmth');
            return _buildSliderControl(
              context: context,
              label: 'Warmth',
              value: warmth,
              onChanged: (value) {
                print('🌡️ EditingBottomSheet: WARMTH SLIDER CHANGED TO: $value');
                context.read<AppState>().setWarmth(value);
              },
              min: -100,
              max: 100,
            );
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
  
  Widget _buildEffectsControls(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text(
          'Effects controls coming soon',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFFB0B0B0),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCropControls(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text(
          'Crop controls coming soon',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFFB0B0B0),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDefaultControls(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text(
          'Controls coming soon',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFFB0B0B0),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSliderControl({
    required BuildContext context,
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
  }) {
    final displayValue = value.round();
    final isPositive = displayValue >= 0;
    final isActive = displayValue != 0;
    
    print('🎚️ EditingBottomSheet: _buildSliderControl called for $label with value: $value');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFFB0B0B0),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF4A4A4A) : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isActive ? const Color(0xFF5A5A5A) : const Color(0xFF3A3A3A),
                ),
              ),
              child: Text(
                '${isPositive && displayValue > 0 ? '+' : ''}$displayValue',
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.white : const Color(0xFF707070),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: isActive ? Colors.white : const Color(0xFF5A5A5A),
            inactiveTrackColor: const Color(0xFF3A3A3A),
            thumbColor: isActive ? Colors.white : const Color(0xFF707070),
            overlayColor: Colors.white.withOpacity(0.1),
            valueIndicatorColor: const Color(0xFF2A2A2A),
            trackHeight: 2.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: 200, // More precise control
              label: '${isPositive && displayValue > 0 ? '+' : ''}$displayValue',
              onChanged: (newValue) {
                print('🎚️ EditingBottomSheet: SLIDER $label CHANGED FROM $value TO $newValue');
                onChanged(newValue);
              },
            ),
          ),
        ),
      ],
    );
  }
}
