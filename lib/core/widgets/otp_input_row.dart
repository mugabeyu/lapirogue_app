import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Shared 6-digit code input used by every OTP/verification screen in the
/// app (signup, reservation confirmation, password reset), so they all look
/// and behave identically instead of each screen hand-rolling its own boxes.
///
/// The box is a plain [Container] with a borderless [TextField] inside rather
/// than a decorated field: `InputDecorator` sizes itself from its content and
/// overrides an outer height, which collapsed the boxes to the height of a
/// single digit. Owning the geometry here keeps every box a predictable
/// rounded square.
class OtpInputRow extends StatefulWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final int length;

  /// Called once every box is filled, so the caller can submit without the
  /// guest having to reach for the button.
  final ValueChanged<String>? onCompleted;

  const OtpInputRow({
    super.key,
    required this.controllers,
    required this.focusNodes,
    this.length = 6,
    this.onCompleted,
  });

  @override
  State<OtpInputRow> createState() => _OtpInputRowState();
}

class _OtpInputRowState extends State<OtpInputRow> {
  @override
  void initState() {
    super.initState();
    // Redraws the focus ring as the guest moves between boxes.
    for (final node in widget.focusNodes) {
      node.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    for (final node in widget.focusNodes) {
      node.removeListener(_onFocusChanged);
    }
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  String get _value => widget.controllers.map((c) => c.text).join();

  void _handleChanged(int index, String value) {
    if (value.length > 1) {
      _distributePaste(index, value);
      return;
    }

    if (value.isNotEmpty && index < widget.length - 1) {
      widget.focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      widget.focusNodes[index - 1].requestFocus();
    }

    _notifyIfComplete();
  }

  /// Lets a guest paste the whole code from their mail app into any box and
  /// have it spread across the rest, instead of only the first digit landing
  /// and the others being silently dropped.
  void _distributePaste(int index, String pasted) {
    final digits = pasted.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    for (var i = 0; i < digits.length; i++) {
      final target = index + i;
      if (target >= widget.length) break;
      widget.controllers[target].text = digits[i];
    }

    final filled = (index + digits.length).clamp(0, widget.length);
    if (filled >= widget.length) {
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      widget.focusNodes[filled].requestFocus();
    }

    _notifyIfComplete();
  }

  void _notifyIfComplete() {
    final code = _value;
    if (code.length == widget.length) {
      FocusManager.instance.primaryFocus?.unfocus();
      widget.onCompleted?.call(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;

        // Sized from the space actually available rather than a fixed width,
        // so six boxes always fit on a narrow phone without clipping.
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final available = maxWidth - gap * (widget.length - 1);
        final boxWidth = (available / widget.length).clamp(38.0, 54.0);
        final boxHeight = boxWidth * 1.18;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                right: index == widget.length - 1 ? 0 : gap,
              ),
              child: _OtpBox(
                width: boxWidth,
                height: boxHeight,
                controller: widget.controllers[index],
                focusNode: widget.focusNodes[index],
                autofocus: index == 0,
                maxLength: widget.length,
                onChanged: (value) => _handleChanged(index, value),
              ),
            );
          }),
        );
      },
    );
  }
}

class _OtpBox extends StatelessWidget {
  final double width;
  final double height;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final int maxLength;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.width,
    required this.height,
    required this.controller,
    required this.focusNode,
    required this.autofocus,
    required this.maxLength,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;
    final isFilled = controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isFocused
              ? AppColors.primary
              : isFilled
                  ? AppColors.borderStrong
                  : AppColors.border,
          width: isFocused ? 2 : 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          // Allows a full pasted code through so it can be spread across the
          // boxes; a single typed character is the normal case.
          LengthLimitingTextInputFormatter(maxLength),
        ],
        // Inter is bundled with the app, so the glyphs are available on the
        // first frame. The previous 'monospace' family resolved to no real
        // font on web and drew typed digits as unreadable fallback glyphs.
        style: AppTypography.code,
        cursorColor: AppColors.primary,
        cursorHeight: AppTypography.code.fontSize,
        showCursor: true,
        decoration: const InputDecoration(
          counterText: '',
          isCollapsed: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
