import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'echoza_login.dart';
import '../backend_files/firebase_service.dart';
import '../backend_files/validators.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _obscurePassword = true;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _usernameError;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  Future<void> _signUp() async {
    if (!mounted) return;

    setState(() {
      _emailError = null;
      _passwordError = null;
      _usernameError = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    _usernameError = Validators.validateUsername(username);
    _emailError = Validators.validateEmail(email);
    _passwordError = Validators.validatePassword(password);

    if (_emailError != null || _passwordError != null || _usernameError != null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final user = await FirebaseService.signUpWithEmail(email, password, username);

      if (!mounted) return;

      if (user != null) {
        await FirebaseService.sendEmailVerification();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification email sent to $email. Please verify your email.')),
        );

        // Wait a brief moment for user to see the message
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        // Navigate to login page
        Navigator.of(context).pushAndRemoveUntil(
          PageTransition(
            type: PageTransitionType.bottomToTop,
            duration: const Duration(milliseconds: 350),
            child: const LoginPage(),
          ),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FirebaseService.getFriendlyErrorMessage(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _googleSignIn() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final user = await FirebaseService.signInWithGoogle();

      if (!mounted) return;

      if (user != null) {
        // Wait for Firebase state to settle
        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        // Navigate to login page
        Navigator.of(context).pushAndRemoveUntil(
          PageTransition(
            type: PageTransitionType.bottomToTop,
            duration: const Duration(milliseconds: 350),
            child: const LoginPage(),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              Image.asset(
                'assets/echoza_logo.png',
                height: 150,
              ),
              Text(
                'Echoza',
                style: TextStyle(
                  fontSize: 48,
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

              Text(
                "Create an account",
                style: GoogleFonts.lato(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Sign up to get started",
                style: GoogleFonts.lato(fontSize: 16, color: Colors.black45),
              ),
              const SizedBox(height: 10),

              // Username Field with external error container
              Container(
                margin: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
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
                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0x27FF8764),
                            ),
                            child: const Icon(Icons.person_outline, color: Color(0xFFFF8764)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _usernameController,
                              style: GoogleFonts.lato(),
                              onChanged: (value) {
                                setState(() {
                                  _usernameError = Validators.validateUsername(value);
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Username',
                                border: InputBorder.none,
                                hintStyle: GoogleFonts.lato(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_usernameError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 60.0, top: 4.0),
                        child: Text(
                          _usernameError!,
                          style: GoogleFonts.lato(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),

              // Email field with external error container
              Container(
                margin: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
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
                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0x27FF8764),
                            ),
                            child: const Icon(Icons.email_outlined, color: Color(0xFFFF8764)),
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_emailError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 60.0, top: 4.0),
                        child: Text(
                          _emailError!,
                          style: GoogleFonts.lato(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),

              // Password field with external error container
              Container(
                margin: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
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
                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0x27FF8764),
                            ),
                            child: const Icon(Icons.lock_outline, color: Color(0xFFFF8764)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.lato(),
                              onChanged: (value) {
                                setState(() {
                                  _passwordError = Validators.validatePassword(value);
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Password',
                                border: InputBorder.none,
                                hintStyle: GoogleFonts.lato(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
                    ),
                    if (_passwordError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 60.0, top: 4.0),
                        child: Text(
                          _passwordError!,
                          style: GoogleFonts.lato(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Sign up button
              SizedBox(
                width: 150,
                child: InkWell(
                  onTap: _isLoading ? null : _signUp,
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
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Sign up",
                        style: GoogleFonts.lato(
                            fontSize: 16, color: Colors.white),
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
                    child: Text("Or continue with",
                        style: GoogleFonts.lato(fontSize: 13)),
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
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/google-logo.png',
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Google",
                        style: GoogleFonts.lato(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Already have account text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ",
                      style: GoogleFonts.lato(fontSize: 14)),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(
                        context,
                        PageTransition(
                          type: PageTransitionType.bottomToTop,
                          duration: const Duration(milliseconds: 350),
                          child: const LoginPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Log in",
                      style: GoogleFonts.lato(
                        fontSize: 14, color: Color(0xFFFE5B54),
                        fontWeight: FontWeight.w800,),
                    ),
                  )
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
