import 'package:flutter/material.dart';
import '../../../config/theme/app_theme.dart';

class SttListeningOverlay extends StatefulWidget {
  final double soundLevel;
  final String partialText;
  final VoidCallback onStop;

  const SttListeningOverlay({
    super.key,
    required this.soundLevel,
    required this.partialText,
    required this.onStop,
  });

  @override
  State<SttListeningOverlay> createState() => _SttListeningOverlayState();
}

class _SttListeningOverlayState extends State<SttListeningOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onStop, // Tap anywhere to stop
        child: Container(
          color: const Color(0xFF030508).withValues(alpha: 0.85),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon and Pulse
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!disableAnimations)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          // Scale goes 1.0 -> 1.6
                          final scale1 = 1.0 + (_pulseController.value * 0.6);
                          // Opacity goes 0.5 -> 0.0
                          final opacity1 = (0.5 - (_pulseController.value * 0.5))
                              .clamp(0.0, 1.0);

                          // Second ring offset by half a cycle
                          final offsetValue =
                              (_pulseController.value + 0.5) % 1.0;
                          final scale2 = 1.0 + (offsetValue * 0.6);
                          final opacity2 =
                              (0.5 - (offsetValue * 0.5)).clamp(0.0, 1.0);

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.scale(
                                scale: scale2,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF00A8FF)
                                          .withValues(alpha: opacity2),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              Transform.scale(
                                scale: scale1,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF00D4AA)
                                        .withValues(alpha: opacity1 * 0.4),
                                    border: Border.all(
                                      color: const Color(0xFF00D4AA)
                                          .withValues(alpha: opacity1),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    
                    // Mic Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF030508),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.mic,
                          color: Color(0xFF00D4AA),
                          size: 36,
                        ),
                        onPressed: widget.onStop,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Waveform (or fallback text)
              if (disableAnimations)
                Text(
                  'Listening...',
                  style: AppTheme.bodyLarge.copyWith(
                    color: const Color(0xFF00D4AA),
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                _buildWaveform(widget.soundLevel),
              
              const SizedBox(height: 32),
              
              // Partial Transcript
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  widget.partialText.isEmpty
                      ? 'Speak now...'
                      : widget.partialText,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white,
                    fontStyle: widget.partialText.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveform(double soundLevel) {
    // Normalize to a practical visual range (e.g., 4 to 40 logical pixels)
    // The soundLevel is expected to be roughly 0.0 to 1.0 here based on the clamping done in the caller.
    final height1 = 8.0 + (soundLevel * 16.0);
    final height2 = 12.0 + (soundLevel * 24.0);
    final height3 = 16.0 + (soundLevel * 32.0); // Center is most reactive
    final height4 = 12.0 + (soundLevel * 20.0);
    final height5 = 8.0 + (soundLevel * 12.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildWaveBar(height1),
        const SizedBox(width: 8),
        _buildWaveBar(height2),
        const SizedBox(width: 8),
        _buildWaveBar(height3),
        const SizedBox(width: 8),
        _buildWaveBar(height4),
        const SizedBox(width: 8),
        _buildWaveBar(height5),
      ],
    );
  }

  Widget _buildWaveBar(double height) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 6,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF00A8FF),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
