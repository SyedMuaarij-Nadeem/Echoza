import 'premium_upgrade_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:page_transition/page_transition.dart';
import '../backend_files/firebase_service.dart';
import '../widgets/avatar_picker.dart';
import '../backend_files/validators.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _selectedAvatar;
  bool _isPremium = false;
  bool _isLoading = true;
  bool _passwordVisible = false;
  bool _showPasswordFields = false;

  String? _usernameError;
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseService.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        setState(() {
          _usernameController.text = doc['username'] ?? '';
          _emailController.text = user.email ?? '';
          _selectedAvatar = doc['avatar'];
          _isPremium = doc['isPremium'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load user data: $e')));
      }
    }
  }

  Future<void> _showAvatarPickerDialog() async {
    final avatar = await showDialog<String>(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Choose your avatar',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4754C5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AvatarPicker(
                    initialAvatar: _selectedAvatar,
                    onAvatarSelected: (avatarName) {
                      Navigator.pop(context, avatarName);
                    },
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.lato(
                        color: const Color(0xFF4754C5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    if (avatar != null) {
      setState(() => _selectedAvatar = avatar);
    }
  }

  Future<bool> _updateProfile() async {
    final usernameError = Validators.validateUsername(_usernameController.text);
    if (usernameError != null) {
      setState(() => _usernameError = usernameError);
      return false; // Validation fail ho gayi
    } else {
      setState(() => _usernameError = null);
    }

    try {
      final user = FirebaseService.currentUser;
      if (user != null) {
        // Sirf woh data bhejein jo update karna hai
        final Map<String, dynamic> updates = {
          'username': _usernameController.text.trim(),
          'avatar': _selectedAvatar,
          // Aap yahan koi aur field bhi update kar sakte hain
        };

        // Naye updateUserProfile function ko call karein
        await FirebaseService.updateUserProfile(user.uid, updates);
        return true;
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
      return false;
    }
  }

  Future<void> _changePassword() async {
    // Validate password fields
    final newPasswordError = Validators.validatePassword(
      _newPasswordController.text,
    );
    final confirmPasswordError = Validators.validateConfirmPassword(
      _newPasswordController.text,
      _confirmPasswordController.text,
    );

    setState(() {
      _newPasswordError = newPasswordError;
      _confirmPasswordError = confirmPasswordError;
    });

    // Re-authentication check
    final user = FirebaseService.currentUser;
    if (user == null || user.email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not logged in or email not available.'),
          ),
        );
      }
      return;
    }

    // Current password validation for re-authentication
    String? currentPasswordValidation = Validators.validatePassword(
      _currentPasswordController.text,
    );
    if (currentPasswordValidation != null) {
      setState(() {
        _currentPasswordError = currentPasswordValidation;
      });
      return; // Stop if current password is not valid
    } else {
      setState(() {
        _currentPasswordError = null;
      });
    }

    // If any validation fails, stop here
    if (newPasswordError != null ||
        confirmPasswordError != null ||
        currentPasswordValidation != null) {
      return;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!')),
        );
      }

      setState(() {
        _showPasswordFields = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _currentPasswordError = null;
        _newPasswordError = null;
        _confirmPasswordError = null;
      });
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirebaseService.getFriendlyErrorMessage(e))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change password: $e')),
        );
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = FirebaseService.currentUser?.email;
    if (email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not found. Please log in again.'),
          ),
        );
      }
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

  Future<void> _showPremiumUpgrade() async {
    await showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFE5B54), Color(0xFF4754C5)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Use Icon for crown for simplicity, or provide asset if available
                  Image.asset('assets/crown.png', height: 60),
                  const SizedBox(height: 20),
                  Text(
                    'Upgrade to Premium',
                    style: GoogleFonts.lato(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'Get access to exclusive features and content',
                    style: GoogleFonts.lato(fontSize: 16, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.bottomToTop,
                          duration: const Duration(milliseconds: 350),
                          child: PremiumUpgradeScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
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
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Not Now',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _showSuccessPopup() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/tick.png', height: 80),
                  // Add your tick icon asset
                  const SizedBox(height: 20),
                  Text(
                    'Changes saved',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4754C5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4754C5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _deleteAccount() async {
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Delete Account', style: GoogleFonts.lato()),
                content: Text(
                  'Are you sure you want to delete your account? This action cannot be undone.',
                  style: GoogleFonts.lato(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel', style: GoogleFonts.lato()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.lato(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm) {
      try {
        await FirebaseService.deleteAccount();
        await FirebaseService.signOut();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirebaseService.getFriendlyErrorMessage(e))),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete account: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7E7FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF4754C5),
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Profile Settings',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            // No flexibleSpace here
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _isLoading
                  ? Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                  : Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 20,
                      bottom: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar Section
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _showAvatarPickerDialog,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,

                                  ),
                                  child:
                                      _selectedAvatar != null &&
                                              _selectedAvatar!.isNotEmpty
                                          ? ClipOval(
                                            child: Image.asset(
                                              'assets/avatars/$_selectedAvatar.png',
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                          : const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Color(0xFF4754C5),
                                          ),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                _usernameController.text.isNotEmpty
                                    ? _usernameController.text
                                    : 'Set Username',
                                style: GoogleFonts.lato(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4754C5),
                                ),
                              ),
                              const SizedBox(height: 2),
                              TextButton(
                                onPressed: _showAvatarPickerDialog,
                                child: Text(
                                  'Change Avatar',
                                  style: GoogleFonts.lato(
                                    color: const Color(0xFF4754C5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Username Field
                        _buildInputField(
                          label: 'Username',
                          controller: _usernameController,
                          hintText: 'Enter username',
                          errorText: _usernameError,
                          showEditIcon: true,
                          onChanged: (value) {
                            setState(() {
                              _usernameError = null; // Clear error on typing
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // Email Field
                        _buildInputField(
                          label: 'Email',
                          controller: _emailController,
                          hintText: 'Enter email',
                          isReadOnly: true,
                        ),

                        const SizedBox(height: 20),

                        // Password Section
                        Row(
                          children: [
                            Text(
                              'Password',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4754C5),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showPasswordFields = !_showPasswordFields;
                                  // Clear password fields and errors when hiding them
                                  if (!_showPasswordFields) {
                                    _currentPasswordController.clear();
                                    _newPasswordController.clear();
                                    _confirmPasswordController.clear();
                                    _currentPasswordError = null;
                                    _newPasswordError = null;
                                    _confirmPasswordError = null;
                                  }
                                });
                              },
                              child: Text(
                                _showPasswordFields
                                    ? 'Cancel'
                                    : 'Change Password',
                                style: GoogleFonts.lato(
                                  color: const Color(0xFF4754C5),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_showPasswordFields) ...[
                          const SizedBox(height: 10),
                          _buildPasswordField(
                            controller: _currentPasswordController,
                            label: 'Current Password',
                            errorText: _currentPasswordError,
                            onChanged: (value) {
                              setState(() {
                                _currentPasswordError =
                                    null; // Clear error on typing
                              });
                            },
                          ),
                          const SizedBox(height: 5),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _resetPassword,
                              child: Text(
                                "Forgot Password?",
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: const Color(0xFFFE5B54),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildPasswordField(
                            controller: _newPasswordController,
                            label: 'New Password',
                            errorText: _newPasswordError,
                            onChanged: (value) {
                              setState(() {
                                _newPasswordError =
                                    null; // Clear error on typing
                                _confirmPasswordError =
                                    null; // Also clear confirm password error if new password changes
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: 'Confirm New Password',
                            errorText: _confirmPasswordError,
                            onChanged: (value) {
                              setState(() {
                                _confirmPasswordError =
                                    null; // Clear error on typing
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4754C5),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Update Password',
                                style: GoogleFonts.lato(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],

                        // Account Type
                        _buildAccountTypeSection(),

                        const SizedBox(height: 30),

                        // Save Changes Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              bool success = await _updateProfile();
                              if (success && mounted) {
                                _showSuccessPopup();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFE5B54),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Save Changes',
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Delete Account Button
                        Center(
                          child: TextButton(
                            onPressed: _deleteAccount,
                            child: Text(
                              'Delete Account',
                              style: GoogleFonts.lato(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
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
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    String? errorText,
    bool isReadOnly = false,
    bool showEditIcon = false,
    ValueChanged<String>? onChanged, // Added onChanged callback
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4754C5),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.lato(),
            readOnly: isReadOnly,
            onChanged: onChanged,
            // Pass the onChanged callback to TextField
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              hintText: hintText,
              suffixIcon:
                  showEditIcon && !isReadOnly
                      ? const Icon(Icons.edit, color: Color(0xFF4754C5))
                      : null,
            ),
            onTap: () {
              if (label == 'Username') {
                setState(() => _usernameError = null);
              }
            },
          ),
        ),
        // Added error text below the container
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text(
              errorText,
              style: GoogleFonts.lato(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    String? errorText, // Added errorText parameter
    ValueChanged<String>? onChanged, // Added onChanged callback
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56, // Consistent height with other fields
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: !_passwordVisible,
            style: GoogleFonts.lato(),
            onChanged: onChanged,
            // Pass the onChanged callback to TextField
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              hintText: label,
              // Changed from labelText to hintText
              hintStyle: GoogleFonts.lato(color: Colors.grey[600]),
              // Style for hint text
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF4754C5),
                ),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ),
            ),
          ),
        ),
        // Added error text below the container
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text(
              errorText,
              style: GoogleFonts.lato(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildAccountTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Type',
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4754C5),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            leading:
                _isPremium
                    ? Image.asset('assets/crown.png', height: 24)
                    : const Icon(
                      Icons.person_outline,
                      color: Color(0xFF4754C5),
                    ),
            title: Text(
              _isPremium ? 'Premium Account' : 'Free Account',
              style: GoogleFonts.lato(),
            ),
            trailing: TextButton(
              onPressed: _showPremiumUpgrade,
              child: Text(
                _isPremium ? 'Manage' : 'Upgrade',
                style: GoogleFonts.lato(
                  color: const Color(0xFF4754C5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
