import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../core/widgets/otp_input_row.dart';
import '../../../core/widgets/result_overlay.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/theme/app_typography.dart';

/// Password reset step 2: the guest first enters the 6-digit code emailed to
/// them (see the "Reset password" Supabase email template, which sends
/// {{ .Token }}). The code is verified on its own before anything else is
/// shown - only once it's confirmed correct do we reveal the new-password
/// card. An incorrect code keeps the guest on the code step with an error
/// and a resend option, instead of letting them type a password that will
/// never be saved.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? email;

  const ResetPasswordScreen({
    super.key,
    this.email,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Whether the OTP has been confirmed correct yet. The new-password card
  // only renders once this flips to true.
  bool _codeVerified = false;

  bool _isVerifying = false;
  bool _isResetting = false;
  bool _isResending = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  /// Captured while the widget is still mounted, because `dispose` needs it
  /// after `ref` has stopped being usable.
  late final AuthNotifier _authNotifier;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email ?? '';
    _authNotifier = ref.read(authStateProvider.notifier);
  }

  /// Set once the password has actually been changed, so leaving the screen
  /// afterwards is not mistaken for abandoning the flow.
  bool _completed = false;

  @override
  void dispose() {
    // Leaving with a verified code but no new password would otherwise strand
    // a usable session on the device, which the next launch would treat as a
    // normal sign-in. Drop it.
    if (!_completed) {
      // Read the notifier directly: `ref` is not safe to use once dispose has
      // started, and this must run regardless of how the screen was left.
      unawaited(_authNotifier.cancelPasswordRecovery());
    }

    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final n in _otpFocusNodes) {
      n.dispose();
    }
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (!_codeFormKey.currentState!.validate()) return;

    if (_otpCode.length != 6) {
      setState(() => _errorMessage = 'Enter the 6-digit code from your email');
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Email is required');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      // Verifying the recovery OTP establishes a real session, which
      // updateUser() needs below. Flag the recovery first so that session is
      // held at "resetting password" instead of being reported as a completed
      // sign-in — otherwise a correct code alone would open the whole app.
      await ref.read(authStateProvider.notifier).beginPasswordRecovery();

      await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: _otpCode,
        type: OtpType.recovery,
      );

      if (!mounted) return;
      setState(() => _codeVerified = true);
    } catch (e) {
      // A failed verification leaves no usable session, so drop the hold.
      await ref.read(authStateProvider.notifier).cancelPasswordRecovery();
      if (!mounted) return;
      // Incorrect/expired code: stay on this step, surface the error, and
      // let the guest request a fresh code instead of falling through.
      setState(() => _errorMessage = friendlyAuthError(e));
    }

    if (mounted) setState(() => _isVerifying = false);
  }

  Future<void> _resetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isResetting = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      // The reset is complete, so release the hold and sign out — the guest
      // logs back in with the new password, matching the web app.
      _completed = true;
      await ref.read(authStateProvider.notifier).endPasswordRecovery();
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;
      await showResultOverlay(
        context,
        success: true,
        title: 'Password reset successfully',
        message: 'Please sign in with your new password.',
      );
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      setState(() => _errorMessage = friendlyAuthError(e));
    }

    if (mounted) setState(() => _isResetting = false);
  }

  Future<void> _resendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Enter your email to resend the code');
      return;
    }

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      // Clear any stale digits so the guest doesn't accidentally submit the
      // old (now invalid) code.
      for (final c in _otpControllers) {
        c.clear();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New code sent to your email'),
          backgroundColor: AppColors.statusConfirmed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to resend code'),
          backgroundColor: AppColors.statusCancelled,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (mounted) setState(() => _isResending = false);
  }

  Widget _buildErrorBanner() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusCancelledBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.statusCancelled.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.statusCancelled, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.captionMedium.copyWith(color: AppColors.statusCancelled),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep() {
    return Form(
      key: _codeFormKey,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySoft,
            ),
            child: const Icon(Icons.mark_email_unread, color: AppColors.primary, size: 34),
          ),
          const SizedBox(height: 20),
          Text(
            'Enter Verification Code',
            style: AppTypography.heading.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a 6-digit code to your email. Enter it below to continue.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _buildErrorBanner(),
          if (widget.email == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
            ),
          OtpInputRow(controllers: _otpControllers, focusNodes: _otpFocusNodes),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isResending ? null : _resendCode,
            child: _isResending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Resend code', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Text('Verify Code', style: AppTypography.cardTitle),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Back to Sign In', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySoft,
            ),
            child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 34),
          ),
          const SizedBox(height: 20),
          Text(
            'Create New Password',
            style: AppTypography.heading.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Code verified. Choose a new password for your account.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _buildErrorBanner(),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 8) return 'Password must be at least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please confirm your password';
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isResetting ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              ),
              child: _isResetting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Text('Reset Password', style: AppTypography.cardTitle),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Reset Password',
      child: _codeVerified ? _buildNewPasswordStep() : _buildCodeStep(),
    );
  }
}
