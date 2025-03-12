import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:remalux_ar/core/theme/colors.dart';
import 'package:remalux_ar/core/widgets/custom_snack_bar.dart';
import 'package:remalux_ar/features/auth/domain/models/login_request.dart';
import 'package:remalux_ar/features/auth/domain/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 ### - ### - ## - ##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phoneNumber = _phoneController.text;
    final password = _passwordController.text;

    if (phoneNumber.isEmpty || password.isEmpty) {
      CustomSnackBar.show(
        context,
        message: 'Пожалуйста, заполните все поля',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final auth = ref.read(authProvider);

      // Login
      final authResponse = await auth.login(
        LoginRequest(
          phoneNumber: phoneNumber,
          password: password,
        ),
      );

      if (!mounted) return;

      // Get user info
      final user = await auth.getCurrentUser();

      if (mounted) {
        // Show success message
        CustomSnackBar.show(
          context,
          message: 'Вы успешно авторизовались',
          type: SnackBarType.success,
          duration: const Duration(seconds: 2),
        );

        // Add a small delay to allow the snackbar to be visible before navigation
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          context.go('/');
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: e.toString(),
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
            image: AssetImage('lib/core/assets/images/login.jpg'),
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
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Welcome Text
                                Text(
                                  'Добро пожаловать!',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.ysabeau(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Phone Input
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Номер телефона',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [_phoneMaskFormatter],
                                      decoration: InputDecoration(
                                        hintText: '+7 (___) ___ __ __',
                                        hintStyle: TextStyle(
                                          color: AppColors.textSecondary
                                              .withOpacity(0.5),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF8F8F8),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Password Input
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Пароль',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        hintText: 'Пароль',
                                        hintStyle: TextStyle(
                                          color: AppColors.textSecondary
                                              .withOpacity(0.5),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF8F8F8),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      // TODO: Implement forgot password
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Забыли пароль?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Register Button
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFB71C1C),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize:
                                        const Size(double.infinity, 52),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Авторизоваться',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ],
                            ),
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
                            const Text(
                              'Еще нет аккаунта?',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // TODO: Navigate to registration
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Пожалуйста, зарегистрируйтесь',
                                style: TextStyle(
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
            ],
          ),
        ),
      ),
    );
  }
}
