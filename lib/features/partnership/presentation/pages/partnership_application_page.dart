import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:remalux_ar/core/widgets/custom_text_field.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_snack_bar.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:remalux_ar/features/partnership/presentation/providers/cities_provider.dart';
import 'package:remalux_ar/features/partnership/presentation/providers/partnership_provider.dart';
import 'package:remalux_ar/features/partnership/presentation/widgets/city_select_modal.dart';
import 'package:remalux_ar/features/partnership/domain/models/city.dart';
import 'dart:async';

class PartnershipApplicationPage extends ConsumerStatefulWidget {
  const PartnershipApplicationPage({super.key});

  @override
  ConsumerState<PartnershipApplicationPage> createState() =>
      _PartnershipApplicationPageState();
}

class _PartnershipApplicationPageState
    extends ConsumerState<PartnershipApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _binController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  bool _agreedToTerms = false;
  String? _selectedCity;
  String? _cityError;
  bool _isLoading = false;
  City? _selectedCityData;
  String? _emailError;
  String? _emailStatus;
  String? _phoneError;
  String? _phoneStatus;
  Timer? _emailCheckTimer;
  Timer? _phoneCheckTimer;
  bool _showValidationErrors = false;

  bool get _isFormValid {
    if (_emailError != null || _phoneError != null) return false;
    if (!_showValidationErrors) return _agreedToTerms;

    return _formKey.currentState?.validate() == true &&
        _selectedCityData != null &&
        _agreedToTerms &&
        _fullNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _binController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty;
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
        _emailError = 'partnership.form.errors.required_field'.tr();
        _emailStatus = null;
      } else if (!_isValidEmail(email)) {
        _emailError = 'partnership.form.errors.invalid_email'.tr();
        _emailStatus = null;
      } else {
        _emailError = null;
        _emailStatus = null;
      }
    });

    if (_emailError == null) {
      _emailCheckTimer = Timer(const Duration(milliseconds: 500), () async {
        final repository = ref.read(partnershipRepositoryProvider);
        final isAvailable = await repository.checkEmailAvailability(email);
        if (mounted) {
          setState(() {
            if (isAvailable) {
              _emailStatus = 'partnership.form.email_available'.tr();
              _emailError = null;
            } else {
              _emailStatus = null;
              _emailError = 'partnership.form.email_taken'.tr();
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
        _phoneError = 'partnership.form.errors.required_field'.tr();
        _phoneStatus = null;
      } else if (phone.length < 18) {
        // +7 (XXX) XXX-XX-XX
        _phoneError = 'partnership.form.errors.invalid_phone'.tr();
        _phoneStatus = null;
      } else {
        _phoneError = null;
        _phoneStatus = null;
      }
    });

    if (_phoneError == null) {
      _phoneCheckTimer = Timer(const Duration(milliseconds: 500), () async {
        final repository = ref.read(partnershipRepositoryProvider);
        final isAvailable = await repository.checkPhoneAvailability(phone);
        if (mounted) {
          setState(() {
            if (isAvailable) {
              _phoneStatus = 'partnership.form.phone_available'.tr();
              _phoneError = null;
            } else {
              _phoneStatus = null;
              _phoneError = 'partnership.form.phone_taken'.tr();
            }
          });
        }
      });
    }
  }

  void _showCitySelector(List<City> cities) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: CitySelectModal(
            cities: cities,
            selectedCity: _selectedCity,
            onSelect: (city) {
              final selectedCity = cities.firstWhere(
                (c) => context.locale.languageCode == 'kk'
                    ? c.titleKz == city
                    : context.locale.languageCode == 'en'
                        ? c.titleEn == city
                        : c.title == city,
              );
              setState(() {
                _selectedCity = city;
                _selectedCityData = selectedCity;
                _cityError = null;
              });
            },
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    setState(() {
      _showValidationErrors = true;
    });

    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
    });

    final repository = ref.read(partnershipRepositoryProvider);
    repository
        .submitApplication(
      name: _fullNameController.text,
      phoneNumber: _phoneController.text,
      bin: _binController.text,
      cityId: _selectedCityData!.id,
      email: _emailController.text,
      agreement: _agreedToTerms,
    )
        .then((_) {
      setState(() {
        _isLoading = false;
      });
      CustomSnackBar.show(
        context,
        message: 'partnership.form.success'.tr(),
        type: SnackBarType.success,
      );
      Navigator.pop(context);
    }).catchError((error) {
      setState(() {
        _isLoading = false;
      });
      CustomSnackBar.show(
        context,
        message: 'partnership.form.submit_error'.tr(),
        type: SnackBarType.error,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    // Инициализируем начальную проверку email
    _checkEmail(_emailController.text);
    // Добавляем слушатель изменений для email
    _emailController.addListener(() => _checkEmail(_emailController.text));
    // Добавляем слушатель изменений для телефона
    _phoneController.addListener(() => _checkPhone(_phoneController.text));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _binController.dispose();
    _phoneController.dispose();
    _emailCheckTimer?.cancel();
    _phoneCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(citiesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'partnership.form.title'.tr(),
        showBottomBorder: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          label: 'partnership.form.full_name'.tr(),
                          controller: _fullNameController,
                          validator: (value) {
                            if (!_showValidationErrors) return null;
                            if (value == null || value.isEmpty) {
                              return 'partnership.form.errors.required_field'
                                  .tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'partnership.form.email'.tr(),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                          statusText: _emailStatus,
                          onChanged: _checkEmail,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'partnership.form.bin'.tr(),
                          controller: _binController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (!_showValidationErrors) return null;
                            if (value == null || value.isEmpty) {
                              return 'partnership.form.errors.required_field'
                                  .tr();
                            }
                            if (value.length != 12) {
                              return 'partnership.form.errors.invalid_bin'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'partnership.form.phone'.tr(),
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [_phoneMaskFormatter],
                          errorText: _phoneError,
                          statusText: _phoneStatus,
                          onChanged: _checkPhone,
                        ),
                        const SizedBox(height: 16),
                        citiesAsync.when(
                          data: (cities) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'partnership.form.select_city'.tr(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _showCitySelector(cities),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: _showValidationErrors &&
                                            _cityError != null
                                        ? Border.all(color: Colors.red)
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedCity ??
                                            'partnership.form.select_city'.tr(),
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: _selectedCity != null
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_showValidationErrors && _cityError != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8, left: 12),
                                  child: Text(
                                    _cityError!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => Text(
                            'common.error_loading'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: (bool? value) {
                            setState(() {
                              _agreedToTerms = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'partnership.form.agree_with'.tr(),
                              children: [
                                TextSpan(
                                  text: 'partnership.form.terms_and_conditions'
                                      .tr(),
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
                    const SizedBox(height: 16),
                    CustomButton(
                      label: 'partnership.form.submit'.tr(),
                      onPressed: _submitForm,
                      isEnabled: _isFormValid,
                      isLoading: _isLoading,
                      type: ButtonType.normal,
                      backgroundColor: const Color(0xFFAA2A2F),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
