import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:remalux_ar/core/styles/constants.dart';

class CustomTabBar extends StatelessWidget {
  final TabController tabController;

  const CustomTabBar({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: const Border(
              top: BorderSide(
                color: AppColors.borderColor,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: TabBar(
              controller: tabController,
              indicatorColor: Colors.transparent,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textPrimary,
              labelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  icon: SvgPicture.asset(
                    'lib/core/assets/icons/tabs/1.svg',
                    colorFilter: ColorFilter.mode(
                      tabController.index == 0
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  text: "Главная",
                ),
                Tab(
                  icon: SvgPicture.asset(
                    'lib/core/assets/icons/tabs/2.svg',
                    colorFilter: ColorFilter.mode(
                      tabController.index == 1
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  text: "Каталог",
                ),
                const Tab(
                  height: 65,
                  child: Padding(
                    padding: EdgeInsets.only(top: 22),
                    child: Text(
                      "AR",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                Tab(
                  icon: SvgPicture.asset(
                    'lib/core/assets/icons/tabs/3.svg',
                    colorFilter: ColorFilter.mode(
                      tabController.index == 3
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  text: "Корзина",
                ),
                Tab(
                  icon: SvgPicture.asset(
                    'lib/core/assets/icons/tabs/4.svg',
                    colorFilter: ColorFilter.mode(
                      tabController.index == 4
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  text: "Профиль",
                ),
              ],
            ),
          ),
        ),
        // AR Cube Icon
        Positioned(
          top: -20,
          left: 0,
          right: 0,
          child: Center(
            child: Image.asset(
              'lib/core/assets/images/cube.png',
              width: 50,
              height: 58,
            ),
          ),
        ),
      ],
    );
  }
}
