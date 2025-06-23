import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:ui';

class PremiumUpgradeScreen extends StatefulWidget {
  const PremiumUpgradeScreen({Key? key}) : super(key: key);

  @override
  _PremiumUpgradeScreenState createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends State<PremiumUpgradeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedPlanIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _glowAnimation;

  final List<SparkleParticle> _sparkles = [];
  final Random _random = Random();
  final int _sparkleCount = 16;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _colorAnimation = ColorTween(
      begin: const Color(0xFFFFD700), // Gold
      end: const Color(0xFFFFC400), // Brighter gold
    ).animate(_animationController);

    _glowAnimation = Tween<double>(begin: 8.0, end: 15.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize sparkles
    for (int i = 0; i < _sparkleCount; i++) {
      _sparkles.add(SparkleParticle(_random));
    }

    // Update sparkles with animation
    _animationController.addListener(() {
      setState(() {
        for (var sparkle in _sparkles) {
          sparkle.update();
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFE5B54), Color(0xFF4754C5)],
            stops: [0.2, 0.8],
            transform: GradientRotation(-0.5),
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.black12,
              elevation: 0,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Upgrade to Premium',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Animated Crown with Sparkles
                    SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow Effect
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, _) {
                                return Container(
                                  width: 120 + _glowAnimation.value * 2,
                                  height: 120 + _glowAnimation.value * 2,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _colorAnimation.value!.withOpacity(0.3),
                                        blurRadius: _glowAnimation.value,
                                        spreadRadius: _glowAnimation.value * 0.5,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // Sparkle Particles
                            for (var sparkle in _sparkles)
                              Positioned(
                                left: 100 + sparkle.offset.dx,
                                top: 100 + sparkle.offset.dy,
                                child: Opacity(
                                  opacity: sparkle.opacity,
                                  child: Transform.rotate(
                                    angle: sparkle.rotation,
                                    child: Icon(
                                      sparkle.icon,
                                      size: sparkle.size,
                                      color: sparkle.color,
                                    ),
                                  ),
                                ),
                              ),

                            // Animated Crown
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform(
                                  transform: Matrix4.identity()
                                    ..scale(_scaleAnimation.value)
                                    ..rotateZ(_rotateAnimation.value),
                                  child: ShaderMask(
                                    shaderCallback: (bounds) {
                                      return LinearGradient(
                                        colors: [
                                          _colorAnimation.value!,
                                          _colorAnimation.value!.withOpacity(0.9),
                                          _colorAnimation.value!,
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds);
                                    },
                                    child: Image.asset(
                                      'assets/crown.png',
                                      height: 120,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Title
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFFC400),
                              Color(0xFFFFD700),
                            ],
                            stops: [0.0, 0.5, 1.0],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds);
                        },
                        child: Text(
                          'PREMIUM MEMBERSHIP',
                          style: GoogleFonts.lato(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle
                      Text(
                        'Unlock all exclusive features',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Features Card
                      _buildFeatureCard(),
                      const SizedBox(height: 40),

                      // Plan Selection Title
                      Text(
                        'CHOOSE YOUR PLAN',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Plan Options
                      _buildPlanOption(
                        index: 0,
                        title: 'MONTHLY',
                        price: '\$9.99',
                        period: 'per month',
                        isSelected: _selectedPlanIndex == 0,
                      ),
                      const SizedBox(height: 15),

                      _buildPlanOption(
                        index: 1,
                        title: 'YEARLY',
                        price: '\$59.99',
                        period: 'per year',
                        subtitle: 'Save 50% compared to monthly',
                        isSelected: _selectedPlanIndex == 1,
                      ),
                      const SizedBox(height: 15),

                      _buildPlanOption(
                        index: 2,
                        title: 'LIFETIME',
                        price: '\$149.99',
                        period: 'one-time',
                        subtitle: 'Pay once, use forever',
                        isSelected: _selectedPlanIndex == 2,
                      ),
                      const SizedBox(height: 40),

                      // Upgrade Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _processPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            'UPGRADE NOW',
                            style: GoogleFonts.lato(
                              color: const Color(0xFF4754C5),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Payment Methods
                      Text(
                        'Secure payment with',
                        style: GoogleFonts.lato(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/payment/visa.png', height: 80),
                          const SizedBox(width: 15),
                          Image.asset('assets/payment/mastercard.png', height: 80),
                          const SizedBox(width: 15),
                          Image.asset('assets/payment/paypal.png', height: 80),
                          ],
                      ),
                      const SizedBox(height: 20),

                      // Terms
                      Text(
                        'Your subscription will automatically renew unless canceled at least 24 hours before the end of the current period.',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () {
                          // Show terms
                        },
                        child: Text(
                          'Terms and Conditions',
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildFeatureItem('Unlimited access to all content'),
          const SizedBox(height: 20),
          _buildFeatureItem('Ad-free experience'),
          const SizedBox(height: 20),
          _buildFeatureItem('Exclusive premium content'),
          const SizedBox(height: 20),
          _buildFeatureItem('Priority customer support'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 22),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanOption({
    required int index,
    required String title,
    required String price,
    required String period,
    String? subtitle,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedPlanIndex = index),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              )
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        subtitle,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  period,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFFE7E7FF), // Changed to match your app's bg color
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4754C5).withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: const Color(0xFF4754C5).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFFE5B54)), // Changed to accent color
                strokeWidth: 3, // Slightly thicker
              ),
              const SizedBox(height: 20),
              Text(
                'Processing Payment...',
                style: GoogleFonts.lato(
                  fontSize: 18, // Slightly larger
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4754C5),
                  letterSpacing: 0.5, // Improved readability
                ),
              ),
            ],
          ),
        ),
      ),
    );


    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);

