import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({Key? key}) : super(key: key);

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
          'Contact & Support',
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFE5B54), Color(0xFF4754C5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(FontAwesomeIcons.headset, size: 40, color: Colors.white),
                  const SizedBox(height: 15),
                  Text(
                    'We\'re here to help!',
                    style: GoogleFonts.lato(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Contact our support team or browse our resources',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Contact Options
            Text(
              'Contact Options',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4754C5),
              ),
            ),
            const SizedBox(height: 15),

            _buildContactOption(
              icon: FontAwesomeIcons.solidEnvelope,
              title: 'Email Support',
              subtitle: 'Get help via email',
              onTap: () => _launchEmail(),
            ),
            _buildContactOption(
              icon: FontAwesomeIcons.solidComments,
              title: 'Live Chat',
              subtitle: 'Available 9AM-5PM (GMT)',
              onTap: () => _launchLiveChat(),
            ),
            _buildContactOption(
              icon: FontAwesomeIcons.phone,
              title: 'Call Support',
              subtitle: '+92 xxx xxxxxxx',
              onTap: () => _launchPhoneCall(),
            ),
            const SizedBox(height: 30),

            // Help Resources
            Text(
              'Help Resources',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4754C5),
              ),
            ),
            const SizedBox(height: 15),

            _buildResourceCard(
              icon: FontAwesomeIcons.book,
              title: 'Knowledge Base',
              onTap: () => _launchKnowledgeBase(),
            ),
            _buildResourceCard(
              icon: FontAwesomeIcons.solidQuestionCircle,
              title: 'FAQs',
              onTap: () => _launchFAQs(),
            ),
            _buildResourceCard(
              icon: FontAwesomeIcons.youtube,
              title: 'Video Tutorials',
              onTap: () => _launchTutorials(),
            ),
            const SizedBox(height: 30),

            // Social Media
            Center(
              child: Column(
                children: [
                Text(
                'Connect With Us',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4754C5),
                ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      icon: FontAwesomeIcons.facebook,
                      color: const Color(0xFF4267B2),
                      onTap: () => _launchFacebook(),
                    ),
                    _buildSocialButton(
                      icon: FontAwesomeIcons.twitter,
                      color: const Color(0xFF1DA1F2),
                      onTap: () => _launchTwitter(),
                    ),
                    _buildSocialButton(
                      icon: FontAwesomeIcons.instagram,
                      color: const Color(0xFFE1306C),
                      onTap: () => _launchInstagram(),
                    ),
                    _buildSocialButton(
                      icon: FontAwesomeIcons.linkedin,
                      color: const Color(0xFF0077B5),
                      onTap: () => _launchLinkedIn(),
                    ),
                  ],
                ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4754C5).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF4754C5)),
        ),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4754C5),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.lato(
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF4754C5)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildResourceCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4754C5)),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4754C5),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF4754C5)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // URL Launcher Methods
  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@echoza.com',
      queryParameters: {'subject': 'Echoza Support Request'},
    );

    if (await canLaunch(emailLaunchUri.toString())) {
      await launch(emailLaunchUri.toString());
    } else {
      throw 'Could not launch email';
    }
  }

  Future<void> _launchLiveChat() async {
    // Implement your live chat URL
    const url = 'https://echoza.com/live-chat';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Future<void> _launchPhoneCall() async {
    const url = 'tel:+15551234567';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Future<void> _launchKnowledgeBase() async {
    const url = 'https://echoza.com/knowledge-base';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Future<void> _launchFAQs() async {
    const url = 'https://echoza.com/faqs';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Future<void> _launchTutorials() async {
    const url = 'https://youtube.com/echoza';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Future<void> _launchFacebook() async {
    const url = 'https://facebook.com/echoza';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Future<void> _launchTwitter() async {
    const url = 'https://twitter.com/echoza';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Future<void> _launchInstagram() async {
    const url = 'https://instagram.com/echoza';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Future<void> _launchLinkedIn() async {
    const url = 'https://linkedin.com/company/echoza';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}