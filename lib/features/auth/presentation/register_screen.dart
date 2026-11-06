import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

const Color primaryBlue = Color(0xFF0D5CC7);
const Color darkBlue = Color(0xFF102F4F);
const Color borderColor = Color(0xFFDDE6F0);

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {

  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    // Validate fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate terms
    if (!_acceptTerms) {
      _showError(
        'Please accept the Terms and Conditions.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authApi = ref.read(authApiProvider);

      final firstName =
          _firstNameController.text.trim();

      final lastName =
          _lastNameController.text.trim();

      final username =
          _usernameController.text.trim();

      final email =
          _emailController.text.trim().toLowerCase();

      final phone =
          _phoneController.text.trim();

      final password =
          _passwordController.text;

      // ========================================================
      // REAL BACKEND REQUEST
      // ========================================================

      final response = await authApi.register(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        phone: phone,
        password: password,
      );

      debugPrint(
        'REGISTER SUCCESS: $response',
      );

      if (!mounted) return;

      // ========================================================
      // REGISTRATION SUCCESS
      // ========================================================

      setState(() {
        _isLoading = false;
      });

      // Pass email to OTP screen.
      //
      // Your OTP screen can read:
      //
      // state.extra as String
      //
      // from GoRouter.
      context.push(
        '/verify-otp',
        extra: email,
      );
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
  // ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                24,
                16,
                24,
                30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // TOP BAR
                  // ==================================================

                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/login');
                          }
                        },
                        style: IconButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFF4F8FF),
                          foregroundColor: darkBlue,
                          fixedSize: const Size(44, 44),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          size: 22,
                        ),
                      ),

                      const Spacer(),

                      Image.asset(
                        'assets/images/kwarihub_logo.png',
                        width: 95,
                        height: 42,
                        fit: BoxFit.contain,
                      ),

                      const Spacer(),

                      const SizedBox(
                        width: 44,
                        height: 44,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // TITLE
                  // ==================================================

                  const Center(
                    child: Column(
                      children: [
                        Text(
                          'Create Your Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            color: darkBlue,
                          ),
                        ),
                        SizedBox(height: 9),
                        Text(
                          'Join KwariHub and discover amazing textiles.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // FIRST + LAST NAME
                  // ==================================================

                  Row(
                    children: [
                      Expanded(
                        child: _RegisterField(
                          controller:
                              _firstNameController,
                          label: 'First Name',
                          hint: 'First name',
                          icon:
                              Icons.person_outline_rounded,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Required';
                            }

                            return null;
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _RegisterField(
                          controller:
                              _lastNameController,
                          label: 'Last Name',
                          hint: 'Last name',
                          icon:
                              Icons.person_outline_rounded,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Required';
                            }

                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // USERNAME
                  // ==================================================

                  _RegisterField(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'Choose a username',
                    icon: Icons.alternate_email_rounded,
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Username is required';
                      }

                      if (value.trim().length < 3) {
                        return 'At least 3 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // EMAIL
                  // ==================================================

                  _RegisterField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'you@example.com',
                    icon: Icons.email_outlined,
                    keyboardType:
                        TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Email is required';
                      }

                      final emailRegex = RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      );

                      if (!emailRegex.hasMatch(
                        value.trim(),
                      )) {
                        return 'Enter a valid email';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // PHONE
                  // ==================================================

                  _RegisterField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: '080 1234 5678',
                    icon: Icons.phone_outlined,
                    keyboardType:
                        TextInputType.phone,
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Phone number is required';
                      }

                      if (value.trim().length < 10) {
                        return 'Enter a valid phone number';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // PASSWORD
                  // ==================================================

                  _RegisterField(
                    controller:
                        _passwordController,
                    label: 'Password',
                    hint: 'Create a password',
                    icon:
                        Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey.shade500,
                        size: 21,
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Password is required';
                      }

                      if (value.length < 8) {
                        return 'At least 8 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // CONFIRM PASSWORD
                  // ==================================================

                  _RegisterField(
                    controller:
                        _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Repeat your password',
                    icon:
                        Icons.lock_outline_rounded,
                    obscureText:
                        _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey.shade500,
                        size: 21,
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Please confirm password';
                      }

                      if (value !=
                          _passwordController.text) {
                        return 'Passwords do not match';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // TERMS
                  // ==================================================

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _acceptTerms,
                          activeColor: primaryBlue,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(5),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms =
                                  value ?? false;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 2,
                          ),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      'I agree to the ',
                                ),
                                TextSpan(
                                  text:
                                      'Terms and Conditions',
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: ' and ',
                                ),
                                TextSpan(
                                  text:
                                      'Privacy Policy',
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: '.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // REGISTER BUTTON
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading ? null : _register,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        disabledBackgroundColor:
                            primaryBlue.withValues(alpha: 0.6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 23,
                              height: 23,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<
                                        Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 9),
                                Icon(
                                  Icons
                                      .arrow_forward_rounded,
                                  size: 21,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // OR
                  // ==================================================

                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: borderColor,
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        child: Text(
                          'Or sign up with',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: borderColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // SOCIAL BUTTONS
                  // ==================================================

                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          icon: 'G',
                          label: 'Google',
                          color:
                              const Color(0xFF4285F4),
                          onPressed: () {},
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _SocialButton(
                          iconData:
                              Icons.apple_rounded,
                          label: 'Apple',
                          color: Colors.black,
                          onPressed: () {},
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _SocialButton(
                          icon: 'f',
                          label: 'Facebook',
                          color:
                              const Color(0xFF1877F2),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // LOGIN
                  // ==================================================

                  Center(
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.go('/login');
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REGISTER FIELD
// ============================================================

class _RegisterField extends StatelessWidget {
  const _RegisterField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF102F4F),
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,

          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF102F4F),
            fontWeight: FontWeight.w600,
          ),

          decoration: InputDecoration(
            hintText: hint,

            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
            ),

            prefixIcon: Icon(
              icon,
              color: Colors.grey.shade500,
              size: 20,
            ),

            suffixIcon: suffixIcon,

            filled: true,
            fillColor: const Color(0xFFFAFCFF),

            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 16,
            ),

            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: borderColor,
              ),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: borderColor,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: primaryBlue,
                width: 1.5,
              ),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.red.shade300,
              ),
            ),

            focusedErrorBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.red.shade400,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SOCIAL BUTTON
// ============================================================

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
    this.iconData,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final String? icon;
  final IconData? iconData;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(
            color: borderColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(13),
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 6,
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            if (iconData != null)
              Icon(
                iconData,
                color: color,
                size: 21,
              )
            else
              Text(
                icon ?? '',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

            const SizedBox(width: 6),

            Flexible(
              child: Text(
                label,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkBlue,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}