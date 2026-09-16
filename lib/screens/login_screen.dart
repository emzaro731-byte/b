import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _signUp = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _emailAuth() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      _show('Enter your email and password.');
      return;
    }
    if (password.length < 6) {
      _show('Password must be at least 6 characters.');
      return;
    }
    setState(() => _loading = true);
    try {
      if (_signUp) {
        await _authService.signUpWithEmail(email, password);
        _show('Account created successfully.');
      } else {
        await _authService.signInWithEmail(email, password);
      }
    } on FirebaseAuthException catch (e) {
      _show(e.message ?? 'Authentication failed.');
    } catch (_) {
      _show('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _loading = true);
    try {
      await _authService.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      _show(e.message ?? 'Google sign-in failed.');
    } catch (_) {
      _show('Google sign-in was cancelled or failed.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      _show('Enter your email first.');
      return;
    }
    try {
      await _authService.resetPassword(email);
      _show('Password reset email sent.');
    } on FirebaseAuthException catch (e) {
      _show(e.message ?? 'Could not send reset email.');
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, size: 72),
                const SizedBox(height: 20),
                Text(
                  _signUp ? 'Create your Veylola account' : 'Welcome to Veylola AI',
                  style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(_signUp ? 'Sign up with email or Google' : 'Sign in to continue'),
                const SizedBox(height: 28),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (!_signUp)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _loading ? null : _forgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  )
                else
                  const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _emailAuth,
                    child: Text(_loading ? 'Please wait...' : (_signUp ? 'Create account' : 'Sign in with email')),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _googleLogin,
                    icon: const Icon(Icons.g_mobiledata, size: 30),
                    label: const Text('Continue with Google'),
                  ),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: _loading ? null : () => setState(() => _signUp = !_signUp),
                  child: Text(_signUp ? 'Already have an account? Sign in' : 'New to Veylola? Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
