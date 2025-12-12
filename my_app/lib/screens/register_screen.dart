import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/validators.dart';
import 'phone_auth_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _showEmailForm = false;
  
  late AnimationController _animationController;
  late AnimationController _formAnimationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _formSlideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _formSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _formAnimationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    _formAnimationController.dispose();
    super.dispose();
  }

  void _toggleEmailForm() {
    setState(() {
      _showEmailForm = !_showEmailForm;
    });
    if (_showEmailForm) {
      _formAnimationController.forward();
    } else {
      _formAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      body: SafeArea(
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: size.height * 0.06),
                          
                          // Back Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2E8B82)),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          
                          const SizedBox(height: 32),

                          // App Logo and Header
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF2E8B82).withOpacity(0.15),
                                    const Color(0xFF4CAF50).withOpacity(0.15),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2E8B82).withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.favorite_border_rounded,
                                size: 64,
                                color: Color(0xFF2E8B82),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Header Text
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Join Your Health Journey',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A5A54),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your account to start tracking your health and wellbeing',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // Error Message
                          if (authService.errorMessage != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red[600]),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      authService.errorMessage!,
                                      style: TextStyle(color: Colors.red[800]),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Social Sign Up Options
                          if (!_showEmailForm) ...[
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Google Sign Up Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: OutlinedButton(
                                      onPressed: authService.isLoading ? null : _handleGoogleSignUp,
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        side: BorderSide(color: Colors.grey[300]!),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: const BoxDecoration(
                                              image: DecorationImage(
                                                image: NetworkImage('https://developers.google.com/identity/images/g-logo.png'),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          const Text(
                                            'Continue with Google',
                                            style: TextStyle(
                                              color: Color(0xFF1A5A54),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Phone Sign Up Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: OutlinedButton(
                                      onPressed: authService.isLoading ? null : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const PhoneAuthScreen()),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        side: BorderSide(color: Colors.grey[300]!),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            color: Color(0xFF2E8B82),
                                            size: 24,
                                          ),
                                          SizedBox(width: 16),
                                          Text(
                                            'Continue with Phone',
                                            style: TextStyle(
                                              color: Color(0xFF1A5A54),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  // Divider
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: Colors.grey[300],
                                          thickness: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'OR',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: Colors.grey[300],
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // Email Sign Up Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _toggleEmailForm,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2E8B82),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.email_outlined, size: 24),
                                          SizedBox(width: 16),
                                          Text(
                                            'Continue with Email',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Email Registration Form
                          if (_showEmailForm)
                            AnimatedBuilder(
                              animation: _formAnimationController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _formSlideAnimation.value),
                                  child: Opacity(
                                    opacity: _formAnimationController.value,
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 20,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          children: [
                                            // Back to options button
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: TextButton.icon(
                                                onPressed: _toggleEmailForm,
                                                icon: const Icon(Icons.arrow_back, color: Color(0xFF2E8B82)),
                                                label: const Text(
                                                  'Other options',
                                                  style: TextStyle(
                                                    color: Color(0xFF2E8B82),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 16),

                                            // Full Name Field
                                            CustomTextField(
                                              labelText: 'Full Name',
                                              hintText: 'Enter your full name',
                                              controller: _nameController,
                                              prefixIcon: const Icon(Icons.person_outlined, color: Color(0xFF2E8B82)),
                                              validator: Validators.validateName,
                                            ),
                                            
                                            const SizedBox(height: 20),
                                            
                                            // Email Field
                                            CustomTextField(
                                              labelText: 'Email Address',
                                              hintText: 'Enter your email',
                                              controller: _emailController,
                                              keyboardType: TextInputType.emailAddress,
                                              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF2E8B82)),
                                              validator: Validators.validateEmail,
                                            ),
                                            
                                            const SizedBox(height: 20),
                                            
                                            // Password Field
                                            CustomTextField(
                                              labelText: 'Password',
                                              hintText: 'Create a password',
                                              controller: _passwordController,
                                              obscureText: _obscurePassword,
                                              prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF2E8B82)),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                                  color: Colors.grey[600],
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _obscurePassword = !_obscurePassword;
                                                  });
                                                },
                                              ),
                                              validator: Validators.validatePassword,
                                            ),
                                            
                                            const SizedBox(height: 20),
                                            
                                            // Confirm Password Field
                                            CustomTextField(
                                              labelText: 'Confirm Password',
                                              hintText: 'Confirm your password',
                                              controller: _confirmPasswordController,
                                              obscureText: _obscureConfirmPassword,
                                              prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF2E8B82)),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                                  color: Colors.grey[600],
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                                  });
                                                },
                                              ),
                                              validator: (value) => Validators.validateConfirmPassword(
                                                value, 
                                                _passwordController.text,
                                              ),
                                            ),
                                            
                                            const SizedBox(height: 24),
                                            
                                            // Terms and Conditions Checkbox
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey[200]!),
                                              ),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Checkbox(
                                                    value: _acceptTerms,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _acceptTerms = value ?? false;
                                                      });
                                                    },
                                                    activeColor: const Color(0xFF2E8B82),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          _acceptTerms = !_acceptTerms;
                                                        });
                                                      },
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(top: 12),
                                                        child: RichText(
                                                          text: TextSpan(
                                                            style: TextStyle(
                                                              color: Colors.grey[700],
                                                              fontSize: 14,
                                                              height: 1.4,
                                                            ),
                                                            children: const [
                                                              TextSpan(text: 'I agree to the '),
                                                              TextSpan(
                                                                text: 'Terms of Service',
                                                                style: TextStyle(
                                                                  color: Color(0xFF2E8B82),
                                                                  fontWeight: FontWeight.w600,
                                                                  decoration: TextDecoration.underline,
                                                                ),
                                                              ),
                                                              TextSpan(text: ' and '),
                                                              TextSpan(
                                                                text: 'Privacy Policy',
                                                                style: TextStyle(
                                                                  color: Color(0xFF2E8B82),
                                                                  fontWeight: FontWeight.w600,
                                                                  decoration: TextDecoration.underline,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            
                                            const SizedBox(height: 32),
                                            
                                            // Register Button
                                            CustomButton(
                                              text: 'Create Account',
                                              onPressed: (authService.isLoading || !_acceptTerms) 
                                                  ? null 
                                                  : _handleEmailRegister,
                                              isLoading: authService.isLoading,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          
                          const SizedBox(height: 48),
                          
                          // Already have account link
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E8B82),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignUp() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.clearError();

    bool success = await authService.signInWithGoogle();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully signed up with Google!'),
          backgroundColor: Color(0xFF2E8B82),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleEmailRegister() async {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.clearError();
      
      bool success = await authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _nameController.text.trim(),
        phoneNumber: null, // Phone number not collected in email form
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please verify your email.'),
            backgroundColor: Color(0xFF2E8B82),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }
}