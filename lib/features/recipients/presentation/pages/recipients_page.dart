import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/features/recipients/domain/services/recipients_service.dart';
import 'package:remalux_ar/features/recipients/presentation/widgets/add_recipient_sheet.dart';
import 'package:remalux_ar/core/widgets/custom_snack_bar.dart';
import 'package:remalux_ar/core/styles/constants.dart';

final recipientsProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    return await ref.read(recipientsServiceProvider).getRecipients();
  } catch (e) {
    print('Error fetching recipients: $e');
    return [];
  }
});

class RecipientsPage extends ConsumerWidget {
  const RecipientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipientsAsync = ref.watch(recipientsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Получатели',
        showBottomBorder: true,
      ),
      body: Column(
        children: [
          // Add recipient button
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => const AddRecipientSheet(),
                  );
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add,
                        color: Colors.blue,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Добавить нового получателя',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
          ),
          const SizedBox(height: 8),
          // Recipients list
          Expanded(
            child: recipientsAsync.when(
              data: (recipients) {
                if (recipients.isEmpty) {
                  return const Center(
                    child: Text('У вас пока нет получателей'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recipients.length,
                  itemBuilder: (context, index) {
                    final recipient = recipients[index];
                    return Dismissible(
                      key: Key(recipient.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (direction) async {
                        try {
                          await ref
                              .read(recipientsServiceProvider)
                              .deleteRecipient(recipient.id);
                          ref.refresh(recipientsProvider);

                          if (context.mounted) {
                            CustomSnackBar.show(
                              context,
                              message: 'Получатель удален',
                              type: SnackBarType.success,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            CustomSnackBar.show(
                              context,
                              message: 'Ошибка при удалении получателя',
                              type: SnackBarType.error,
                            );
                          }
                        }
                      },
                      child: Container(
                        height: 68,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          minLeadingWidth: 0,
                          minVerticalPadding: 0,
                          title: Text(
                            recipient.name,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                          subtitle: Text(
                            recipient.phoneNumber,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.2,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_horiz),
                            onPressed: () {
                              // TODO: Implement edit functionality
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Text('Ошибка: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
