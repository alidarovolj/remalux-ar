import 'package:flutter/material.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LocationBottomSheet extends StatelessWidget {
  const LocationBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppLength.body),
            topRight: Radius.circular(AppLength.body),
          ),
        ),
        child: const _LocationContent(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => LocationBottomSheet.show(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'lib/core/assets/icons/pin_filled.svg',
            width: AppLength.xl,
            height: AppLength.xl,
            colorFilter: const ColorFilter.mode(
              AppColors.primary,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            "Пушкина 32",
            style: TextStyle(
              fontSize: AppLength.body,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const Icon(
            Icons.arrow_drop_down,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _LocationContent extends StatelessWidget {
  const _LocationContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppLength.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Местоположение',
                  style: TextStyle(
                    fontSize: AppLength.xl,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppLength.body),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppLength.xs),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Поиск адреса',
                    border: InputBorder.none,
                    prefixIcon:
                        Icon(Icons.search, color: AppColors.textSecondary),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppLength.body,
                      vertical: AppLength.sm,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppLength.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    'lib/core/assets/icons/pin_filled.svg',
                    width: AppLength.xl,
                    height: AppLength.xl,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: AppLength.xs),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Текущее местоположение',
                        style: TextStyle(
                          fontSize: AppLength.body,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Пушкина 39, Алматы',
                        style: TextStyle(
                          fontSize: AppLength.sm,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(
            left: AppLength.xs,
            right: AppLength.xs,
            bottom: AppLength.body,
          ),
          child: Divider(
            height: AppLength.xs,
            thickness: 1,
            color: AppColors.backgroundLight,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppLength.xs),
          child: Text(
            'Сохраненные адреса',
            style: TextStyle(
              fontSize: AppLength.xxl,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
            child: ListView(
              children: [
                _AddressItem(
                  address: 'Достык 77',
                  isSelected: false,
                  onTap: () {},
                ),
                _AddressItem(
                  address: 'Гагарина 12',
                  isSelected: false,
                  onTap: () {},
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppLength.body),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'lib/core/assets/icons/plus.svg',
                        width: AppLength.body,
                        height: AppLength.body,
                        colorFilter: const ColorFilter.mode(
                          AppColors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: AppLength.xs),
                      const Text(
                        'Добавить новый адрес',
                        style: TextStyle(
                            fontSize: AppLength.body,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressItem extends StatelessWidget {
  final String address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressItem({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: AppLength.body),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset(
              'lib/core/assets/icons/pin_filled.svg',
              width: AppLength.xl,
              height: AppLength.xl,
              colorFilter: const ColorFilter.mode(
                AppColors.primary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: AppLength.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Текущий адрес',
                  style: TextStyle(
                    fontSize: AppLength.body,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: AppLength.body,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Radio(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
