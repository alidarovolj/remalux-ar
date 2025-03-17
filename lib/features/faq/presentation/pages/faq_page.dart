import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:remalux_ar/core/widgets/custom_text_field.dart';
import 'package:remalux_ar/features/auth/domain/providers/auth_provider.dart';
import 'package:remalux_ar/features/faq/domain/models/faq.dart';
import 'package:remalux_ar/features/faq/domain/providers/faq_provider.dart';
import 'package:remalux_ar/features/profile/presentation/pages/profile_page.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, String>> questions = [
    {
      'title': 'Что такое водоэмульсионная краска?',
      'answer':
          'Водоэмульсионная краска — это краска, в составе которой основным растворителем является вода. Она образует эмульсию из воды и связующего вещества, что делает краску безопасной и удобной в использовании.',
    },
    {
      'title':
          'Можно ли использовать водоэмульсионную краску для наружных работ?',
      'answer':
          'Да, существует специальная водоэмульсионная краска для наружных работ, которая обладает повышенной устойчивостью к воздействию дождя, снега и солнечных лучей. Можете использовать фасадную краску, сатин, текстурную краску.',
    },
    {
      'title': 'Какие основные преимущества красок REMALUX?',
      'answer':
          'Они быстро сохнут, не имеют запаха, легко наносятся, безопасны для здоровья и экологии, не выделяют токсичных веществ.',
    },
    {
      'title': 'Какие виды водоэмульсионных красок бывают?',
      'answer':
          'Водоэмульсионные краски бывают на основе акрила, латекса, силикона и других полимеров. Выбор зависит от условий эксплуатации и требований к поверхности.',
    },
    {
      'title': 'Какую водоэмульсионную краску выбрать для стен в квартире?',
      'answer':
          'Для внутренних работ лучше выбирать краску PRO, универсальную краску, краску для интерьера, так как они обладают хорошей паропроницаемостью и легко очищаются.',
    },
    {
      'title': 'Какие водоэмульсионные краски лучше для детских комнат?',
      'answer':
          'Для детских комнат стоит выбирать краску PRO, универсальную краску, сатин, краска по металлу и дереву которые не содержат вредных веществ и не имеют сильного запаха.',
    },
    {
      'title': 'Что значит \'матовая\' или \'глянцевая\' поверхность?',
      'answer':
          'Матовая краска не отражает свет, создавая бархатистую поверхность скрывая неровности (краска PRO, универсальная, интерьерная). В то время как глянцевая придает стенам блеск (сатин, краска для кухни и ванной, краска по металлу и дереву) требует идеально ровную поверхность т.к. проявит все неровности.',
    },
    {
      'title':
          'Как правильно подготовить поверхность перед нанесением водоэмульсионной краски?',
      'answer':
          'Поверхность должна быть чистой, сухой и гладкой. При необходимости следует удалить старую краску, загладить трещины и швы, а затем покрыть грунтовкой. Влажность не должно быть выше 80%, а температура свыше t +10°C.',
    },
    {
      'title': 'Какой расход водоэмульсионной краски на 1 м²?',
      'answer':
          'Обычно расход составляет около 100–150 мл на 1 м², в зависимости от типа поверхности и выбранной краски. На один слой.',
    },
    {
      'title': 'Можно ли наносить водоэмульсионную краску в несколько слоев?',
      'answer':
          'Да, для достижения равномерного покрытия рекомендуется наносить в два или в три слоя краски, давая каждому слою высохнуть.',
    },
    {
      'title': 'Как долго сохнет водоэмульсионная краска?',
      'answer':
          'Время высыхания зависит от температуры и влажности, но обычно краска сохнет от 2 часов.',
    },
    {
      'title':
          'Какая водоэмульсионная краска наиболее устойчива к загрязнениям?',
      'answer':
          'Краски PRO и сатин, фасадная краска, краска по металлу и дереву обладают хорошей устойчивостью к загрязнениям и могут быть очищены от пыли и грязи.',
    },
    {
      'title': 'Какую краску лучше выбрать для ванной комнаты?',
      'answer':
          'Специально для ванных комнат мы разработали водоэмульсионную краску для кухни и ванной с антимикробными свойствами и полуглянцевым финишем, устойчивые к повышенной влажности и образованию грибка.',
    },
    {
      'title':
          'Как правильно мыть стены после покраски водоэмульсионной краской?',
      'answer':
          'Для мытья рекомендуется использовать мягкие губки и нейтральные моющие средства. Жесткие химические вещества могут повредить покрытие.',
    },
    {
      'title':
          'Какую водоэмульсионную краску использовать для поверхности из дерева?',
      'answer':
          'Для дерева у нас существуют водоэмульсионные краски как по дереву и металлу, которые имеют повышенную адгезию к древесным поверхностям.',
    },
    {
      'title': 'Почему водоэмульсионная краска может трескаться?',
      'answer':
          'Это может быть связано с несоблюдением технологий нанесения краски.',
    },
    {
      'title': 'Какую водоэмульсионную краску выбрать для покраски потолков?',
      'answer':
          'Наши водоэмульсионные краски идеально подходят для покраски потолков, так как они быстро сохнут и не выделяют запахов. Можем предложить вам краску для интерьера или моющаяся краску, либо премиум сегмент краска \'2х1\'.',
    },
    {
      'title': 'Почему краска на водной основе лучше, чем масляные краски?',
      'answer':
          'Водоэмульсионные краски легче наносить, они быстрее сохнут, не имеют сильного запаха и более безопасны для здоровья, чем масляные.',
    },
    {
      'title': 'Как хранить водоэмульсионную краску?',
      'answer':
          'Хранить краску следует в плотно закрытой упаковке в сухом и прохладном месте при температуре от +5°C до +35°C, вдали от источников тепла и прямого солнечного света.',
    },
  ];

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Часто задаваемые вопросы',
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
                  const SnackBar(
                    content: Text(
                      'Ваш вопрос успешно отправлен',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              error: (error, _) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Произошла проблема при отправке вопроса',
                      style: TextStyle(color: Colors.white),
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
              const Text(
                'У вас остались вопросы? Не волнуйтесь, мы здесь, чтобы помочь! Прочитайте наши часто задаваемые вопросы.\nЕсли ваш вопрос не был рассмотрен, просто оставьте его, и мы ответим вам как можно скорее.',
                style: TextStyle(
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
                    label: 'Интересующий вопрос',
                    placeholder: 'Напишите свой вопрос',
                    controller: _questionController,
                    minLines: 3,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    label: 'Оставить вопрос',
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
                                const Text(
                                  'Для отправки вопроса необходимо авторизоваться',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                CustomButton(
                                  label: 'Войти',
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
              ...questions.map((question) => Column(
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
                              question['title']!,
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
                                question['answer']!,
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
