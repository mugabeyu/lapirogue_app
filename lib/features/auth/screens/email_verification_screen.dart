import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/reservation_provider.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final String verificationType;
  final String? verificationId;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.verificationType = 'signup',
    this.verificationId,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsRemaining = 600;
  Timer? _timer;
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final ctrl in _otpControllers) {
      ctrl.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get _isReservationVerification =>
      widget.verificationType == 'reservation';

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      _showSnack('Please enter the complete 6-digit code', Colors.red);
      return;
    }

    setState(() => _isVerifying = true);

    try {
      if (_isReservationVerification) {
        final baseUrl = await AuthService().baseUrl;
        final response = await http.post(
          Uri.parse('$baseUrl/api/reservations/verify-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': widget.email,
            'token': widget.verificationId,
            'code': _otpCode,
          }),
        );
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        if (response.statusCode >= 400 || payload['success'] != true) {
          throw Exception(payload['error'] ?? 'Verification failed');
        }
        await ref.read(reservationProvider.notifier).refresh();
      } else {
        await Supabase.instance.client.auth.verifyOTP(
          email: widget.email,
          token: _otpCode,
          type: OtpType.signup,
        );
      }

      if (!mounted) return;

      _timer?.cancel();
      if (_isReservationVerification) {
        context.go('/reservations');
      } else {
        context.pushReplacement('/onboarding');
      }
    } catch (e) {
      _showSnack(
        e.toString().contains('Invalid')
            ? 'Invalid or expired code'
            : 'Verification failed. Try again.',
        Colors.red,
      );
    }

    setState(() => _isVerifying = false);
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);

    try {
      if (_isReservationVerification) {
        final baseUrl = await AuthService().baseUrl;
        final response = await http.post(
          Uri.parse('$baseUrl/api/reservations/resend-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': widget.email,
            'token': widget.verificationId,
          }),
        );
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        if (response.statusCode >= 400 || payload['success'] != true) {
          throw Exception(payload['error'] ?? 'Failed to resend code');
        }
      } else {
        await Supabase.instance.client.auth.resend(
          email: widget.email,
          type: OtpType.signup,
        );
      }
      setState(() => _secondsRemaining = 900);
      _startTimer();
      _showSnack('New code sent to your email', AppColors.statusConfirmed);
    } catch (e) {
      _showSnack('Failed to resend code', Colors.red);
    }

    setState(() => _isResending = false);
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: AppColors.oceanBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread,
                size: 40,
                color: AppColors.goldAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isReservationVerification
                  ? 'Confirm your reservation'
                  : 'Check your email',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _isReservationVerification
                  ? 'We sent a 6-digit code to\n${widget.email}\nto confirm your room reservation.'
                  : 'We sent a 6-digit code to\n${widget.email}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Form(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.oceanBlue,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isReservationVerification
                            ? 'Confirm Reservation'
                            : 'Verify & Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Code expires in $_formattedTime',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isResending || _secondsRemaining > 0
                  ? null
                  : _resendOtp,
              child: _isResending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _secondsRemaining > 0
                          ? 'Resend code in $_formattedTime'
                          : 'Resend code',
                      style: TextStyle(
                        color: _secondsRemaining > 0
                            ? Colors.grey
                            : AppColors.oceanBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please check your inbox and spam folder for the verification code.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
}
