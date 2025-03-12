import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum BannerType {
  products,
  ideas,
  colors,
  news,
}

class PageBanner extends StatelessWidget {
  final BannerType bannerType;

  const PageBanner({
    super.key,
    required this.bannerType,
    // Оставляем эти параметры для обратной совместимости, но не используем их
    String title = '',
    String secondTitle = '',
    dynamic textColor,
  });

  String get _bannerImage {
    switch (bannerType) {
      case BannerType.products:
        return 'lib/core/assets/images/product-banner.png';
      case BannerType.ideas:
        return 'lib/core/assets/images/idea-banner.png';
      case BannerType.colors:
        return 'lib/core/assets/images/colors-banner.png';
      case BannerType.news:
        return 'lib/core/assets/images/news-banner.png';
    }
  }

  String get _bannerTitle {
    switch (bannerType) {
      case BannerType.products:
        return 'Продукты';
      case BannerType.ideas:
        return 'От идеи';
      case BannerType.colors:
        return 'Цвета';
      case BannerType.news:
        return 'Новости';
    }
  }

  String get _bannerSubtitle {
    switch (bannerType) {
      case BannerType.products:
        return 'для вашего дома';
      case BannerType.ideas:
        return 'до реальности';
      case BannerType.colors:
        return 'и оттенки';
      case BannerType.news:
        return 'и события';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Получаем ширину экрана для адаптивности
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        height: screenWidth < 768 ? 150 : 200, // Уменьшаем высоту на мобильных
        margin: const EdgeInsets.only(bottom: 24, top: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100], // Светло-серый фон
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Фоновое изображение
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: screenWidth > 1200
                  ? screenWidth * 0.5
                  : (screenWidth > 768 ? screenWidth * 0.6 : screenWidth * 0.4),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.asset(
                  _bannerImage,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  errorBuilder: (context, error, stackTrace) {
                    // Если изображение не найдено, показываем заглушку
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image, size: 48, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Контент
            Padding(
              padding: EdgeInsets.all(screenWidth < 768 ? 16 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Логотип Remalux (изображение вместо текста)
                  Container(
                    height: screenWidth < 768 ? 40 : 50,
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'lib/core/assets/images/logos/main.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Если изображение не найдено, показываем текст
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          color: const Color(0xFFB32C1B),
                          child: Text(
                            'Remalux®',
                            style: GoogleFonts.montserrat(
                              fontSize: screenWidth < 768 ? 16 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: screenWidth < 768 ? 12 : 20),

                  // Заголовок и подзаголовок
                  Text(
                    _bannerTitle,
                    style: GoogleFonts.ysabeau(
                      fontSize: screenWidth < 768 ? 19 : 22,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B), // Темно-синий цвет
                    ),
                  ),
                  Text(
                    _bannerSubtitle,
                    style: GoogleFonts.ysabeau(
                      fontSize: screenWidth < 768 ? 19 : 22,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B), // Темно-синий цвет
                    ),
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
