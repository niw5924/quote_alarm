import 'package:flutter/material.dart';

class AlarmCancelSlider extends StatelessWidget {
  final double sliderValue;
  final ValueChanged<double> onSliderChanged;
  final VoidCallback onSliderComplete;

  const AlarmCancelSlider({
    super.key,
    required this.sliderValue,
    required this.onSliderChanged,
    required this.onSliderComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Slide to Cancel Alarm',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 150,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 50.0,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 30.0,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 30.0,
              ),
              thumbColor: Colors.white,
              activeTrackColor: const Color(0xFF6BF3B1),
              inactiveTrackColor: Colors.grey,
            ),
            child: Slider(
              value: sliderValue,
              min: 0,
              max: 1,
              onChanged: (value) {
                onSliderChanged(value);
                if (value == 1) {
                  onSliderComplete();
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
