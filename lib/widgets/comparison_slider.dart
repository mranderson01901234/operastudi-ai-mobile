import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class ComparisonSlider extends StatelessWidget {
  const ComparisonSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (!appState.canCompareImages) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: appState.isComparisonMode 
                ? const Color(0xFF4A90E2) 
                : const Color(0xFF404040),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Toggle button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Compare Images',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: appState.isComparisonMode,
                    onChanged: (_) => appState.toggleComparisonMode(),
                    activeColor: const Color(0xFF4A90E2),
                    inactiveThumbColor: const Color(0xFF707070),
                    inactiveTrackColor: const Color(0xFF404040),
                  ),
                ],
              ),
              
              // Slider (only visible when comparison mode is on)
              if (appState.isComparisonMode) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Original',
                      style: TextStyle(
                        color: Color(0xFFB0B0B0),
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4.0,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10.0,
                            pressedElevation: 8.0,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 20.0,
                          ),
                          activeTrackColor: const Color(0xFF4A90E2),
                          inactiveTrackColor: const Color(0xFF404040),
                          thumbColor: const Color(0xFF4A90E2),
                          overlayColor: const Color(0xFF4A90E2).withOpacity(0.2),
                          // Ensure proper handle centering
                          trackShape: const RoundedRectSliderTrackShape(),
                          tickMarkShape: const RoundSliderTickMarkShape(),
                        ),
                        child: Slider(
                          value: appState.comparisonSliderValue,
                          onChanged: appState.updateComparisonSlider,
                          min: 0.0,
                          max: 1.0,
                        ),
                      ),
                    ),
                    const Text(
                      'Enhanced',
                      style: TextStyle(
                        color: Color(0xFFB0B0B0),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
