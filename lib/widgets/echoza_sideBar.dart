import '../pages/contact_support_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import '../pages/premium_upgrade_page.dart';
import '../pages/about_echoza_page.dart';
import '../backend_files/firebase_service.dart';
import '../pages/profile_settings_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class EchozaSidebar extends StatelessWidget {
  const EchozaSidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Color(0xFFE7E7FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFE7E7FF),
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menu',
                    style: GoogleFonts.lato(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4754C5)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Color(0xFFFE5B54)),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Update the profile settings menu item
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Profile Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.bottomToTop,
                          duration: const Duration(milliseconds: 350),
                          child: const ProfileSettingsPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: FontAwesomeIcons.headset,
                    title: 'Contact & Support',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.bottomToTop,
                          duration: const Duration(milliseconds: 350),
                          child: const ContactSupportScreen(),
                        ),
                      );
                      // Add navigation to tutorial
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'About Echoza',
                    onTap: () {
                      Navigator.push(
                          context,
                          PageTransition(
                          type: PageTransitionType.bottomToTop,
                          duration: const Duration(milliseconds: 350),
                      child: const AboutEchozaScreen(),
                      ),
                      );
                      // Add navigation to about page
                    },
                  ),
                  // Premium button with crown icon
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5867E1), Color(0xFF323D95)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Image.asset('assets/crown.png', height: 24),
                      title: Text(
                        'Go Premium',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            PageTransition(
                            type: PageTransitionType.bottomToTop,
                            duration: const Duration(milliseconds: 350),
                        child: PremiumUpgradeScreen(),
                        ),
                        );
                        // Add navigation to premium page
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Logout button above version
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5867E1), Color(0xFF323D95)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  // leading: Icon(Icons.logout, color: Colors.white),
                  leading: Image.asset('assets/logout.png', height: 32,),
                  title: Text(
                    'Logout',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  onTap: () async {
                    await FirebaseService.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ),
            ),

            // App version at bottom
            Padding(
              padding: const EdgeInsets.only(left: 170, bottom: 20, top: 8),
              child: Text(
                'Echoza v1.0.0',
                style: GoogleFonts.lato(
                    color: Colors.black38,
                    fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF4754C5)),
      title: Text(
        title,
        style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}