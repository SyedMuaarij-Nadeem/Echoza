import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';

import 'premium_upgrade_page.dart';

class AboutEchozaScreen extends StatelessWidget {
  const AboutEchozaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7E7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4754C5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About Echoza',
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Logo and Tagline
              Center(
                child: Column(
                  children: [
                    Image.asset('assets/echoza_logo.png', height: 150),

                    Text(
                      'Echoza',
                      style: TextStyle(
                        fontSize: 48,
                        fontFamily: 'omegle',
                        foreground:
                        Paint()
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

                    // Logo
                    Text(
                      'Enhance Your Audio Experience',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4754C5),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'v1.0.0',
                      style: GoogleFonts.lato(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Features Section
              Text(
                'Key Features',
                style: GoogleFonts.lato(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4754C5),
                ),
              ),
              const SizedBox(height: 15),

              _buildFeatureCard(
                icon: Icons.mic,
                title: 'Audio Recording',
                description: 'Record high-quality audio with built-in noise suppression and voice enhancement',
              ),
              _buildFeatureCard(
                icon: Icons.audio_file,
                title: 'Audio Processing',
                description: 'Import audio files and apply professional-grade noise reduction and voice clarity enhancement',
              ),
              _buildFeatureCard(
                icon: Icons.video_library,
                title: 'Video Audio Enhancement',
                description: 'Extract and enhance audio from video files while maintaining original video quality',
              ),
              _buildFeatureCard(
                icon: Icons.history,
                title: 'Processing History',
                description: 'Access all your previously processed files with easy playback and management',
              ),
              _buildFeatureCard(
                icon: Icons.person,
                title: 'Personalized Profile',
                description: 'Customize your profile with username and avatar selection',
              ),
              _buildFeatureCard(
                icon: Icons.workspace_premium,
                title: 'Premium Features',
                description: 'Unlock unlimited functionality and ad-free experience with premium subscription',
              ),

              const SizedBox(height: 30),

              // Premium CTA
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFE5B54), Color(0xFF4754C5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/crown.png', height: 30),
                        const SizedBox(width: 10),
                        Text(
                          'Go Premium',
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Unlock all features and enjoy an ad-free experience',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.bottomToTop,
                            duration: const Duration(milliseconds: 350),
                            child: const PremiumUpgradeScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Upgrade Now',
                        style: GoogleFonts.lato(
                          color: const Color(0xFF4754C5),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Footer
              Center(
                child: Text(
                  '© 2023 Echoza. All rights reserved',
                  style: GoogleFonts.lato(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8764).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFE5B54),
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4754C5),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}