    showDialog(
    context: context,
    builder: (context) => AlertDialog(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    ),
    title: Text(
    'Payment Successful!',
    style: GoogleFonts.lato(
    fontWeight: FontWeight.bold,
    color: const Color(0xFF4754C5),
    ),
    ),
    content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Image.asset('assets/crown.png', height: 60),
    const SizedBox(height: 20),
    Text(
    'Welcome to Premium!',
    style: GoogleFonts.lato(
    fontWeight: FontWeight.bold,
    ),
    ),
    const SizedBox(height: 10),
    Text(
    'Your premium membership is now active.',
    style: GoogleFonts.lato(),
    textAlign: TextAlign.center,
    ),
    ],
    ),
    actions: [
    TextButton(
    onPressed: () {
    Navigator.popUntil(context, (route) => route.isFirst);
    // Update premium status in your app
    },
    child: Text(
    'START USING PREMIUM',
    style: GoogleFonts.lato(
    color: const Color(0xFF4754C5),
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    ],
    ),
    );
  }
}

class SparkleParticle {
  final Random random;
  Offset offset = Offset.zero;
  double size = 0;
  double opacity = 0;
  double rotation = 0;
  double speed = 0;
  double angle = 0;
  double distance = 0;
  double life = 0;
  double maxLife = 0;
  IconData icon = Icons.star;
  Color color = Colors.white;

  SparkleParticle(this.random) {
    reset();
  }

  void reset() {
    angle = random.nextDouble() * 2 * pi;
    distance = 50 + random.nextDouble() * 40;
    size = 4 + random.nextDouble() * 8;
    opacity = 0;
    rotation = random.nextDouble() * 2 * pi;
    speed = 0.5 + random.nextDouble() * 2;
    life = 0;
    maxLife = 1 + random.nextDouble() * 2;

    // Randomly choose between different sparkle types
    final type = random.nextInt(3);
    switch (type) {
      case 0:
        icon = Icons.star;
        color = Colors.white.withOpacity(0.9);
        break;
      case 1:
        icon = Icons.star_border;
        color = Colors.white.withOpacity(0.7);
        break;
      case 2:
        icon = Icons.brightness_1;
        color = Colors.white.withOpacity(0.8);
        size = size * 0.7;
        break;
    }
  }

  void update() {
    life += 0.016; // Roughly 60 FPS
    if (life > maxLife) {
      reset();
    } else {
      // Fade in/out effect
      if (life < 0.3) {
        opacity = life / 0.3;
      } else if (life > maxLife - 0.3) {
        opacity = (maxLife - life) / 0.3;
      } else {
        opacity = 1;
      }

      // Circular motion with slight randomness
      angle += 0.01 * speed * (0.9 + random.nextDouble() * 0.2);
      offset = Offset(
        cos(angle) * distance * (1 + sin(life * 2) * 0.1),
        sin(angle) * distance * (1 + cos(life * 2) * 0.1),
      );

          // Gentle pulsing with randomness
          size = 4 + random.nextDouble() * 4 + sin(life * 5 + random.nextDouble()) * 2;

      // Occasional twinkle
      if (random.nextDouble() < 0.05) {
        size *= 1.5;
      }
    }
  }
}