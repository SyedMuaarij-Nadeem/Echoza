import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'echoza_login.dart';
import '../widgets/dot_wave_loader.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _subtitleController;
  late final AnimationController _bounceController;

  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoScale;

  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;

  late final Animation<double> _bounceScale;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _showLoader = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _playSplashAudio();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    final logoCurve = CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack);
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(logoCurve);
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(logoCurve);
    _logoScale = Tween<double>(begin: 0.5, end: 1).animate(logoCurve);

    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    final textCurve = CurvedAnimation(parent: _textController, curve: Curves.easeOut);
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(textCurve);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(textCurve);

    _subtitleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    final subtitleCurve = CurvedAnimation(parent: _subtitleController, curve: Curves.easeOut);
    _subtitleOpacity = Tween<double>(begin: 0, end: 1).animate(subtitleCurve);
    _subtitleSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(subtitleCurve);

    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.07), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.07, end: 1), weight: 50),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut));
  }

  Future<void> _playSplashAudio() async {
    await _audioPlayer.setVolume(1.0);
    await _audioPlayer.play(AssetSource('splashScreenSound.m4a'));
  }

  Future<void> _fadeOutAudio() async {
    double volume = 1.0;
    const fadeStep = 0.1;
    while (volume > 0.0) {
      volume = (volume - fadeStep).clamp(0.0, 1.0);
      await _audioPlayer.setVolume(volume);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await _audioPlayer.stop();
  }

  Future<void> _startAnimationSequence() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    await _textController.forward();
    await _bounceController.forward(); // Bounce completes here

    await _subtitleController.forward(); // Start subtitle immediately
    setState(() => _showLoader = true);  // Show loader as soon as subtitle appears

    await Future.delayed(const Duration(seconds: 4)); // Keep loader for 3 seconds

    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => user != null ? HomeScreen() : const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _subtitleController.dispose();
    _bounceController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7E7FF),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _bounceScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: SlideTransition(
                        position: _logoSlide,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Image.asset('assets/echoza_logo.png', width: 150, height: 150),
                        ),
                      ),
                    ),
                    FadeTransition(
                      opacity: _textOpacity,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            'Echoza',
                            style: TextStyle(
                              fontSize: 54,
                              fontFamily: 'omegle',
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  colors: [
                                    Color(0xFFFE5B54),
                                    Color(0xFFFF8764),
                                    Color(0xFFFE5B54),
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _subtitleOpacity,
                child: SlideTransition(
                  position: _subtitleSlide,
                  child: Text(
                    "Feel the Difference, Hear the Clarity",
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      color: const Color(0xFF4754C5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_showLoader) const DotWaveLoader(),
            ],
          ),
        ),
      ),
    );
  }
}
