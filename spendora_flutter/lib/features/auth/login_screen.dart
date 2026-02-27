import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../expenses/expense_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isRegisterMode = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) {
      return;
    }

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String fullName = _fullNameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Email and password are required.';
      });
      return;
    }

    if (_isRegisterMode && fullName.isEmpty) {
      setState(() {
        _error = 'Full name is required.';
      });
      return;
    }

    if (_isRegisterMode && password.length < 8) {
      setState(() {
        _error = 'Password must be at least 8 characters.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final AuthResult result = _isRegisterMode
        ? await _authService.register(
            email: email,
            password: password,
            fullName: fullName,
          )
        : await _authService.login(email: email, password: password);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (!result.success) {
      setState(() {
        _error = result.errorMessage ?? 'Authentication failed.';
      });
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ExpenseScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRegisterMode ? 'Create Account' : 'Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_isRegisterMode) ...<Widget>[
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: _isRegisterMode
                    ? 'Password (min 8 chars)'
                    : 'Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            CustomButton(
              label: _isLoading
                  ? (_isRegisterMode ? 'Creating...' : 'Signing In...')
                  : (_isRegisterMode ? 'Create Account' : 'Login'),
              onPressed: _isLoading ? null : _submit,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isRegisterMode = !_isRegisterMode;
                        _error = null;
                      });
                    },
              child: Text(
                _isRegisterMode
                    ? 'Already have an account? Login'
                    : 'No account yet? Create one',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
