import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// TV Distortion Effect - Omegle-style matching animation
/// Creates scan lines, static noise, and glitch effects
class TvDistortionEffect extends StatefulWidget {
  final bool isActive;
  final Widget? child;
  final VoidCallback? onComplete;
  final Duration duration;

  const TvDistortionEffect({
    super.key,
    this.isActive = false,
    this.child,
    this.onComplete,
    this.duration = const Duration(milliseconds: 2500),
  });

  @override
  State<TvDistortionEffect> createState() => _TvDistortionEffectState();
}

class _TvDistortionEffectState extends State<TvDistortionEffect>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _glitchController;
  late AnimationController _scanLineController;
  late AnimationController _noiseController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glitchIntensity;

  final math.Random _random = math.Random();
  double _horizontalShift = 0;
  double _verticalShift = 0;
  List<_GlitchSlice> _glitchSlices = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    
    // Start animation if already active
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startEffect();
      });
    }
  }

  void _initAnimations() {
    // Main animation controller
    _mainController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Glitch effect controller (faster)
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // Scan line animation
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..repeat();

    // Noise animation
    _noiseController = AnimationController(
      duration: const Duration(milliseconds: 30),
      vsync: this,
    )..repeat();

    // Fade in/out
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_mainController);

    // Scale effect
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 15),
    ]).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));

    // Glitch intensity
    _glitchIntensity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.8), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.0), weight: 20),
    ]).animate(_mainController);

    // Listen for glitch updates
    _glitchController.addListener(_updateGlitch);
    _noiseController.addListener(() {
      if (mounted) setState(() {});
    });

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  void _updateGlitch() {
    if (!mounted) return;
    setState(() {
      _horizontalShift = (_random.nextDouble() - 0.5) * 20 * _glitchIntensity.value;
      _verticalShift = (_random.nextDouble() - 0.5) * 10 * _glitchIntensity.value;
      _generateGlitchSlices();
    });
  }

  void _generateGlitchSlices() {
    _glitchSlices = List.generate(
      _random.nextInt(5) + 3,
      (index) => _GlitchSlice(
        top: _random.nextDouble(),
        height: _random.nextDouble() * 0.1 + 0.02,
        shift: (_random.nextDouble() - 0.5) * 30,
        colorShift: _random.nextBool(),
      ),
    );
  }

  @override
  void didUpdateWidget(TvDistortionEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startEffect();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopEffect();
    }
  }

  void _startEffect() {
    _mainController.forward(from: 0);
    _glitchController.repeat();
  }

  void _stopEffect() {
    _mainController.stop();
    _glitchController.stop();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glitchController.dispose();
    _scanLineController.dispose();
    _noiseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if not active
    if (!widget.isActive) {
      return widget.child ?? const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _noiseController]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              children: [
                // Main content with glitch
                Transform.translate(
                  offset: Offset(_horizontalShift, _verticalShift),
                  child: _buildGlitchedContent(),
                ),
                
                // Scan lines overlay
                _buildScanLines(),
                
                // Static noise overlay
                _buildStaticNoise(),
                
                // Chromatic aberration effect
                _buildChromaticAberration(),
                
                // Vignette
                _buildVignette(),
                
                // "Connecting..." text
                _buildConnectingText(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlitchedContent() {
    return ClipRect(
      child: Stack(
        children: [
          // Base dark background
          Container(
            color: const Color(0xFF0A0A0A),
            child: widget.child,
          ),
          // Glitch slices
          ..._glitchSlices.map((slice) => Positioned(
            top: slice.top * MediaQuery.of(context).size.height,
            left: slice.shift,
            right: -slice.shift,
            height: slice.height * MediaQuery.of(context).size.height,
            child: Container(
              color: slice.colorShift
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.cyan.withOpacity(0.05),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildScanLines() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScanLinesPainter(
          animationValue: _scanLineController.value,
          intensity: _glitchIntensity.value,
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildStaticNoise() {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.08 * _glitchIntensity.value,
        child: CustomPaint(
          painter: _NoisePainter(seed: _noiseController.value),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget _buildChromaticAberration() {
    final offset = 3.0 * _glitchIntensity.value;
    return IgnorePointer(
      child: Stack(
        children: [
          // Red channel shift
          Positioned(
            left: offset,
            right: -offset,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.red.withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Cyan channel shift
          Positioned(
            left: -offset,
            right: offset,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.cyan.withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVignette() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.4),
              Colors.black.withOpacity(0.8),
            ],
            stops: const [0.4, 0.8, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectingText() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated dots
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: 3),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              final dots = '.' * (((_mainController.value * 10).toInt() % 4));
              return Text(
                'Bağlanıyor$dots',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Birisi aranıyor...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 40),
          // Progress indicator
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: _mainController.value,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlitchSlice {
  final double top;
  final double height;
  final double shift;
  final bool colorShift;

  _GlitchSlice({
    required this.top,
    required this.height,
    required this.shift,
    required this.colorShift,
  });
}

class _ScanLinesPainter extends CustomPainter {
  final double animationValue;
  final double intensity;

  _ScanLinesPainter({required this.animationValue, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.15 * intensity)
      ..strokeWidth = 1;

    // Horizontal scan lines
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Moving bright scan line
    final scanY = (animationValue * size.height * 2) % size.height;
    final scanPaint = Paint()
      ..color = Colors.white.withOpacity(0.05 * intensity)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(_ScanLinesPainter oldDelegate) => true;
}

class _NoisePainter extends CustomPainter {
  final double seed;
  final math.Random _random;

  _NoisePainter({required this.seed}) : _random = math.Random(seed.toInt() * 1000);

  @override
  void paint(Canvas canvas, Size size) {
    final pixelSize = 4.0;
    
    for (double x = 0; x < size.width; x += pixelSize) {
      for (double y = 0; y < size.height; y += pixelSize) {
        if (_random.nextDouble() > 0.7) {
          final brightness = _random.nextDouble();
          final paint = Paint()
            ..color = Colors.white.withOpacity(brightness * 0.3);
          canvas.drawRect(
            Rect.fromLTWH(x, y, pixelSize, pixelSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_NoisePainter oldDelegate) => true;
}


/// Full screen TV distortion overlay for matching
class TvDistortionOverlay extends StatelessWidget {
  final bool isVisible;
  final VoidCallback? onComplete;

  const TvDistortionOverlay({
    super.key,
    required this.isVisible,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: TvDistortionEffect(
        isActive: isVisible,
        onComplete: onComplete,
        duration: const Duration(milliseconds: 3000),
      ),
    );
  }
}

