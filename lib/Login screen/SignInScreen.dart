import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fypnewproject/admin%20panel/admin_panel.dart';
import '../HomePage.dart';
import 'SignUpScreen.dart';


class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    timeDilation = 1.5; // Remove or set to 1.0 for production

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.fastOutSlowIn,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Enhanced email validation function
  bool _isValidEmail(String email) {
    // Basic email format validation
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegExp.hasMatch(email)) {
      return false;
    }

    // Check if it's a Gmail address (you can modify this to allow other providers)
    final gmailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@gmail\.com$',
      caseSensitive: false,
    );

    return gmailRegExp.hasMatch(email);
  }

  // Function to validate email format and show appropriate error
  String? _validateEmailInput(String email) {
    if (email.isEmpty) {
      return 'Please enter your email address';
    }

    if (!email.contains('@')) {
      return 'Please enter a valid email address';
    }

    if (!_isValidEmail(email)) {
      return 'Please enter a valid Gmail address (e.g., user@gmail.com)';
    }

    return null; // No error
  }

  Future<void> _signIn() async {
    // Validate email format first
    final emailError = _validateEmailInput(_emailController.text.trim());
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters long'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null && mounted) {
        // Verify email is verified (optional additional check)
        if (!userCredential.user!.emailVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please verify your email address first'),
              backgroundColor: Colors.orange,
            ),
          );

          // Optionally send verification email again
          await userCredential.user!.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent. Please check your inbox.'),
              backgroundColor: Colors.blue,
            ),
          );
          return;
        }

        // Check if the user is admin
        final userEmail = userCredential.user!.email;
        final isAdmin = userEmail == 'mabdullahkhayoo@gmail.com';

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAdmin ? 'Admin login successful!' : 'Sign in successful!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to HomePage after a brief delay
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          if (isAdmin) {
            // Navigate to admin panel for admin user
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminPanel()),
            );
          } else {
            // Navigate to HomePage for regular users
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid Gmail address';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found for this email. Please check your email or sign up.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Sign in failed: ${e.message ?? 'Please try again'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.cyan.shade400,
              Colors.teal.shade600,
              Colors.blue.shade800,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Card(
                    elevation: 16,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header with logo
                          const Icon(
                            Icons.volunteer_activism,
                            size: 60,
                            color: Colors.amber,
                          ),
                          SizedBox(height: size.height * 0.02),
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 28 : 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          SizedBox(height: size.height * 0.01),
                          Text(
                            'Sign in to continue sharing',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: size.height * 0.04),

                          // Email Field
                          _buildTextField(
                            controller: _emailController,
                            label: 'Gmail Address',
                            hint: 'your@gmail.com',
                            icon: Icons.email,
                            isPassword: false,
                            size: size,
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: size.height * 0.02),

                          // Password Field
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Enter your password',
                            icon: Icons.lock,
                            isPassword: true,
                            size: size,
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: size.height * 0.02),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                _showForgotPasswordDialog(context);
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: isSmallScreen ? 14 : 16,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.03),

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: isSmallScreen ? 50 : 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 4,
                                textStyle: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              )
                                  : const Text('SIGN IN'),
                            ),
                          ),
                          SizedBox(height: size.height * 0.03),

                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: isSmallScreen ? 14 : 16,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SignUpScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isPassword,
    required Size size,
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: size.height * 0.01),
        TextField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blue.shade700),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade600,
              ),
              onPressed: () {
                setState(() => _isPasswordVisible = !_isPasswordVisible);
              },
            )
                : null,
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 14 : 16,
              horizontal: 16,
            ),
          ),
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
          keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
          onChanged: !isPassword ? (value) {
            // Real-time validation for email field
            if (value.isNotEmpty && !_isValidEmail(value)) {
              // You can add visual feedback here if needed
            }
          } : null,
        ),
      ],
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your Gmail address to receive a password reset link.'),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Gmail Address',
                  hintText: 'your@gmail.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                final emailError = _validateEmailInput(email);

                if (emailError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(emailError),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent! Check your Gmail inbox.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  }
                } on FirebaseAuthException catch (e) {
                  if (mounted) {
                    String errorMessage;
                    switch (e.code) {
                      case 'user-not-found':
                        errorMessage = 'No account found for this email address.';
                        break;
                      case 'invalid-email':
                        errorMessage = 'Please enter a valid Gmail address.';
                        break;
                      default:
                        errorMessage = 'Error: ${e.message ?? 'Please try again'}';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('An error occurred: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
  }
}