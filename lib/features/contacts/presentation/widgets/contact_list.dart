import 'package:flutter/material.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/contacts/data/models/contact_model.dart';
import 'package:remalux_ar/features/contacts/presentation/widgets/yandex_map_view.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactList extends StatelessWidget {
  final List<Contact> contacts;

  const ContactList({
    super.key,
    required this.contacts,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...contact.innerItems
                .map((item) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Address with icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 20,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.address.ru,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Phone with icon
                        if (item.mainPhone != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => launchUrl(
                                      Uri.parse('tel:${item.mainPhone}')),
                                  child: Text(
                                    item.mainPhone!,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Email with icon
                        if (item.mainEmail != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.email_outlined,
                                    size: 20,
                                    color: AppColors.textPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => launchUrl(
                                        Uri.parse('mailto:${item.mainEmail}')),
                                    child: Text(
                                      item.mainEmail!,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Map and Work schedule in a row
                        if (item.latitude != null && item.longitude != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Work schedule
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'График работы',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Work days
                                    ...[
                                      'Пн',
                                      'Вт',
                                      'Ср',
                                      'Чт',
                                      'Пт',
                                      'Сб',
                                      'Вс'
                                    ].asMap().entries.map(
                                      (entry) {
                                        final workTime =
                                            item.workTime[entry.key];
                                        final isWorkDay =
                                            workTime.startTime != null;

                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 32,
                                                child: Text(
                                                  entry.value,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: isWorkDay
                                                        ? AppColors.textPrimary
                                                        : AppColors
                                                            .textSecondary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                isWorkDay
                                                    ? '${workTime.startTime} - ${workTime.endTime}'
                                                    : 'Выходной',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: isWorkDay
                                                      ? AppColors.textPrimary
                                                      : AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    // Break time
                                    if (item.breakTime.startTime != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Перерыв: ${item.breakTime.startTime} - ${item.breakTime.endTime}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Map
                              Expanded(
                                child: Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.backgroundLight,
                                      width: 1,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: YandexMapView(
                                    latitude: double.parse(item.latitude!),
                                    longitude: double.parse(item.longitude!),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        // Additional contacts
                        if (item.contactItems.phone.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ...item.contactItems.phone.map(
                            (phone) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.phone_outlined,
                                    size: 24,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => launchUrl(
                                        Uri.parse('tel:${phone.value}')),
                                    child: Text(
                                      phone.value,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        if (item.contactItems.email.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ...item.contactItems.email.map(
                            (email) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => launchUrl(
                                          Uri.parse('mailto:${email.value}')),
                                      child: Text(
                                        email.value,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                      ],
                    ))
                .toList(),
          ],
        );
      },
    );
  }
}
