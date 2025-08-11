import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/features/recipients/domain/providers/recipients_provider.dart';
import 'package:remalux_ar/features/recipients/presentation/widgets/add_recipient_sheet.dart';
import 'package:remalux_ar/core/widgets/custom_snack_bar.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';

class RecipientsPage extends ConsumerStatefulWidget {
  const RecipientsPage({super.key});

  @override
  ConsumerState<RecipientsPage> createState() => _RecipientsPageState();
}

class _RecipientsPageState extends ConsumerState<RecipientsPage> {
  @override
  void initState() {
    super.initState();
    // Force refresh recipients on page visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshRecipients();
      }
    });
  }

  Future<void> _refreshRecipients() async {
    try {
      await ref.read(recipientsProvider.notifier).refreshRecipients();
    } catch (error) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'recipients.error.refresh'.tr(),
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Remove refresh call from here to avoid setState during build
  }

  @override
  Widget build(BuildContext context) {
    final recipientsAsync = ref.watch(recipientsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'recipients.title'.tr(),
        showBottomBorder: true,
      ),
      body: recipientsAsync.when(
        data: (recipients) {
          if (recipients.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 96,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'recipients.empty.message'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'recipients.add'.tr(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              // Add recipient button
              Padding(
                padding: const EdgeInsets.all(12),
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
                          'recipients.add_new'.tr(),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Recipients list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                              message: 'recipients.deleted'.tr(),
                              type: SnackBarType.success,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            CustomSnackBar.show(
                              context,
                              message: 'recipients.error.delete'.tr(),
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
                            horizontal: 12,
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
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              try {
                                await ref
                                    .read(recipientsServiceProvider)
                                    .deleteRecipient(recipient.id);
                                ref.refresh(recipientsProvider);

                                if (context.mounted) {
                                  CustomSnackBar.show(
                                    context,
                                    message: 'recipients.deleted'.tr(),
                                    type: SnackBarType.success,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  CustomSnackBar.show(
                                    context,
                                    message: 'recipients.error.delete'.tr(),
                                    type: SnackBarType.error,
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => Column(
          children: [
            // Add recipient button skeleton
            Padding(
              padding: const EdgeInsets.all(12),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Recipients list skeleton
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 6, // Show 6 skeleton items
                itemBuilder: (context, index) => const _RecipientSkeletonItem(),
              ),
            ),
          ],
        ),
        error: (error, stackTrace) => Center(
          child: Text('recipients.error.generic'.tr() + ': $error'),
        ),
      ),
    );
  }
}

class _RecipientSkeletonItem extends StatelessWidget {
  const _RecipientSkeletonItem();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
