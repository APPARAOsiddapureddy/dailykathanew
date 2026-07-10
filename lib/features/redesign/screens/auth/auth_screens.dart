import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/config.dart';
import '../../data/api_service.dart';
import '../../data/mock_data.dart';
import '../legal/terms_screen.dart';
import '../main/main_shell.dart';
import '../onboarding/language_screen.dart';

/// Shared by both the auto-verification path (Android instant sign-in) and
/// the manual OTP-entry path: signs in with Firebase, exchanges the
/// resulting ID token for our own app session, then routes onward.
Future<void> _completePhoneSignIn(
  BuildContext context, {
  required PhoneAuthCredential credential,
  required bool needsProfile,
}) async {
  final userCredential = await FirebaseAuth.instance.signInWithCredential(
    credential,
  );
  final user = userCredential.user;
  if (user == null) throw Exception('Firebase sign-in returned no user');

  final idToken = await user.getIdToken();
  if (idToken == null) throw Exception('Could not obtain sign-in token');

  if (!context.mounted) return;
  final state = context.read<AppState>();
  await state.loginWithFirebaseToken(user.phoneNumber ?? '', idToken);

  if (!context.mounted) return;
  if (needsProfile) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => NameScreen(phone: user.phoneNumber ?? ''),
      ),
      (route) => false,
    );
  } else {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }
}

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isChecking = false;
  String? _error;

  Future<void> _submit() async {
    String phone = _controller.text.trim();
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid 10-digit phone number');
      return;
    }

    // Automatically append +91 for standard Indian 10-digit numbers
    if (phone.length == 10 && !phone.startsWith('+')) {
      phone = '+91$phone';
    }

    setState(() {
      _isChecking = true;
      _error = null;
    });

    try {
      final result = await apiService.checkPhone(phone);
      final bool needsProfile = result['needsProfile'] ?? true;

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android may auto-verify without the user typing the code.
          if (!mounted) return;
          try {
            await _completePhoneSignIn(
              context,
              credential: credential,
              needsProfile: needsProfile,
            );
          } catch (e) {
            debugPrint('Auto sign-in error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Phone verification failed: ${e.code} ${e.message}');
          if (mounted) {
            setState(
              () => _error = e.message ?? 'Could not verify this number.',
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpVerificationScreen(
                  phone: phone,
                  needsProfile: needsProfile,
                  verificationId: verificationId,
                  resendToken: resendToken,
                ),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      debugPrint('Phone check / verifyPhoneNumber error: $e');
      if (mounted) {
        setState(() => _error = 'Could not connect. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ॐ',
                style: TextStyle(fontSize: 48, color: Color(0xFFE0701C)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Daily Katha',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Noto Serif Telugu',
                  color: Color(0xFF6B1F22),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  filled: true,
                  fillColor: const Color(0xFFFBEAD2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isChecking ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0701C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
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
}

class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  final bool needsProfile;
  final String verificationId;
  final int? resendToken;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    required this.needsProfile,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _resendCooldownSeconds = 30;

  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;
  int _resendCooldown = _resendCooldownSeconds;
  Timer? _resendTimer;

  // Mutable copies — updated whenever the user requests a resend, since
  // Firebase issues a fresh verificationId (and resend token) each time.
  late String _verificationId = widget.verificationId;
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    _resendToken = widget.resendToken;
    _startResendCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      setState(() => _error = 'Enter the OTP sent to your phone');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );
      await _completePhoneSignIn(
        context,
        credential: credential,
        needsProfile: widget.needsProfile,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('OTP verify error: ${e.code} ${e.message}');
      if (mounted) {
        setState(() => _error = 'Incorrect or expired OTP. Please try again.');
      }
    } catch (e) {
      debugPrint('OTP verify error: $e');
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phone,
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted) return;
          try {
            await _completePhoneSignIn(
              context,
              credential: credential,
              needsProfile: widget.needsProfile,
            );
          } catch (e) {
            debugPrint('Auto sign-in error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('OTP resend failed: ${e.code} ${e.message}');
          if (mounted) {
            setState(
              () => _error = e.message ?? 'Could not resend OTP. Please try again.',
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _resendToken = resendToken;
            });
            _startResendCooldown();
          }
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      debugPrint('OTP resend error: $e');
      if (mounted) {
        setState(() => _error = 'Could not resend OTP. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Verify your number',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Noto Serif Telugu',
                  color: Color(0xFF6B1F22),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the OTP sent to ${widget.phone}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B5A45)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '••••••',
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFFBEAD2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: (_resendCooldown > 0 || _isResending)
                    ? null
                    : _resend,
                child: Text(
                  _resendCooldown > 0
                      ? 'Resend OTP in ${_resendCooldown}s'
                      : (_isResending ? 'Resending...' : 'Resend OTP'),
                  style: const TextStyle(color: Color(0xFFE0701C)),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isVerifying ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0701C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 16,
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
}

class NameScreen extends StatefulWidget {
  final String phone;
  const NameScreen({super.key, required this.phone});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  bool _termsAccepted = false;
  String? _error;

  Future<void> _openPrivacyPolicy() async {
    await launchUrl(
      Uri.parse('${AppConfig.apiBaseUrl}/privacy-policy'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    if (!_termsAccepted) {
      setState(
        () => _error = 'Please accept the Terms & Conditions to continue',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      // By the time we're here, the phone has already been OTP-verified
      // and the app holds a valid session token — this just fills in
      // the display name on the existing account.
      final state = context.read<AppState>();
      final ok = await state.updateProfileName(name);
      if (!ok) throw Exception('Failed to save name');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LanguageScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      if (mounted) {
        setState(() => _error = 'Could not register. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome! 🪔',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Noto Serif Telugu',
                  color: Color(0xFF6B1F22),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  filled: true,
                  fillColor: const Color(0xFFFBEAD2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    activeColor: const Color(0xFFE0701C),
                    onChanged: (value) =>
                        setState(() => _termsAccepted = value ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B5A45),
                          ),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: const TextStyle(
                                color: Color(0xFFE0701C),
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const TermsScreen(),
                                    ),
                                  );
                                },
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: Color(0xFFE0701C),
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _openPrivacyPolicy,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0701C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Start Journey',
                        style: TextStyle(
                          fontSize: 16,
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
}
