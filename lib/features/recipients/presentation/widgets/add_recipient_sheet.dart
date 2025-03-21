import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/widgets/custom_text_field.dart';
import 'package:remalux_ar/core/widgets/custom_snack_bar.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:remalux_ar/features/recipients/domain/providers/recipients_provider.dart';

class AddRecipientSheet extends ConsumerStatefulWidget {
  const AddRecipientSheet({super.key});

  @override
  ConsumerState<AddRecipientSheet> createState() => _AddRecipientSheetState();
}

class _AddRecipientSheetState extends ConsumerState<AddRecipientSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Добавить нового получателя',
                  style: GoogleFonts.ysabeau(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Имя и фамилия',
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, введите имя';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Номер телефона',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [_phoneMaskFormatter],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, введите номер телефона';
                }
                if (!_phoneMaskFormatter.isFill()) {
                  return 'Пожалуйста, введите полный номер телефона';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Сохранить',
              onPressed: _isLoading
                  ? () {}
                  : () async {
                      await _saveRecipient();
                    },
              isEnabled: !_isLoading,
              isLoading: _isLoading,
              type: ButtonType.normal,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRecipient() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        await ref.read(recipientsProvider.notifier).addRecipient(
              name: _nameController.text,
              phoneNumber: _phoneController.text,
            );

        if (mounted) {
          Navigator.pop(context);
          CustomSnackBar.show(
            context,
            message: 'Получатель успешно добавлен',
            type: SnackBarType.success,
          );
          // Force refresh recipients list
          ref.read(recipientsProvider.notifier).refreshRecipients();
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'Ошибка при добавлении получателя',
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
  }
}
