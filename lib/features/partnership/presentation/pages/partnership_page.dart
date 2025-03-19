import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';

class PartnershipPage extends StatelessWidget {
  const PartnershipPage({super.key});

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
              padding: const EdgeInsets.all(16.0),
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
                    onPressed: () {
                      // TODO: Implement submit application logic
                    },
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
                                'partnership.branches.clients'
                                    .tr()
                                    .toLowerCase(),
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
                color: Color(0xFFE6E6E6),
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
                  color: Color(0xFFE31E24),
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
}
