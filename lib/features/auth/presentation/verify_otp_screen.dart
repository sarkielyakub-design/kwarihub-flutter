import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  ConsumerState<VerifyOtpScreen> createState() =>
      _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  static const Color primaryBlue = Color(0xFF0D5CC7);
  static const Color darkBlue = Color(0xFF102F4F);

  final _otpController = TextEditingController();

  bool _isLoading = false;

  String? _email;

  @override
  void initState() {
    super.initState();

    // Get email from GoRouter extra.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;

      if (extra is String && extra.isNotEmpty) {
        setState(() {
          _email = extra;
        });
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    final code = _otpController.text.trim();

    if (_email == null || _email!.isEmpty) {
      _showError(
        'Email address is missing. Please register again.',
      );
      return;
    }

    if (code.length != 6) {
      _showError(
        'Please enter the 6-digit verification code.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authApi = ref.read(authApiProvider);

      final response = await authApi.verifyOtp(
        email: _email!,
        code: code,
      );

      debugPrint(
        'OTP VERIFICATION SUCCESS: $response',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // ========================================================
      // VERIFIED SUCCESSFULLY
      // ========================================================

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email verified successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.go('/home');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final message = e
          .toString()
          .replaceFirst('Exception: ', '');

      _showError(message);
    }
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<void> _resendCode() async {
    if (_email == null || _email!.isEmpty) {
      _showError(
        'Email address is missing. Please register again.',
      );
      return;
    }

    _showMessage(
      'Resend OTP endpoint will be connected next.',
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryBlue,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final email = _email;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: darkBlue,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              // ==================================================
              // ICON
              // ==================================================

              Center(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 40,
                    color: primaryBlue,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // TITLE
              // ==================================================

              Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: darkBlue,
                    ),
              ),

              const SizedBox(height: 12),

              Text(
                'Enter the 6-digit verification code sent to your email.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // EMAIL
              // ==================================================

              if (email != null)
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: primaryBlue,
                  ),
                ),

              const SizedBox(height: 35),

              // ==================================================
              // OTP FIELD
              // ==================================================

              TextField(
                controller: _otpController,
                maxLength: 6,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,

                enabled: !_isLoading,

                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 12,
                  color: darkBlue,
                ),

                onChanged: (value) {
                  // Only allow 6 digits.
                  if (value.length > 6) {
                    _otpController.text =
                        value.substring(0, 6);

                    _otpController.selection =
                        TextSelection.fromPosition(
                      TextPosition(
                        offset:
                            _otpController.text.length,
                      ),
                    );
                  }
                },

                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',

                  hintStyle: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 12,
                  ),

                  filled: true,
                  fillColor:
                      const Color(0xFFFAFCFF),

                  contentPadding:
                      const EdgeInsets.symmetric(
                    vertical: 18,
                  ),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFDDE6F0),
                    ),
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFDDE6F0),
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: primaryBlue,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // VERIFY BUTTON
              // ==================================================

              SizedBox(
                height: 56,
                child: PrimaryButton(
                  label: _isLoading
                      ? 'Verifying...'
                      : 'Verify Email',
                  onPressed:
                      _isLoading ? () {} : _verifyOtp,
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // RESEND
              // ==================================================

              Center(
                child: TextButton(
                  onPressed:
                      _isLoading ? null : _resendCode,
                  child: const Text(
                    'Resend Code',
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // HELP TEXT
              // ==================================================

              Center(
                child: Text(
                  'Didn’t receive the code? Check your spam folder.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
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