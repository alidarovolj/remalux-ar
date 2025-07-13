import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_snack_bar.dart';
import 'package:remalux_ar/core/widgets/custom_text_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:remalux_ar/features/auth/domain/services/password_recovery_service.dart';
import 'dart:async';
import 'dart:ui';

class PhoneVerificationPage extends ConsumerStatefulWidget {
  const PhoneVerificationPage({super.key});

  @override
  ConsumerState<PhoneVerificationPage> createState() =>
      _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends ConsumerState<PhoneVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 1;
  bool _isLoading = false;
  Timer? _resendTimer;
  int _remainingTime = 30;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isPhoneValid = false;
  String? _verificationToken;

  // Password validation
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _codeMaskFormatter = MaskTextInputFormatter(
    mask: '####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_validatePhone);
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _validatePhone() {
    final phone = _phoneMaskFormatter.getUnmaskedText();
    setState(() {
      _isPhoneValid = phone.length == 10; // Проверяем длину номера без маски
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _remainingTime = 30;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _handleNextStep() async {
    if (_currentStep == 1) {
      if (_isPhoneValid) {
        setState(() => _isLoading = true);
        try {
          await ref
              .read(passwordRecoveryServiceProvider)
              .requestCode(_phoneController.text);
          if (mounted) {
            setState(() {
              _currentStep = 2;
              _startResendTimer();
              _isLoading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            CustomSnackBar.show(
              context,
              message: e.toString(),
              type: SnackBarType.error,
            );
          }
        }
      }
    } else if (_currentStep == 2) {
      final code = _codeController.text.replaceAll(' ', '');
      if (code.length == 4) {
        setState(() => _isLoading = true);
        try {
          final token =
              await ref.read(passwordRecoveryServiceProvider).verifyCode(
                    _phoneController.text,
                    code,
                  );
          if (mounted) {
            setState(() {
              _verificationToken = token;
              _currentStep = 3;
              _resendTimer?.cancel();
              _isLoading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            CustomSnackBar.show(
              context,
              message: e.toString(),
              type: SnackBarType.error,
            );
          }
        }
      }
    } else if (_currentStep == 3) {
      if (_validatePasswordStep()) {
        _handlePasswordReset();
      }
    }
  }

  bool _validatePasswordStep() {
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

  void _handlePasswordReset() async {
    setState(() => _isLoading = true);

    try {
      final message =
          await ref.read(passwordRecoveryServiceProvider).resetPassword(
                _verificationToken!,
                _passwordController.text,
                _confirmPasswordController.text,
              );

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: message,
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
        for (int i = 1; i <= 3; i++)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(100),
          ),
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
          ),
        ),
        title: SvgPicture.asset(
          'lib/core/assets/icons/logo.svg',
          height: 32,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/core/assets/images/registration.jpg',
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
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
                            child: Column(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: _currentStep == 1
                                          ? _buildStep1Content()
                                          : _currentStep == 2
                                              ? _buildStep2Content()
                                              : _buildStep3Content(),
                                    ),
                                  ),
                                ),
                                SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ElevatedButton(
                                          onPressed: _currentStep == 1
                                              ? (_isPhoneValid
                                                  ? _handleNextStep
                                                  : null)
                                              : _currentStep == 2
                                                  ? (_codeController
                                                              .text.length ==
                                                          7
                                                      ? _handleNextStep
                                                      : null)
                                                  : (_validatePasswordStep()
                                                      ? _handlePasswordReset
                                                      : null),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFB71C1C),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            minimumSize:
                                                const Size(double.infinity, 52),
                                          ),
                                          child: _currentStep == 3 && _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.white),
                                                  ),
                                                )
                                              : Text(
                                                  _currentStep == 1
                                                      ? 'auth.verification.send_code'
                                                          .tr()
                                                      : 'auth.verification.continue'
                                                          .tr(),
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                        ),
                                        if (_currentStep > 1) ...[
                                          const SizedBox(height: 16),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                if (_currentStep == 2) {
                                                  _currentStep = 1;
                                                  _codeController.clear();
                                                  _resendTimer?.cancel();
                                                } else {
                                                  _currentStep = 2;
                                                  _passwordController.clear();
                                                  _confirmPasswordController
                                                      .clear();
                                                }
                                              });
                                            },
                                            child: Text(
                                              'auth.verification.back'.tr(),
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
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
        ],
      ),
    );
  }

  Widget _buildStep1Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'auth.forgot_password.title'.tr(),
          textAlign: TextAlign.center,
          style: GoogleFonts.ysabeau(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'auth.forgot_password.description'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'auth.verification.phone'.tr(),
          hintText: 'auth.verification.phone_placeholder'.tr(),
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [_phoneMaskFormatter],
        ),
      ],
    );
  }

  Widget _buildStep2Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'auth.verification.title'.tr(),
          textAlign: TextAlign.center,
          style: GoogleFonts.ysabeau(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'auth.verification.code_sent'.tr(args: [_phoneController.text]),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 36),
        AutofillGroup(
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    width: 58,
                    height: 54,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _codeController.text.length > index
                            ? _codeController.text[index]
                            : '',
                        style: GoogleFonts.ysabeau(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.8),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: 4,
                  showCursor: false,
                  cursorWidth: 0,
                  style: const TextStyle(
                    color: Colors.transparent,
                    height: 0,
                    fontSize: 1,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    if (value.length == 4) {
                      _handleNextStep();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        Center(
          child: GestureDetector(
            onTap: _remainingTime == 0
                ? () {
                    _startResendTimer();
                    // ✅ Повторная отправка кода
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Код подтверждения отправлен повторно'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                : null,
            child: Text(
              _remainingTime > 0
                  ? 'auth.verification.resend_code_timer'.tr(args: [
                      '${_remainingTime ~/ 60}:${(_remainingTime % 60).toString().padLeft(2, '0')}'
                    ])
                  : 'auth.verification.resend_code'.tr(),
              style: TextStyle(
                fontSize: 15,
                color: _remainingTime > 0
                    ? AppColors.textSecondary
                    : AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'auth.password_reset.new_password'.tr(),
          textAlign: TextAlign.center,
          style: GoogleFonts.ysabeau(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 32),
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
        CustomTextField(
          label: 'auth.registration.confirm_password'.tr(),
          controller: _confirmPasswordController,
          obscureText: !_confirmPasswordVisible,
          onChanged: (value) {
            setState(() {
              _validatePasswordStep();
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
}
