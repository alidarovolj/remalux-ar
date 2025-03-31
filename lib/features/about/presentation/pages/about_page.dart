import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      'lib/core/assets/images/logos/main.png',
                      height: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'about.info_section.title'.tr(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ysabeau(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'about.info_section.description'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textIconsSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    title: 'about.info_section.items.technology.title'.tr(),
                    description:
                        'about.info_section.items.technology.description'.tr(),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    title: 'about.info_section.items.service.title'.tr(),
                    description:
                        'about.info_section.items.service.description'.tr(),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    title: 'about.info_section.items.assortment.title'.tr(),
                    description:
                        'about.info_section.items.assortment.description'.tr(),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    title: 'about.info_section.items.safety.title'.tr(),
                    description:
                        'about.info_section.items.safety.description'.tr(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textIconsSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForWhomSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage('lib/core/assets/images/for_whom.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.only(
            left: 12,
            top: 12,
            right: 64,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'about.for_whom.title'.tr(),
                style: GoogleFonts.ysabeau(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'about.for_whom.description'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvantageItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textIconsSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarFleetSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    'about.car_fleet.title'.tr(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ysabeau(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'about.car_fleet.description'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textIconsSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 200,
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'lib/core/assets/images/about_cars.png',
                      fit: BoxFit.cover,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'about.title'.tr(),
        showBottomBorder: false,
        showLogo: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'lib/core/assets/images/about-bg.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAdvantageItem(
                    icon: Icons.verified,
                    title: 'about.advantages.quality.title'.tr(),
                    description: 'about.advantages.quality.description'.tr(),
                  ),
                  _buildAdvantageItem(
                    icon: Icons.attach_money,
                    title: 'about.advantages.price.title'.tr(),
                    description: 'about.advantages.price.description'.tr(),
                  ),
                  _buildAdvantageItem(
                    icon: Icons.science,
                    title: 'about.advantages.technology.title'.tr(),
                    description: 'about.advantages.technology.description'.tr(),
                  ),
                  _buildAdvantageItem(
                    icon: Icons.support_agent,
                    title: 'about.advantages.service.title'.tr(),
                    description: 'about.advantages.service.description'.tr(),
                  ),
                  _buildAdvantageItem(
                    icon: Icons.inventory_2,
                    title: 'about.advantages.materials.title'.tr(),
                    description: 'about.advantages.materials.description'.tr(),
                  ),
                  _buildAdvantageItem(
                    icon: Icons.category,
                    title: 'about.advantages.assortment.title'.tr(),
                    description: 'about.advantages.assortment.description'.tr(),
                  ),
                ],
              ),
            ),
            _buildForWhomSection(),
            const SizedBox(height: 16),
            _buildInfoSection(),
            const SizedBox(height: 16),
            _buildCarFleetSection(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'about.to_products'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
