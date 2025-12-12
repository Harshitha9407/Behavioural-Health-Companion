import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class TokenScreen extends StatefulWidget {
  const TokenScreen({Key? key}) : super(key: key);

  @override
  _TokenScreenState createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  String _token = 'No token yet';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Automatically get token when screen opens
    printFirebaseToken();
  }

  Future<void> printFirebaseToken() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? token = await user.getIdToken();
        print('🔑 FIREBASE TOKEN: $token');
        print('📋 Copy this token for Postman testing!');
        
        setState(() {
          _token = token ?? 'Token is null';
          _isLoading = false;
        });
      } else {
        print('❌ No user logged in!');
        setState(() {
          _token = 'No user logged in!';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _token = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_token != 'No token yet' && _token != 'No user logged in!' && !_token.startsWith('Error:')) {
      Clipboard.setData(ClipboardData(text: _token));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Token copied to clipboard!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        title: const Text('Firebase Token'),
        backgroundColor: const Color(0xFF2E8B82),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.key,
                size: 80,
                color: Colors.orange[700],
              ),
            ),

            const SizedBox(height: 24),

            // Title
            const Text(
              'Firebase Authentication Token',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A5A54),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Use this token for testing backend APIs in Postman',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Get Token Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : printFirebaseToken,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isLoading ? 'Getting Token...' : 'Refresh Token'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B82),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 24),

            // Token Display
            if (_token != 'No token yet') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _token.startsWith('Error') || _token == 'No user logged in!'
                              ? Icons.error_outline
                              : Icons.check_circle_outline,
                          color: _token.startsWith('Error') || _token == 'No user logged in!'
                              ? Colors.red
                              : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _token.startsWith('Error') || _token == 'No user logged in!'
                              ? 'Error'
                              : 'Token Ready',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _token.startsWith('Error') || _token == 'No user logged in!'
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      _token,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Copy Button
              if (!_token.startsWith('Error') && _token != 'No user logged in!') ...[
                ElevatedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Token'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 32),

            // Instructions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'How to use in Postman:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionStep('1', 'Copy the token above'),
                  _buildInstructionStep('2', 'Open Postman'),
                  _buildInstructionStep('3', 'Go to Headers tab'),
                  _buildInstructionStep('4', 'Add new header:\n   Key: Authorization\n   Value: Bearer [paste token]'),
                  _buildInstructionStep('5', 'Send your API request'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Check Console Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.terminal, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Token also printed in console/debug output',
                      style: TextStyle(
                        color: Colors.green[900],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}