import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:remalux_ar/core/services/storage_service.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _pages = [
    OnboardingItem(
      image: 'lib/core/assets/images/onboarding/1.png',
      title: 'Найдите своего врача',
      description: 'Выбирайте врачей по рейтингу, отзывам и опыту работы',
    ),
    OnboardingItem(
      image: 'lib/core/assets/images/onboarding/2.png',
      title: 'Запишитесь на прием',
      description: 'Записывайтесь к врачу в удобное для вас время',
    ),
    OnboardingItem(
      image: 'lib/core/assets/images/onboarding/3.png',
      title: 'Получайте консультации',
      description: 'Консультируйтесь с врачами онлайн в чате',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return OnboardingPageItem(item: _pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppLength.body),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: _currentPage == index
                              ? AppColors.primary
                              : AppColors.borderColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppLength.body),
                  CustomButton(
                    label:
                        _currentPage == _pages.length - 1 ? 'Начать' : 'Далее',
                    onPressed: () async {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      } else {
                        await StorageService.setHasSeenOnboarding();
                        if (context.mounted) {
                          context.go('/');
                        }
                      }
                    },
                    type: ButtonType.normal,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPageItem extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingPageItem({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppLength.body),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            item.image,
            height: 300,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppLength.xl),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: AppLength.xl,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppLength.body),
          Text(
            item.description,
            style: const TextStyle(
              fontSize: AppLength.body,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String image;
  final String title;
  final String description;

  OnboardingItem({
    required this.image,
    required this.title,
    required this.description,
  });
}
