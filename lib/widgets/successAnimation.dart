import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class SuccessAnimation extends StatelessWidget {
  final String filePath;
  final VoidCallback onClose;

  const SuccessAnimation({
    super.key,
    required this.filePath,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Color(0xFFE7E7FF),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation
            Lottie.asset(
              'assets/success.json',
              width: 300,
              height: 150,
              repeat: false,
            ),

            // Title
            Text(
              "Successfully Saved!",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4754C5),
              ),
            ),

            const SizedBox(height: 15),

            // File path
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    "Saved to:",
                    style: GoogleFonts.lato(fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  SelectableText(
                    filePath,
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Close button
            Container(
              width: 100,
              height: 52,
              decoration: BoxDecoration(
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
                gradient: LinearGradient(
                  colors: [Color(0xFFFE5B54), Color(0xFFFF8764)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: ElevatedButton.icon(
                onPressed: onClose,
                label: Text(
                  "OK",
                  style: GoogleFonts.lato(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}