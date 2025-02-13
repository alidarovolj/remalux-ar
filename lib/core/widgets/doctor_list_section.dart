import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/providers/requests/doctor_provider.dart';
import 'package:remalux_ar/core/widgets/section_widget.dart';
import 'package:remalux_ar/core/widgets/visit_card.dart';
import 'package:remalux_ar/core/types/visit_card_type.dart';

class DoctorListSection extends ConsumerWidget {
  final String title;
  final String? leadingIcon;
  final String? buttonTitle;
  final VoidCallback? onButtonPressed;
  final Map<String, dynamic> filters;
  final bool isCompact;

  const DoctorListSection({
    super.key,
    required this.title,
    this.leadingIcon,
    this.buttonTitle,
    this.onButtonPressed,
    this.filters = const {},
    this.isCompact = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(doctorsProvider);

    return SectionWidget(
      title: title,
      leadingIcon: leadingIcon,
      buttonTitle: buttonTitle,
      onButtonPressed: onButtonPressed,
      child: doctorsAsync.when(
        data: (doctors) {
          // Apply filters
          final filteredDoctors = doctors.where((doctor) {
            bool passes = true;
            filters.forEach((key, value) {
              switch (key) {
                case 'specialization':
                  passes &= doctor.specializations.contains(value);
                  break;
                case 'experience':
                  passes &= doctor.about.experience >= value;
                  break;
              }
            });
            return passes;
          }).toList();

          if (filteredDoctors.isEmpty) {
            return const SizedBox.shrink();
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filteredDoctors.map((doctor) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: VisitCard(
                    isCompact: isCompact,
                    cardData: VisitCardType(
                      id: doctor.id.toString(),
                      name: doctor.fullName,
                      rating: 0.0,
                      specialization: doctor.specializations.isNotEmpty
                          ? doctor.specializations.first
                          : 'Специалист',
                      experience: doctor.about.experience,
                      location: 'Не указано',
                      price: 'По запросу',
                      avatar: doctor.about.icon,
                      onDetails: () {
                        debugPrint('Show details for ${doctor.fullName}');
                      },
                      onReschedule: () {
                        debugPrint(
                            'Reschedule appointment for ${doctor.fullName}');
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Ошибка: $error')),
      ),
    );
  }
}
