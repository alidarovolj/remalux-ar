import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/features/addresses/domain/providers/addresses_provider.dart';
import 'package:remalux_ar/core/widgets/custom_snack_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

class AddressesPage extends ConsumerStatefulWidget {
  const AddressesPage({super.key});

  @override
  ConsumerState<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends ConsumerState<AddressesPage> {
  @override
  void initState() {
    super.initState();
    print('📱 AddressesPage initState');
    // Force refresh addresses on page visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshAddresses();
      }
    });
  }

  Future<void> _refreshAddresses() async {
    print('🔄 Force refreshing addresses');
    try {
      print('📱 Starting addresses refresh');
      await ref.read(addressesProvider.notifier).refreshAddresses();
      print('✅ Addresses refresh completed successfully');
    } catch (error) {
      print('❌ Addresses refresh failed: $error');
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'addresses.error.refresh'.tr(),
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
    final addresses = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'addresses.title'.tr(),
        showBottomBorder: true,
      ),
      body: addresses.when(
        data: (addressesList) {
          if (addressesList.isEmpty) {
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
                        'addresses.empty.title'.tr(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ysabeau(
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1,
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
                        context.pushNamed('add_address').then((_) {
                          // Refresh addresses when returning from the add page
                          _refreshAddresses();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'addresses.add.button'.tr(),
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
              // Add address button
              Padding(
                padding: const EdgeInsets.all(12),
                child: InkWell(
                  onTap: () {
                    context.pushNamed('add_address').then((_) {
                      // Refresh addresses when returning from the add page
                      _refreshAddresses();
                    });
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
                          'addresses.add.new'.tr(),
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
              // Addresses list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: addressesList.length,
                  itemBuilder: (context, index) {
                    final address = addressesList[index];
                    return Dismissible(
                      key: Key(address.id.toString()),
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
                              .read(addressesProvider.notifier)
                              .deleteAddress(address.id);
                          if (context.mounted) {
                            CustomSnackBar.show(
                              context,
                              message: 'addresses.delete.success'.tr(),
                              type: SnackBarType.success,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            CustomSnackBar.show(
                              context,
                              message: 'addresses.delete.error'.tr(),
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
                            address.address,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                          subtitle: address.entrance != null ||
                                  address.floor != null ||
                                  address.apartment != null
                              ? Text(
                                  [
                                    if (address.entrance != null)
                                      'addresses.details.entrance'
                                          .tr(args: [address.entrance!]),
                                    if (address.floor != null)
                                      'addresses.details.floor'
                                          .tr(args: [address.floor!]),
                                    if (address.apartment != null)
                                      'addresses.details.apartment'
                                          .tr(args: [address.apartment!]),
                                  ].join(', '),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                    height: 1.2,
                                  ),
                                )
                              : null,
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              try {
                                await ref
                                    .read(addressesProvider.notifier)
                                    .deleteAddress(address.id);
                                if (context.mounted) {
                                  CustomSnackBar.show(
                                    context,
                                    message: 'addresses.delete.success'.tr(),
                                    type: SnackBarType.success,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  CustomSnackBar.show(
                                    context,
                                    message: 'addresses.delete.error'.tr(),
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
            // Add address button skeleton
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
            // Addresses list skeleton
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 6, // Show 6 skeleton items
                itemBuilder: (context, index) => const _AddressSkeletonItem(),
              ),
            ),
          ],
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'addresses.error'.tr(args: [error.toString()]),
          ),
        ),
      ),
    );
  }
}

class _AddressSkeletonItem extends StatelessWidget {
  const _AddressSkeletonItem();

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
                width: 200,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 160,
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
