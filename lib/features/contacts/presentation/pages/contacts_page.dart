import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/features/contacts/domain/providers/contacts_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(contactsProvider.notifier).refreshContacts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Наши филиалы',
        showBottomBorder: true,
      ),
      body: contacts.when(
        data: (contactsList) {
          if (_tabController == null ||
              _tabController.length != contactsList.length) {
            _tabController = TabController(
              length: contactsList.length,
              vsync: this,
              initialIndex: _selectedIndex,
            );
            _tabController.addListener(() {
              setState(() {
                _selectedIndex = _tabController.index;
              });
            });
          }

          return Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: contactsList
                    .map((contact) => Tab(
                          text: contact.city.title.ru,
                        ))
                    .toList(),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: contactsList.map((contact) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: contact.innerItems.length,
                      itemBuilder: (context, index) {
                        final item = contact.innerItems[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.address.ru,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => launchUrl(
                                        Uri.parse('tel:${item.mainPhone}'),
                                      ),
                                      child: Text(
                                        item.mainPhone,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    if (item.contactItems.phone.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      ...item.contactItems.phone.map(
                                        (phone) => GestureDetector(
                                          onTap: () => launchUrl(
                                            Uri.parse('tel:${phone.value}'),
                                          ),
                                          child: Text(
                                            phone.value,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.blue,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => launchUrl(
                                        Uri.parse('mailto:${item.mainEmail}'),
                                      ),
                                      child: Text(
                                        item.mainEmail,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    if (item.contactItems.email.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      ...item.contactItems.email.map(
                                        (email) => GestureDetector(
                                          onTap: () => launchUrl(
                                            Uri.parse('mailto:${email.value}'),
                                          ),
                                          child: Text(
                                            email.value,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.blue,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Color(0xFFEEEEEE),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'График работы',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Пн',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: item.workTime[0]
                                                            .startTime !=
                                                        null
                                                    ? AppColors.textPrimary
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              'Вт',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: item.workTime[1]
                                                            .startTime !=
                                                        null
                                                    ? AppColors.textPrimary
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              'Ср',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: item.workTime[2]
                                                            .startTime !=
                                                        null
                                                    ? AppColors.textPrimary
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              'Чт',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: item.workTime[3]
                                                            .startTime !=
                                                        null
                                                    ? AppColors.textPrimary
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              'Пт',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: item.workTime[4]
                                                            .startTime !=
                                                        null
                                                    ? AppColors.textPrimary
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              'Сб',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: item.workTime[5]
                                                            .startTime !=
                                                        null
                                                    ? AppColors.textPrimary
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              'Вс',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: item.workTime[6]
                                                            .startTime !=
                                                        null
                                                    ? AppColors.textPrimary
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: item.workTime
                                              .map(
                                                (workTime) => Text(
                                                  workTime.startTime != null
                                                      ? '${workTime.startTime} - ${workTime.endTime}'
                                                      : 'Выходной',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: workTime.startTime !=
                                                            null
                                                        ? AppColors.textPrimary
                                                        : AppColors
                                                            .textSecondary,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    ),
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
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
