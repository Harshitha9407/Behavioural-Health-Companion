import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _codeSent = false;
  String? _verificationId;
  String _selectedCountryCode = '+91'; // Default to India

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2E8B82)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Phone Verification',
          style: TextStyle(
            color: Color(0xFF2E8B82),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E8B82).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_android,
                        size: 48,
                        color: Color(0xFF2E8B82),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _codeSent ? 'Verify Your Phone' : 'Enter Phone Number',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A5A54),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _codeSent
                              ? 'Enter the verification code sent to your phone'
                              : 'We\'ll send you a verification code',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
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
                  
                  // Form Container
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (!_codeSent) ...[
                            // Country Code and Phone Number
                            Row(
                              children: [
                                // Country Code Dropdown
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCountryCode,
                                      items: const [
                                        DropdownMenuItem(value: '+1', child: Text('+1 🇺🇸')),
                                        DropdownMenuItem(value: '+44', child: Text('+44 🇬🇧')),
                                        DropdownMenuItem(value: '+91', child: Text('+91 🇮🇳')),
                                        DropdownMenuItem(value: '+86', child: Text('+86 🇨🇳')),
                                        DropdownMenuItem(value: '+81', child: Text('+81 🇯🇵')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCountryCode = value!;
                                        });
                                      },
                                      style: const TextStyle(
                                        color: Color(0xFF2E8B82),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Phone Number Field
                                Expanded(
                                  child: CustomTextField(
                                    labelText: 'Phone Number',
                                    hintText: 'Enter phone number',
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: const Icon(Icons.phone, color: Color(0xFF2E8B82)),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter phone number';
                                      }
                                      if (value.length < 10) {
                                        return 'Enter valid phone number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Send OTP Button
                            CustomButton(
                              text: 'Send Verification Code',
                              onPressed: authService.isLoading ? null : _sendOTP,
                              isLoading: authService.isLoading,
                            ),
                          ] else ...[
                            // OTP Input Field
                            CustomTextField(
                              labelText: 'Verification Code',
                              hintText: 'Enter 6-digit code',
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF2E8B82)),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter verification code';
                                }
                                if (value.length != 6) {
                                  return 'Code must be 6 digits';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Verify Button
                            CustomButton(
                              text: 'Verify & Sign In',
                              onPressed: authService.isLoading ? null : _verifyOTP,
                              isLoading: authService.isLoading,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Resend Code
                            Center(
                              child: TextButton(
                                onPressed: _sendOTP,
                                child: const Text(
                                  'Resend Code',
                                  style: TextStyle(
                                    color: Color(0xFF2E8B82),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  if (!_codeSent) ...[
                    const SizedBox(height: 32),
                    
                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E8B82).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2E8B82).withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You will receive a 6-digit verification code via SMS',
                              style: TextStyle(
                                color: Color(0xFF2E8B82),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _sendOTP() async {
    if (!_codeSent && !_formKey.currentState!.validate()) {
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    authService.clearError();
    
    String phoneNumber = _selectedCountryCode + _phoneController.text.trim();
    
    await authService.signInWithPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code sent to $phoneNumber'),
            backgroundColor: const Color(0xFF2E8B82),
          ),
        );
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate() || _verificationId == null) {
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    authService.clearError();
    
    bool success = await authService.verifyPhoneNumberWithOTP(
      verificationId: _verificationId!,
      otpCode: _otpController.text.trim(),
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone verified successfully!'),
          backgroundColor: Color(0xFF2E8B82),
        ),
      );
    }
  }
}