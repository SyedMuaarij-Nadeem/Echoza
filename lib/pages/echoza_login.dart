import '../backend_files/validators.dart'; // Ensure this path is correct
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'echoza_signup.dart';
import '../main.dart'; // Assuming HomeScreen is in main.dart
import '../backend_files/firebase_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // State variables to hold validation error messages
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Clear previous errors and set loading state
    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate inputs using Validators class
    _emailError = Validators.validateEmail(email);
    _passwordError = Validators.validatePassword(password);

    // If there are any validation errors, update the UI and stop
    if (_emailError != null || _passwordError != null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await FirebaseService.loginWithEmail(email, password);

      // Check if email is verified
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await FirebaseService.sendEmailVerification();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please verify your email. A new verification link has been sent.',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.bottomToTop,
          duration: const Duration(milliseconds: 350),
          child:
              HomeScreen(), // Assuming HomeScreen is your main authenticated screen
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FirebaseService.getFriendlyErrorMessage(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseService.signInWithGoogle();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.bottomToTop,
          duration: const Duration(milliseconds: 350),
          child:
              HomeScreen(), // Assuming HomeScreen is your main authenticated screen
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    // Validate email before sending reset link
    final emailValidationError = Validators.validateEmail(email);
    if (emailValidationError != null) {
      setState(() {
        _emailError = emailValidationError; // Update error state for UI display
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(emailValidationError)));
      return;
    }

    try {
      await FirebaseService.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FirebaseService.getFriendlyErrorMessage(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7E7FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
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
                "Welcome back!",
                style: GoogleFonts.lato(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Login to your account",
                style: GoogleFonts.lato(fontSize: 16, color: Colors.black45),
              ),
              const SizedBox(height: 10),

              // Email field
              // In the build method, update both email and password fields to show errors below:

              // Email field with error below
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 15,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x27FF8764),
                          ),
                          child: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFFFF8764),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.lato(),
                            onChanged: (value) {
                              setState(() {
                                _emailError = Validators.validateEmail(value);
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Email',
                              border: InputBorder.none,
                              hintStyle: GoogleFonts.lato(),
                              // Removed errorText property from here
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Error text positioned below the container
              if (_emailError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 60.0, top: 4.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _emailError!,
                      style: GoogleFonts.lato(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),

              // Password field with error below
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 15,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x27FF8764),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFFFF8764),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.lato(),
                            onChanged: (value) {
                              setState(() {
                                _passwordError = Validators.validatePassword(
                                  value,
                                );
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Password',
                              border: InputBorder.none,
                              hintStyle: GoogleFonts.lato(),
                              // Removed errorText property from here
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Color(0xFFFF8764),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Error text positioned below the container
              if (_passwordError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 60.0, top: 4.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _passwordError!,
                      style: GoogleFonts.lato(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),

              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _resetPassword,
                    child: Text(
                      "Forgot Password?",
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Color(0xFFFE5B54),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sign in button
              SizedBox(
                width: 150,
                child: InkWell(
                  onTap: _isLoading ? null : _login,
                  borderRadius: BorderRadius.circular(30),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFE5B54), Color(0xFFFF8764)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Text(
                                "Login",
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      "Or continue with",
                      style: GoogleFonts.lato(fontSize: 13),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),

              // Google sign in button
              InkWell(
                onTap: _isLoading ? null : _googleSignIn,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Image.asset('assets/google-logo.png', height: 20),
                      const SizedBox(width: 8),
                      Text("Google", style: GoogleFonts.lato(fontSize: 16)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Sign up text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.lato(fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.bottomToTop,
                          duration: const Duration(milliseconds: 350),
                          child: const SignupPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Sign up here",
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Color(0xFFFE5B54),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
