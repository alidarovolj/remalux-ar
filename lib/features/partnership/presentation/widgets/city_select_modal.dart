import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/partnership/domain/models/city.dart';

class CitySelectModal extends StatelessWidget {
  final List<City> cities;
  final String? selectedCity;
  final Function(String) onSelect;

  const CitySelectModal({
    super.key,
    required this.cities,
    required this.selectedCity,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              const SizedBox(height: 8),
              Text(
                'partnership.form.select_city'.tr(),
                style: GoogleFonts.ysabeau(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: cities.map((city) {
                  final cityName = context.locale.languageCode == 'kk'
                      ? city.titleKz
                      : context.locale.languageCode == 'en'
                          ? city.titleEn
                          : city.title;
                  final isSelected = selectedCity == cityName;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: AppColors.borderDark, width: 1)
                          : null,
                    ),
                    child: Theme(
                      data: ThemeData(
                        radioTheme: RadioThemeData(
                          fillColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.selected)) {
                                return AppColors.primary;
                              }
                              return const Color(0xFFDDDDDD);
                            },
                          ),
                        ),
                      ),
                      child: RadioListTile<String>(
                        value: cityName,
                        groupValue: selectedCity,
                        onChanged: (String? value) {
                          if (value != null) {
                            onSelect(value);
                            Navigator.pop(context);
                          }
                        },
                        title: Text(
                          cityName,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                        dense: true,
                        visualDensity: const VisualDensity(horizontal: -4),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
