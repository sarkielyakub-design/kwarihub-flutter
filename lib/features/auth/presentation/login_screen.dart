import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/auth_api.dart';

// ============================================================
// COLORS
// ============================================================

const Color primaryBlue = Color(0xFF0D5CC7);
const Color darkBlue = Color(0xFF102F4F);
const Color lightBlue = Color(0xFFF4F8FF);
const Color borderColor = Color(0xFFDDE6F0);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ============================================================
  // SECURE STORAGE
  // ============================================================

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool _obscurePassword = true;
  bool _isLoading = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (email.isEmpty) {
      _showError(
        'Please enter your email address.',
      );
      return;
    }

    if (!email.contains('@')) {
      _showError(
        'Please enter a valid email address.',
      );
      return;
    }

    if (password.isEmpty) {
      _showError(
        'Please enter your password.',
      );
      return;
    }

    if (password.length < 8) {
      _showError(
        'Password must be at least 8 characters.',
      );
      return;
    }

    // ----------------------------------------------------------
    // START LOADING
    // ----------------------------------------------------------

    setState(() {
      _isLoading = true;
    });

    try {
      // --------------------------------------------------------
      // CALL FASTAPI
      // --------------------------------------------------------

      final authApi = AuthApi();

      final data = await authApi.login(
        email: email,
        password: password,
      );

      // --------------------------------------------------------
      // GET TOKENS
      // --------------------------------------------------------

      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];

      if (accessToken == null ||
          accessToken.toString().isEmpty) {
        throw Exception(
          'Access token was not returned by the server.',
        );
      }

      if (refreshToken == null ||
          refreshToken.toString().isEmpty) {
        throw Exception(
          'Refresh token was not returned by the server.',
        );
      }

      // --------------------------------------------------------
      // SAVE TOKENS SECURELY
      // --------------------------------------------------------

      await _storage.write(
        key: 'access_token',
        value: accessToken.toString(),
      );

      await _storage.write(
        key: 'refresh_token',
        value: refreshToken.toString(),
      );

      await _storage.write(
        key: 'user_email',
        value: email,
      );

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint('========================================');
      debugPrint('KWARIHUB LOGIN SUCCESS');
      debugPrint('Email: $email');
      debugPrint('Access token saved');
      debugPrint('Refresh token saved');
      debugPrint('========================================');

      // --------------------------------------------------------
      // GO TO DASHBOARD
      // --------------------------------------------------------

      context.go('/home');
    } on DioException catch (e) {
      // --------------------------------------------------------
      // DIO / FASTAPI ERROR
      // --------------------------------------------------------

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String message =
          'Unable to connect to KwariHub server.';

      // --------------------------------------------------------
      // SERVER RESPONSE
      // --------------------------------------------------------

      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        debugPrint(
          'LOGIN STATUS: $statusCode',
        );

        debugPrint(
          'LOGIN RESPONSE: $responseData',
        );

        // FastAPI usually returns:
        //
        // {
        //   "detail": "..."
        // }

        if (responseData is Map &&
            responseData['detail'] != null) {
          message =
              responseData['detail'].toString();
        } else {
          switch (statusCode) {
            case 400:
              message =
                  'Invalid login request.';
              break;

            case 401:
              message =
                  'Invalid email or password.';
              break;

            case 403:
              message =
                  'Please verify your email before logging in.';
              break;

            case 404:
              message =
                  'Account not found.';
              break;

            case 422:
              message =
                  'Please check your login details.';
              break;

            case 500:
              message =
                  'Server error. Please try again later.';
              break;

            default:
              message =
                  'Login failed. Please try again.';
          }
        }
      } else {
        // ------------------------------------------------------
        // NO SERVER RESPONSE
        // ------------------------------------------------------

        if (e.type ==
            DioExceptionType.connectionError) {
          message =
              'Unable to connect to KwariHub server.';
        } else if (e.type ==
            DioExceptionType.connectionTimeout) {
          message =
              'Connection timed out. Please try again.';
        } else if (e.type ==
            DioExceptionType.receiveTimeout) {
          message =
              'Server took too long to respond.';
        } else {
          message =
              'Network error. Please check your connection.';
        }
      }

      _showError(message);
    } catch (e) {
      // --------------------------------------------------------
      // GENERAL ERROR
      // --------------------------------------------------------

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint(
        'LOGIN ERROR: $e',
      );

      _showError(
        'Something went wrong. Please try again.',
      );
    }
  }

  // ============================================================
  // ERROR SNACKBAR
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
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
  // FORGOT PASSWORD
  // ============================================================

  void _forgotPassword() {
    // We will connect this to:
    //
    // POST /api/v1/auth/forgot-password
    //
    // after login is completely tested.

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Password reset will be connected next.',
        ),
        behavior: SnackBarBehavior.floating,
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

          child: SingleChildScrollView(
            physics:
                const BouncingScrollPhysics(),

            padding: const EdgeInsets.fromLTRB(
              24,
              18,
              24,
              30,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ==================================================
                // TOP BAR
                // ==================================================

                Row(
                  children: [
                    // ------------------------------------------------
                    // BACK
                    // ------------------------------------------------

                    IconButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(
                                  '/onboarding',
                                );
                              }
                            },

                      style: IconButton.styleFrom(
                        backgroundColor:
                            lightBlue,
                        foregroundColor:
                            darkBlue,
                        fixedSize:
                            const Size(44, 44),
                      ),

                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 22,
                      ),
                    ),

                    const Spacer(),

                    // ------------------------------------------------
                    // LOGO
                    // ------------------------------------------------

                    Image.asset(
                      'assets/images/kwarihub_logo.png',
                      width: 95,
                      height: 42,
                      fit: BoxFit.contain,
                    ),

                    const Spacer(),

                    // ------------------------------------------------
                    // BALANCER
                    // ------------------------------------------------

                    const SizedBox(
                      width: 44,
                      height: 44,
                    ),
                  ],
                ),

                const SizedBox(height: 42),

                // ==================================================
                // TITLE
                // ==================================================

                Center(
                  child: Column(
                    children: [
                      Text(
                        'Welcome Back 👋',
                        textAlign:
                            TextAlign.center,

                        style:
                            const TextStyle(
                          fontSize: 29,
                          height: 1.15,
                          fontWeight:
                              FontWeight.w900,
                          color: darkBlue,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        'Login to your account',
                        textAlign:
                            TextAlign.center,

                        style: TextStyle(
                          fontSize: 15,
                          color:
                              Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 38),

                // ==================================================
                // EMAIL LABEL
                // ==================================================

                const Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                    color: darkBlue,
                  ),
                ),

                const SizedBox(height: 9),

                // ==================================================
                // EMAIL INPUT
                // ==================================================

                _InputField(
                  controller:
                      _emailController,
                  hintText:
                      'you@example.com',
                  keyboardType:
                      TextInputType.emailAddress,
                  prefixIcon:
                      Icons.email_outlined,
                  enabled: !_isLoading,
                  textInputAction:
                      TextInputAction.next,
                ),

                const SizedBox(height: 22),

                // ==================================================
                // PASSWORD LABEL
                // ==================================================

                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                    color: darkBlue,
                  ),
                ),

                const SizedBox(height: 9),

                // ==================================================
                // PASSWORD INPUT
                // ==================================================

                _InputField(
                  controller:
                      _passwordController,
                  hintText:
                      'Enter your password',
                  obscureText:
                      _obscurePassword,
                  prefixIcon:
                      Icons.lock_outline_rounded,
                  enabled: !_isLoading,
                  textInputAction:
                      TextInputAction.done,

                  onSubmitted: (_) {
                    if (!_isLoading) {
                      _login();
                    }
                  },

                  suffixIcon:
                      IconButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },

                    icon: Icon(
                      _obscurePassword
                          ? Icons
                              .visibility_outlined
                          : Icons
                              .visibility_off_outlined,

                      color:
                          Colors.grey.shade500,
                      size: 21,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // FORGOT PASSWORD
                // ==================================================

                Align(
                  alignment:
                      Alignment.centerRight,

                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : _forgotPassword,

                    style:
                        TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize:
                          Size.zero,
                      tapTargetSize:
                          MaterialTapTargetSize
                              .shrinkWrap,
                    ),

                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ==================================================
                // LOGIN BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 56,

                  child: ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _login,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          primaryBlue,

                      disabledBackgroundColor:
                          primaryBlue
                              .withValues(
                        alpha: 0.6,
                      ),

                      foregroundColor:
                          Colors.white,

                      elevation: 0,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
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
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 27),

                // ==================================================
                // DIVIDER
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: borderColor,
                        thickness: 1,
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 14,
                      ),

                      child: Text(
                        'Or continue with',
                        style: TextStyle(
                          color:
                              Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Divider(
                        color: borderColor,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ==================================================
                // SOCIAL LOGIN
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child:
                          _SocialButton(
                        icon: 'G',
                        label: 'Google',
                        onPressed: () {
                          _showError(
                            'Google login will be connected later.',
                          );
                        },
                        iconColor:
                            const Color(
                          0xFF4285F4,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child:
                          _SocialButton(
                        icon: '',
                        label: 'Apple',
                        iconData:
                            Icons.apple_rounded,
                        onPressed: () {
                          _showError(
                            'Apple login will be connected later.',
                          );
                        },
                        iconColor:
                            Colors.black,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child:
                          _SocialButton(
                        icon: 'f',
                        label: 'Facebook',
                        onPressed: () {
                          _showError(
                            'Facebook login will be connected later.',
                          );
                        },
                        iconColor:
                            const Color(
                          0xFF1877F2,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // ==================================================
                // REGISTER
                // ==================================================

                Center(
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Colors.grey.shade600,
                        ),
                      ),

                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                context.go(
                                  '/register',
                                );
                              },

                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color:
                                primaryBlue,
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w800,
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
    );
  }
}

// ============================================================
// INPUT FIELD
// ============================================================

class _InputField
    extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(
    BuildContext context,
  ) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,

      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF102F4F),
        fontWeight: FontWeight.w600,
      ),

      decoration: InputDecoration(
        hintText: hintText,

        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),

        prefixIcon: Icon(
          prefixIcon,
          size: 20,
          color: Colors.grey.shade500,
        ),

        suffixIcon: suffixIcon,

        filled: true,

        fillColor: enabled
            ? const Color(0xFFFAFCFF)
            : const Color(0xFFF4F6F9),

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: borderColor,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: borderColor,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: primaryBlue,
            width: 1.5,
          ),
        ),

        disabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: borderColor,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SOCIAL BUTTON
// ============================================================

class _SocialButton
    extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.iconColor,
    this.iconData,
  });

  final String icon;
  final String label;
  final VoidCallback onPressed;
  final Color iconColor;
  final IconData? iconData;

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      height: 50,

      child: OutlinedButton(
        onPressed: onPressed,

        style:
            OutlinedButton.styleFrom(
          backgroundColor:
              Colors.white,

          foregroundColor:
              const Color(
            0xFF102F4F,
          ),

          side:
              const BorderSide(
            color: borderColor,
          ),

          elevation: 0,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),

          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 8,
          ),
        ),

        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            if (iconData != null)
              Icon(
                iconData,
                color: iconColor,
                size: 21,
              )
            else
              Text(
                icon,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w900,
                  color: iconColor,
                ),
              ),

            const SizedBox(
              width: 7,
            ),

            Flexible(
              child: Text(
                label,
                overflow:
                    TextOverflow.ellipsis,

                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                  color: Color(
                    0xFF102F4F,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}