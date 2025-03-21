import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:remalux_ar/core/theme/colors.dart';
import 'package:remalux_ar/core/widgets/custom_snack_bar.dart';
import 'package:remalux_ar/features/auth/domain/models/register_request.dart';
import 'package:remalux_ar/features/auth/domain/providers/auth_provider.dart';
import 'package:remalux_ar/core/widgets/custom_text_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';

class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({super.key});

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State variables
  int _currentStep = 1;
  bool _termsAccepted = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  // Timers for validation
  Timer? _emailCheckTimer;
  Timer? _phoneCheckTimer;

  // Password validation
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  // Email and phone validation status
  String? _emailStatus;
  String? _emailError;
  String? _phoneStatus;
  String? _phoneError;

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _codeMaskFormatter = MaskTextInputFormatter(
    mask: '# # # #',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool get _isStep1Valid {
    return _emailError == null &&
        _phoneError == null &&
        _emailController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _termsAccepted;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email);
  }

  void _checkEmail(String email) {
    if (_emailCheckTimer?.isActive ?? false) {
      _emailCheckTimer!.cancel();
    }

    setState(() {
      if (email.isEmpty) {
        _emailError = null;
        _emailStatus = null;
      } else if (!_isValidEmail(email)) {
        _emailError = 'auth.registration.validation.email_invalid'.tr();
        _emailStatus = null;
      } else {
        _emailError = null;
        _emailStatus = null;
      }
    });

    if (_emailError == null && email.contains('@')) {
      _emailCheckTimer = Timer(const Duration(milliseconds: 500), () async {
        final auth = ref.read(authProvider);
        final isAvailable = await auth.checkEmailAvailability(email);
        if (mounted) {
          setState(() {
            if (isAvailable) {
              _emailStatus =
                  'auth.registration.validation.email_available'.tr();
              _emailError = null;
            } else {
              _emailStatus = null;
              _emailError = 'auth.registration.validation.email_taken'.tr();
            }
          });
        }
      });
    }
  }

  void _checkPhone(String phone) {
    if (_phoneCheckTimer?.isActive ?? false) {
      _phoneCheckTimer!.cancel();
    }

    setState(() {
      if (phone.isEmpty) {
        _phoneError = null;
        _phoneStatus = null;
      } else if (phone.length < 18) {
        _phoneError = null;
        _phoneStatus = null;
      } else {
        _phoneError = null;
        _phoneStatus = null;

        _phoneCheckTimer = Timer(const Duration(milliseconds: 500), () async {
          final auth = ref.read(authProvider);
          final isAvailable = await auth.checkPhoneAvailability(phone);
          if (mounted) {
            setState(() {
              if (isAvailable) {
                _phoneStatus =
                    'auth.registration.validation.phone_available'.tr();
                _phoneError = null;
              } else {
                _phoneStatus = null;
                _phoneError = 'auth.registration.validation.phone_taken'.tr();
              }
            });
          }
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => _checkEmail(_emailController.text));
    _phoneController.addListener(() => _checkPhone(_phoneController.text));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailCheckTimer?.cancel();
    _phoneCheckTimer?.cancel();
    super.dispose();
  }

  void _handleNextStep() {
    if (_currentStep == 1) {
      if (_validateStep1()) {
        setState(() => _currentStep = 2);
      }
    } else if (_currentStep == 2) {
      if (_validateStep2()) {
        _handleRegistration();
      }
    }
  }

  bool _validateStep1() {
    setState(() {
      _termsAccepted = true;
    });
    return _isStep1Valid;
  }

  bool _validateStep2() {
    setState(() {
      _hasMinLength = _passwordController.text.length >= 8;
      _hasUpperCase = _passwordController.text.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = _passwordController.text.contains(RegExp(r'[a-z]'));
      _hasNumber = _passwordController.text.contains(RegExp(r'[0-9]'));
      _hasSpecialChar =
          _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
    return _hasMinLength &&
        _hasUpperCase &&
        _hasLowerCase &&
        _hasNumber &&
        _hasSpecialChar &&
        _passwordController.text == _confirmPasswordController.text;
  }

  void _handleRegistration() async {
    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authProvider);
      await auth.register(RegisterRequest(
        name: 'User', // Default name for now
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        agreement: _termsAccepted,
      ));

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'auth.registration.success'.tr(),
          type: SnackBarType.success,
          duration: const Duration(seconds: 2),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception:')) {
          errorMessage = errorMessage.replaceAll('Exception:', '').trim();
        }

        CustomSnackBar.show(
          context,
          message: errorMessage,
          type: SnackBarType.error,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        for (int i = 1; i <= 2; i++)
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: i <= _currentStep
                  ? const Color(0xFFB71C1C)
                  : const Color(0xFFE0E0E0),
            ),
          ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'auth.registration.title'.tr(),
          textAlign: TextAlign.center,
          style: GoogleFonts.ysabeau(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 32),

        // Email Input
        CustomTextField(
          label: 'auth.registration.email'.tr(),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          statusText: _emailStatus,
          onChanged: _checkEmail,
        ),
        const SizedBox(height: 16),

        // Phone Input
        CustomTextField(
          label: 'auth.registration.phone'.tr(),
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [_phoneMaskFormatter],
          errorText: _phoneError,
          statusText: _phoneStatus,
          onChanged: _checkPhone,
        ),
        const SizedBox(height: 24),

        // Terms Agreement
        Row(
          children: [
            Checkbox(
              value: _termsAccepted,
              onChanged: (bool? value) {
                setState(() {
                  _termsAccepted = value ?? false;
                });
              },
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'auth.registration.terms_agreement'.tr(),
                  children: [
                    TextSpan(
                      text: 'partnership.form.terms_and_conditions'.tr(),
                      style: const TextStyle(
                        color: Color(0xFFAA2A2F),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Next Button
        ElevatedButton(
          onPressed: _isStep1Valid ? _handleNextStep : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB71C1C),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 52),
          ),
          child: Text(
            'auth.registration.next'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordValidation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'auth.password_requirements'.tr(),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              _hasMinLength ? Icons.check : Icons.close,
              size: 16,
              color: _hasMinLength ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              'auth.password_min_length'.tr(),
              style: TextStyle(
                fontSize: 12,
                color: _hasMinLength ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              _hasUpperCase ? Icons.check : Icons.close,
              size: 16,
              color: _hasUpperCase ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              'auth.password_contains_uppercase'.tr(),
              style: TextStyle(
                fontSize: 12,
                color: _hasUpperCase ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              _hasLowerCase ? Icons.check : Icons.close,
              size: 16,
              color: _hasLowerCase ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              'auth.password_contains_lowercase'.tr(),
              style: TextStyle(
                fontSize: 12,
                color: _hasLowerCase ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              _hasNumber ? Icons.check : Icons.close,
              size: 16,
              color: _hasNumber ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              'auth.password_contains_number'.tr(),
              style: TextStyle(
                fontSize: 12,
                color: _hasNumber ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              _hasSpecialChar ? Icons.check : Icons.close,
              size: 16,
              color: _hasSpecialChar ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              'auth.password_contains_special'.tr(),
              style: TextStyle(
                fontSize: 12,
                color: _hasSpecialChar ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'auth.registration.step2'.tr(),
          textAlign: TextAlign.center,
          style: GoogleFonts.ysabeau(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 32),

        // Password Input
        CustomTextField(
          label: 'auth.registration.password'.tr(),
          controller: _passwordController,
          obscureText: !_passwordVisible,
          onChanged: (value) {
            setState(() {
              _hasMinLength = value.length >= 8;
              _hasUpperCase = value.contains(RegExp(r'[A-Z]'));
              _hasLowerCase = value.contains(RegExp(r'[a-z]'));
              _hasNumber = value.contains(RegExp(r'[0-9]'));
              _hasSpecialChar =
                  value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
            });
          },
          suffixIcon: IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility : Icons.visibility_off,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _passwordVisible = !_passwordVisible;
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        _buildPasswordValidation(),
        const SizedBox(height: 16),

        // Confirm Password Input
        CustomTextField(
          label: 'auth.registration.confirm_password'.tr(),
          controller: _confirmPasswordController,
          obscureText: !_confirmPasswordVisible,
          onChanged: (value) {
            setState(() {
              _validateStep2(); // Вызываем валидацию при изменении подтверждения пароля
            });
          },
          suffixIcon: IconButton(
            icon: Icon(
              _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _confirmPasswordVisible = !_confirmPasswordVisible;
              });
            },
          ),
          validator: (value) {
            if (value != _passwordController.text) {
              return 'auth.password_match'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        // Register Button
        ElevatedButton(
          onPressed: _validateStep2() ? _handleRegistration : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB71C1C),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 52),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'auth.registration.register'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        const SizedBox(height: 16),

        // Back Button
        TextButton(
          onPressed: () {
            setState(() {
              _currentStep = 1;
            });
          },
          child: Text(
            'auth.registration.back'.tr(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Image.asset(
          'lib/core/assets/images/logos/main.png',
          height: 32,
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/core/assets/images/registration.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildStepIndicator(),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: _currentStep == 1
                                  ? _buildStep1()
                                  : _buildStep2(),
                            ),
                          ),
                        ),
                        // Login Link
                        Padding(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: MediaQuery.of(context).padding.bottom + 16,
                          ),
                          child: Column(
                            children: [
                              Text(
                                'auth.registration.have_account'.tr(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'auth.registration.login'.tr(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
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
            ],
          ),
        ),
      ),
    );
  }
}
