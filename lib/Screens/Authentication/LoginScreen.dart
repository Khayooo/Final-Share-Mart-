import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fypnewproject/Screens/Admin/AdminPage.dart';
import '../User/HomePage.dart';
import 'RegisterNewUser.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  //State Variables
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

  //backend logic for login
  Future<void> _login() async {
    // Checks if fields are empty.
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields', isError: true);
      return;
    }

    // Checks if email is valid.
    setState(() => _isLoading = true);


    try {
      // Attempt to sign in with the provided email and password.
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check if the user is an admin.
      if (userCredential.user != null && mounted) {
        final userEmail = userCredential.user!.email;
        final isAdmin = userEmail == 'mabdullahkhayoo@gmail.com';

        _showSnackBar(isAdmin ? 'Admin login successful!' : 'Login successful!');

        // Delay for 500 milliseconds before navigating to the appropriate screen.
        await Future.delayed(const Duration(milliseconds: 500));


        if (!mounted) return;

        // Navigate to the appropriate screen based on the user's role.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isAdmin ? const AdminPanelScreen() : const HomePage(),
          ),
        );
      }

    } on FirebaseAuthException catch (e) {
      // Handle authentication errors.
      _showSnackBar('Wrong email or password', isError: true);
    } catch (e) {
      // Handle other errors.
      _showSnackBar('An unexpected error occurred. Please try again.', isError: true);
    } finally {

      if (mounted) setState(() => _isLoading = false);
    }
  }


  // Show a snackbar with the provided message and color.
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // UI started here
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
                          const Icon(Icons.volunteer_activism, size: 60, color: Colors.amber),
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
                            'Login to continue sharing',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: size.height * 0.04),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            hint: 'your@email.com',
                            icon: Icons.email,
                            isPassword: false,
                            size: size,
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: size.height * 0.02),
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _showForgotPasswordDialog(context),
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
                          SizedBox(
                            width: double.infinity,
                            height: isSmallScreen ? 50 : 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
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
                                  : const Text('LOG IN'),
                            ),
                          ),
                          SizedBox(height: size.height * 0.03),
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
                                      builder: (context) => const RegisterNewUser(),
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
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Enter your email',
              hintText: 'your@email.com',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  _showSnackBar('Please enter a valid email address', isError: true);
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  _showSnackBar('Password reset email sent!');
                  Navigator.pop(context);
                } catch (e) {
                  _showSnackBar('Failed to send reset email. Try again later.', isError: true);
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