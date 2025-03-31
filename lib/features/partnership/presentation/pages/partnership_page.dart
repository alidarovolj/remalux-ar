import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PartnershipPage extends StatelessWidget {
  const PartnershipPage({super.key});

  Future<void> _launchInstagram() async {
    const username = 'remalux.kz';
    final uri = Uri.parse('instagram://user?username=$username');
    final webUri = Uri.parse('https://www.instagram.com/$username');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri);
      }
    } catch (e) {
      debugPrint('Error launching Instagram: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'partnership.title'.tr(),
        showBottomBorder: true,
        showLogo: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'partnership.create_projects'.tr(),
                    style: GoogleFonts.ysabeau(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'partnership.welcome_text'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textIconsSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push('/partnership/application'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'partnership.submit_application'.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'partnership.company_history'.tr(),
                    style: GoogleFonts.ysabeau(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'partnership.history_text'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textIconsSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTimelineItem(
                    year: '1990',
                    text: 'partnership.history.1990'.tr(),
                  ),
                  _buildTimelineItem(
                    year: '1995',
                    text: 'partnership.history.1995'.tr(),
                  ),
                  _buildTimelineItem(
                    year: '2000',
                    text: 'partnership.history.2000'.tr(),
                  ),
                  _buildTimelineItem(
                    year: '2010',
                    text: 'partnership.history.2010'.tr(),
                  ),
                  _buildTimelineItem(
                    year: '2015',
                    text: 'partnership.history.2015'.tr(),
                  ),
                  _buildTimelineItem(
                    year: '2023',
                    text: 'partnership.history.2023'.tr(),
                    isLast: true,
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'partnership.branches.title'.tr(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ysabeau(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'partnership.branches.description'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textIconsSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'lib/core/assets/images/map.png',
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '8000+',
                                style: GoogleFonts.ysabeau(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE31E24),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'partnership.branches.clients'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFE31E24),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'partnership.why_choose_us'.tr(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ysabeau(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'partnership.why_choose_us_desc'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textIconsSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildAdvantageCard(
                    iconPath: 'lib/core/assets/images/partnership/green.png',
                    title: 'partnership.advantages.high_quality'.tr(),
                    description:
                        'partnership.advantages.high_quality_desc'.tr(),
                  ),
                  const SizedBox(height: 16),
                  _buildAdvantageCard(
                    iconPath: 'lib/core/assets/images/partnership/orange.png',
                    title: 'partnership.advantages.competitive_prices'.tr(),
                    description:
                        'partnership.advantages.competitive_prices_desc'.tr(),
                  ),
                  const SizedBox(height: 16),
                  _buildAdvantageCard(
                    iconPath: 'lib/core/assets/images/partnership/pink.png',
                    title: 'partnership.advantages.innovative_tech'.tr(),
                    description:
                        'partnership.advantages.innovative_tech_desc'.tr(),
                  ),
                  const SizedBox(height: 16),
                  _buildAdvantageCard(
                    iconPath: 'lib/core/assets/images/partnership/blue.png',
                    title: 'partnership.advantages.service'.tr(),
                    description: 'partnership.advantages.service_desc'.tr(),
                  ),
                  const SizedBox(height: 16),
                  _buildAdvantageCard(
                    iconPath: 'lib/core/assets/images/partnership/red.png',
                    title: 'partnership.advantages.materials'.tr(),
                    description: 'partnership.advantages.materials_desc'.tr(),
                  ),
                  const SizedBox(height: 16),
                  _buildAdvantageCard(
                    iconPath: 'lib/core/assets/images/partnership/last.png',
                    title: 'partnership.advantages.wide_range'.tr(),
                    description: 'partnership.advantages.wide_range_desc'.tr(),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'partnership.statistics.title'.tr(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ysabeau(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildStatisticsGrid(),
                  const SizedBox(height: 24),
                  _buildProductsGrid(),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'partnership.news.title'.tr(),
                          style: GoogleFonts.ysabeau(
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E384D),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'partnership.news.description'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Color(0xFF2E384D),
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          label: 'partnership.news.instagram'.tr(),
                          onPressed: _launchInstagram,
                          type: ButtonType.normal,
                          isFullWidth: true,
                          isBackGradient: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'partnership.application.title'.tr(),
                          style: GoogleFonts.ysabeau(
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E384D),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'partnership.application.description'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Color(0xFF2E384D),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                context.push('/partnership/application'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFAA2A2F),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'partnership.application.submit'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String year,
    required String text,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE31E24),
              ),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 140,
                color: const Color(0xFFE6E6E6),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                year,
                style: GoogleFonts.ysabeau(
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE31E24),
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvantageCard({
    required String iconPath,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Image.asset(
              iconPath,
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textIconsSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2,
      children: [
        _buildStatItem('15', 'partnership.statistics.years'.tr()),
        _buildStatItem('6', 'partnership.statistics.branches'.tr()),
        _buildStatItem('60+', 'partnership.statistics.employees'.tr()),
        _buildStatItem('185', 'partnership.statistics.projects'.tr()),
      ],
    );
  }

  Widget _buildStatItem(String number, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            number,
            style: GoogleFonts.ysabeau(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textIconsSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, String imagePath, String title,
      String description, Color backgroundColor) {
    return SizedBox(
      height: 90,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -30,
            bottom: -30,
            width: MediaQuery.of(context).size.width * 0.4 / 1.5,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              alignment: Alignment.centerRight,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  flex: 60,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E384D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            color: Color(0xFF2E384D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.6,
        children: [
          _buildProductItem(
            context,
            'lib/core/assets/images/part_prods/1.png',
            'partnership.products.varnish'.tr(),
            'partnership.products.varnish_types'.tr(),
            const Color.fromRGBO(244, 237, 231, 1),
          ),
          _buildProductItem(
            context,
            'lib/core/assets/images/part_prods/2.png',
            'partnership.products.putty'.tr(),
            'partnership.products.putty_types'.tr(),
            const Color.fromRGBO(178, 192, 212, 1),
          ),
          _buildProductItem(
            context,
            'lib/core/assets/images/part_prods/3.png',
            'partnership.products.coating'.tr(),
            'partnership.products.coating_types'.tr(),
            const Color.fromRGBO(187, 205, 175, 1),
          ),
          _buildProductItem(
            context,
            'lib/core/assets/images/part_prods/4.png',
            'partnership.products.enamel'.tr(),
            'partnership.products.enamel_types'.tr(),
            const Color.fromRGBO(244, 237, 231, 1),
          ),
          _buildProductItem(
            context,
            'lib/core/assets/images/part_prods/5.png',
            'partnership.products.glue'.tr(),
            'partnership.products.glue_types'.tr(),
            const Color.fromRGBO(178, 192, 212, 1),
          ),
        ],
      );
    });
  }
}
