import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../core/widgets/otp_input_row.dart';
import '../../../core/widgets/result_overlay.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/reservation_provider.dart';
import '../../../core/theme/app_typography.dart';

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
      _showSnack('Please enter the complete 6-digit code', AppColors.statusCancelled);
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
          throw Exception(
            payload['error'] ?? 'Reservation confirmation failed',
          );
        }
        await ref.read(reservationProvider.notifier).refresh();

        if (!mounted) return;
        _timer?.cancel();
        final data = payload['data'] as Map<String, dynamic>?;
        await showResultOverlay(
          context,
          success: true,
          title: 'Reservation confirmed successfully',
          message: 'We\'ve locked in your booking. Taking you to your confirmation now.',
        );
        if (!mounted) return;
        context.pushReplacement(
          '/booking-confirmation',
          extra: {
            'reservationId': data?['reservationId'] as String? ?? '',
            'checkIn': data?['checkIn'] as String? ?? '',
            'checkOut': data?['checkOut'] as String? ?? '',
          },
        );
        return;
      }

      await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: _otpCode,
        type: OtpType.signup,
      );
      await ref.read(authStateProvider.notifier).refreshGuest();
      await ref.read(reservationProvider.notifier).refresh();

      if (!mounted) return;
      _timer?.cancel();
      await showResultOverlay(
        context,
        success: true,
        title: 'Email verified successfully',
        message: 'Welcome to La Pirogue! Taking you to your home screen.',
      );
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      _showSnack(friendlyAuthError(e), AppColors.statusCancelled);
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
      _showSnack(friendlyAuthError(e), AppColors.statusCancelled);
    }

    setState(() => _isResending = false);
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Verify Email',
      child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread,
                  size: 42,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isReservationVerification
                    ? 'Confirm your reservation'
                    : 'Check your email',
                style: AppTypography.heading.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _isReservationVerification
                    ? 'We sent a 6-digit code to\n${widget.email}\nto confirm your room reservation.'
                    : 'We sent a 6-digit code to\n${widget.email}',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Form(
                child: OtpInputRow(controllers: _otpControllers, focusNodes: _focusNodes),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                    elevation: 0,
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
                          style: AppTypography.cardTitle,
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Code expires in $_formattedTime',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
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
                        style: AppTypography.bodyMedium.copyWith(color: _secondsRemaining > 0
                              ? AppColors.textTertiary
                              : AppColors.primary, fontWeight: FontWeight.w700),
                      ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please check your inbox and spam folder for the verification code.',
                        style: AppTypography.small.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}
