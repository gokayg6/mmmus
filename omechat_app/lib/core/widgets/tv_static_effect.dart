import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/app_colors.dart';

/// Premium Omegle-style TV Static Effect
/// Full screen immersive searching experience
class OmegleTvStaticEffect extends StatefulWidget {
  final bool isSearching;
  final VoidCallback? onSkip;
  final String statusText;

  const OmegleTvStaticEffect({
    super.key,
    required this.isSearching,
    this.onSkip,
    this.statusText = 'Birisi aranıyor',
  });

  @override
  State<OmegleTvStaticEffect> createState() => _OmegleTvStaticEffectState();
}

class _OmegleTvStaticEffectState extends State<OmegleTvStaticEffect>
    with TickerProviderStateMixin {
  late Ticker _ticker;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _waveAnimation;
  
  final math.Random _random = math.Random();
  int _frameCount = 0;
  
  // Noise data for static effect
  List<double> _noiseData = [];
  final int _noiseWidth = 120;
  final int _noiseHeight = 80;
  
  // Glitch effects
  double _glitchOffset = 0;
  bool _showGlitch = false;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _generateNoise();
    
    // Pulse animation for the searching indicator - 120Hz optimized
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),  // 120Hz: ~120 frames
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Glow animation for the ring - 120Hz optimized
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),  // 120Hz: ~180 frames
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // Wave animation for background - 120Hz optimized
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3000),  // 120Hz: ~360 frames
      vsync: this,
    )..repeat();
    
    _waveAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_waveController);
    
    _ticker = createTicker(_onTick)..start();
  }

  void _generateNoise() {
    _noiseData = List.generate(
      _noiseWidth * _noiseHeight,
      (_) => _random.nextDouble(),
    );
  }

  void _onTick(Duration elapsed) {
    if (mounted && widget.isSearching) {
      setState(() {
        _frameCount++;
        
        // Update noise every 2 frames
        if (_frameCount % 2 == 0) {
          _generateNoise();
        }
        
        // Random glitch effect
        if (_random.nextDouble() < 0.03) {
          _showGlitch = true;
          _glitchOffset = (_random.nextDouble() - 0.5) * 20;
        } else if (_showGlitch && _random.nextDouble() < 0.3) {
          _showGlitch = false;
          _glitchOffset = 0;
        }
        
        // Animate dots
        if (_frameCount % 20 == 0) {
          _dotCount = (_dotCount + 1) % 4;
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  String get _dots => '.' * _dotCount;

  @override
  Widget build(BuildContext context) {
    if (!widget.isSearching) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: size.width,
        height: size.height,
        color: const Color(0xFF0A0A0A),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Animated wave background
            AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WaveBackgroundPainter(
                    wavePhase: _waveAnimation.value,
                    color: AppColors.primary.withOpacity(0.03),
                  ),
                  size: Size.infinite,
                );
              },
            ),
            
            // TV Static noise layer
            Opacity(
              opacity: 0.15,
              child: CustomPaint(
                painter: _PremiumStaticPainter(
                  noiseData: _noiseData,
                  noiseWidth: _noiseWidth,
                  noiseHeight: _noiseHeight,
                  frameCount: _frameCount,
                  glitchOffset: _glitchOffset,
                ),
                size: Size.infinite,
              ),
            ),
            
            // Scan lines overlay
            CustomPaint(
              painter: _PremiumScanLinesPainter(frameCount: _frameCount),
              size: Size.infinite,
            ),
            
            // Vignette gradient
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.5, 0.8, 1.0],
                ),
              ),
            ),
            
            // Orange accent gradient at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 300,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            // Random interference lines
            if (_showGlitch) ...[
              Positioned(
                top: _random.nextDouble() * size.height * 0.8,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(_glitchOffset, 0),
                  child: Container(
                    height: 2 + _random.nextDouble() * 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.primary.withOpacity(0.3),
                          Colors.white.withOpacity(0.5),
                          AppColors.primary.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  _buildTopBar(context),
                  
                  const Spacer(flex: 2),
                  
                  // Center searching indicator
                  _buildSearchingIndicator(),
                  
                  const Spacer(flex: 2),
                  
                  // Bottom controls
                  _buildBottomControls(context),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'OmeChat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Online indicator
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFF00D26A).withOpacity(0.2 + _glowAnimation.value * 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D26A),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D26A).withOpacity(0.5 + _glowAnimation.value * 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${2847 + _frameCount % 100} çevrimiçi',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated rings
        AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1 * _glowAnimation.value),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
                
                // Animated ring 3
                Transform.scale(
                  scale: 0.9 + _pulseAnimation.value * 0.15,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.1 * _pulseAnimation.value),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                
                // Animated ring 2
                Transform.scale(
                  scale: 0.85 + _pulseAnimation.value * 0.2,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.15 * _pulseAnimation.value),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                
                // Animated ring 1
                Transform.scale(
                  scale: 0.8 + _pulseAnimation.value * 0.25,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2 * _pulseAnimation.value),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                
                // Center circle with gradient
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.primary.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.4 + _glowAnimation.value * 0.3),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3 * _glowAnimation.value),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person_search_rounded,
                      color: AppColors.primary.withOpacity(0.8 + _glowAnimation.value * 0.2),
                      size: 40,
                    ),
                  ),
                ),
                
                // Rotating dots
                ...List.generate(8, (index) {
                  final angle = (index * math.pi / 4) + (_frameCount * 0.02);
                  final radius = 85.0;
                  return Positioned(
                    left: 100 + math.cos(angle) * radius - 4,
                    top: 100 + math.sin(angle) * radius - 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(
                          0.3 + (math.sin(angle + _frameCount * 0.1) + 1) * 0.35,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
        
        const SizedBox(height: 50),
        
        // Status text with glassmorphism
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          _dots,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lütfen bekleyin, size uygun biri aranıyor',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Cancel button
          if (widget.onSkip != null)
            GestureDetector(
              onTap: widget.onSkip,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFDC2626),
                      const Color(0xFFB91C1C),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Aramayı İptal Et',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Tips row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTipChip(Icons.security_rounded, 'Anonim'),
              const SizedBox(width: 12),
              _buildTipChip(Icons.bolt_rounded, 'Hızlı'),
              const SizedBox(width: 12),
              _buildTipChip(Icons.hd_rounded, 'HD'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.primary.withOpacity(0.8),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium wave background painter
class _WaveBackgroundPainter extends CustomPainter {
  final double wavePhase;
  final Color color;

  _WaveBackgroundPainter({required this.wavePhase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    for (int i = 0; i < 3; i++) {
      path.reset();
      final yOffset = size.height * (0.3 + i * 0.2);
      final amplitude = 30.0 + i * 10;
      final phase = wavePhase + i * 0.5;
      
      path.moveTo(0, yOffset);
      
      for (double x = 0; x <= size.width; x += 5) {
        final y = yOffset + math.sin((x / size.width * 4 * math.pi) + phase) * amplitude;
        path.lineTo(x, y);
      }
      
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      
      canvas.drawPath(path, paint..color = color.withOpacity(0.02 - i * 0.005));
    }
  }

  @override
  bool shouldRepaint(_WaveBackgroundPainter oldDelegate) => true;
}

/// Premium static noise painter
class _PremiumStaticPainter extends CustomPainter {
  final List<double> noiseData;
  final int noiseWidth;
  final int noiseHeight;
  final int frameCount;
  final double glitchOffset;

  _PremiumStaticPainter({
    required this.noiseData,
    required this.noiseWidth,
    required this.noiseHeight,
    required this.frameCount,
    required this.glitchOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pixelWidth = size.width / noiseWidth;
    final pixelHeight = size.height / noiseHeight;
    
    final paint = Paint();
    
    for (int y = 0; y < noiseHeight; y++) {
      final xOffset = (y % 3 == 0) ? glitchOffset : 0.0;
      
      for (int x = 0; x < noiseWidth; x++) {
        final index = y * noiseWidth + x;
        if (index < noiseData.length) {
          final brightness = noiseData[index];
          final gray = (brightness * 200).toInt();
          
          paint.color = Color.fromARGB(255, gray, gray, gray);
          
          canvas.drawRect(
            Rect.fromLTWH(
              x * pixelWidth + xOffset,
              y * pixelHeight,
              pixelWidth + 1,
              pixelHeight + 1,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PremiumStaticPainter oldDelegate) => true;
}

/// Premium scan lines painter
class _PremiumScanLinesPainter extends CustomPainter {
  final int frameCount;
  
  _PremiumScanLinesPainter({required this.frameCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 1;

    // Static scan lines
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Moving bright scan line
    final scanY = (frameCount * 3) % size.height.toInt();
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY.toDouble(), size.width, 40));
    
    canvas.drawRect(
      Rect.fromLTWH(0, scanY.toDouble(), size.width, 40),
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(_PremiumScanLinesPainter oldDelegate) => true;
}
