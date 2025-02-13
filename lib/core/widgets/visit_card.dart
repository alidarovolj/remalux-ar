import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/types/visit_card_type.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VisitCard extends StatelessWidget {
  final VisitCardType cardData;
  final bool isCompact;

  const VisitCard({
    super.key,
    required this.cardData,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return isCompact
        ? CompactVisitCard(cardData: cardData)
        : FullVisitCard(cardData: cardData);
  }
}

class CompactVisitCard extends StatelessWidget {
  final VisitCardType cardData;

  const CompactVisitCard({
    super.key,
    required this.cardData,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/doctor-details/${cardData.id}');
      },
      borderRadius:
          BorderRadius.circular(AppLength.body), // Закругление при нажатии
      child: Container(
        width: 128,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppLength.body),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: AppLength.tiny,
              offset: const Offset(0, AppLength.four),
            ),
          ],
        ),
        margin: const EdgeInsets.only(
            left: AppLength.xs,
            top: AppLength.four,
            bottom: AppLength.four), // Отступы 12px вокруг карточки
        child: Padding(
          padding: const EdgeInsets.only(
              right: AppLength.tiny, left: AppLength.tiny, top: AppLength.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Аватар
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(cardData.avatar),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppLength.tiny, vertical: AppLength.four),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppLength.body),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: AppLength.body,
                          ),
                          const SizedBox(width: AppLength.four),
                          Row(
                            children: [
                              Text(
                                cardData.rating.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: AppLength.sm,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Text(
                                ' (30)',
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: AppLength.sm,
                                  color: AppColors.secondary,
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Имя
              Text(
                cardData.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: AppLength.sm,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Специализация
              Text(
                cardData.specialization,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: AppLength.xs,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppLength.xs),
              // CustomButton(
              //   label: 'Записаться',
              //   onPressed: () {
              //     context.push('/doctor-details/${cardData.id}');
              //   },
              //   type: ButtonType.small,
              //   isFullWidth: true,
              // ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 32),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppLength.none, vertical: AppLength.none),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppLength.xs),
                    ),
                  ),
                  onPressed: () {
                    context.push('/doctor-details/${cardData.id}');
                  },
                  child: const Text('Записаться',
                      style: TextStyle(
                          color: AppColors.white, fontSize: AppLength.sm)))
            ],
          ),
        ),
      ),
    );
  }
}

class FullVisitCard extends StatelessWidget {
  final VisitCardType cardData;

  const FullVisitCard({
    super.key,
    required this.cardData,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/doctor-details/${cardData.id}');
      },
      borderRadius: BorderRadius.circular(AppLength.body),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppLength.body),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: AppLength.tiny,
              offset: const Offset(0, AppLength.four),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(
          vertical: AppLength.tiny,
          horizontal: AppLength.xs,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppLength.body),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppLength.xs),
                      image: DecorationImage(
                        image: NetworkImage(cardData.avatar),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: cardData.avatar.isEmpty
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  const SizedBox(width: AppLength.body),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cardData.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppLength.four),
                        Text(
                          cardData.specialization,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: AppLength.body,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppLength.four),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${cardData.rating} (30)',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: AppLength.sm,
                              ),
                            ),
                            Text(
                              ' • Стаж работы ${cardData.experience} лет',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: AppLength.sm,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppLength.body),
              Row(
                children: [
                  SvgPicture.asset(
                    'lib/core/assets/icons/pin.svg',
                    colorFilter: const ColorFilter.mode(
                      AppColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: AppLength.four),
                  Text(
                    cardData.location,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppLength.sm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppLength.xs),
              Row(
                children: [
                  SvgPicture.asset(
                    'lib/core/assets/icons/money.svg',
                    colorFilter: const ColorFilter.mode(
                      AppColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: AppLength.four),
                  Text(
                    'от ${cardData.price} ₸ за прием',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppLength.sm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppLength.body),
              Container(
                padding: const EdgeInsets.all(AppLength.xs),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppLength.body),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset(
                                'lib/core/assets/icons/calendar.svg',
                                width: 14,
                                height: 14,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.secondary,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: AppLength.tiny),
                              const Text(
                                'Доступно на сегодня',
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: AppLength.sm,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppLength.xs,
                              vertical: AppLength.four,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEE5FF),
                              borderRadius: BorderRadius.circular(AppLength.xl),
                            ),
                            child: const Text(
                              '10 Мест',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: AppLength.details,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ]),
                    const SizedBox(height: AppLength.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                const _TimeSlot(time: '9:30'),
                                const _TimeSlot(time: '10:30'),
                                const _TimeSlot(time: '11:00'),
                                const _TimeSlot(time: '11:00'),
                                const _TimeSlot(time: '11:00'),
                                Container(
                                  padding: const EdgeInsets.all(AppLength.tiny),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius:
                                        BorderRadius.circular(AppLength.xl),
                                  ),
                                  child: const Text(
                                    'Еще +5',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: AppLength.sm,
                                    ),
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
              const SizedBox(height: AppLength.body),
              CustomButton(
                label: 'Выбрать время и записаться',
                onPressed: () {
                  context.push('/doctor-details/${cardData.id}');
                },
                type: ButtonType.normal,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeSlot extends StatelessWidget {
  final String time;

  const _TimeSlot({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppLength.tiny),
      padding: const EdgeInsets.all(AppLength.tiny),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppLength.xs),
      ),
      child: Text(
        time,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
