import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:remalux_ar/core/widgets/custom_text_field.dart';
import 'package:remalux_ar/features/faq/domain/providers/faq_provider.dart';
import 'package:remalux_ar/features/profile/presentation/pages/profile_page.dart';
import 'package:easy_localization/easy_localization.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final TextEditingController _questionController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'faq.title'.tr(),
        showBottomBorder: true,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(userProvider);
          final questionsState = ref.watch(questionsProvider);

          ref.listen(questionsProvider, (previous, next) {
            next.whenOrNull(
              data: (_) {
                _questionController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'faq.success_message'.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              error: (error, _) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'faq.error_message'.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          });

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Description
              Text(
                'faq.description'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textIconsSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Question input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextArea(
                    label: 'faq.question_input.label'.tr(),
                    placeholder: 'faq.question_input.placeholder'.tr(),
                    controller: _questionController,
                    minLines: 3,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    label: 'faq.question_input.submit'.tr(),
                    onPressed: () async {
                      if (_questionController.text.isEmpty) return;

                      final user = authState.value;
                      if (user == null) {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'faq.auth_required.title'.tr(),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                CustomButton(
                                  label: 'faq.auth_required.login'.tr(),
                                  onPressed: () {
                                    context.pop();
                                    context.push('/login');
                                  },
                                  type: ButtonType.normal,
                                  backgroundColor: AppColors.primary,
                                  textColor: Colors.white,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        );
                        return;
                      }

                      if (questionsState.isLoading) return;

                      await ref
                          .read(questionsProvider.notifier)
                          .submitQuestion(_questionController.text);
                    },
                    type: ButtonType.normal,
                    backgroundColor: AppColors.buttonSecondary,
                    textColor: AppColors.links,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // FAQ List
              ...List.generate(
                  19,
                  (index) => Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                title: Text(
                                  'faq.questions.${index + 1}.title'.tr(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 0),
                                childrenPadding: const EdgeInsets.only(
                                    left: 12, right: 12, bottom: 16),
                                iconColor: AppColors.textPrimary,
                                collapsedIconColor: AppColors.textPrimary,
                                children: [
                                  Text(
                                    'faq.questions.${index + 1}.answer'.tr(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textIconsSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )),
            ],
          );
        },
      ),
    );
  }
}
