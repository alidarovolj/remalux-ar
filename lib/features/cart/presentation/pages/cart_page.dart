import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dio/dio.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:remalux_ar/features/cart/domain/providers/cart_provider.dart';
import 'package:remalux_ar/features/cart/domain/models/cart_item.dart';
import 'package:remalux_ar/features/cart/presentation/widgets/delete_confirmation_dialog.dart';
import 'package:remalux_ar/features/cart/presentation/widgets/delete_confirmation_modal.dart';
import 'package:remalux_ar/features/cart/presentation/widgets/cart_skeleton.dart';
import 'package:remalux_ar/core/providers/auth/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remalux_ar/core/api/api_client.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage>
    with WidgetsBindingObserver {
  String currentLocale = 'ru';
  Set<int> selectedItems = {};
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    print('📱 CartPage initState');
    // Register observer for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        currentLocale = context.locale.languageCode;
      });

      // Check authentication status
      _checkAuthStatus();

      // Force refresh cart data
      ref.invalidate(cartProvider);

      // Always fetch cart on initialization
      _refreshCart();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Check auth status when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _checkAuthStatus();
    }
  }

  @override
  void didUpdateWidget(CartPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check auth status when widget updates (e.g., when returning to the page)
    _checkAuthStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLocale = context.locale.languageCode;
    if (currentLocale != newLocale) {
      setState(() {
        currentLocale = newLocale;
      });
    }

    // Check auth status every time dependencies change
    _checkAuthStatus();

    // Listen for cart data changes
    final cartData = ref.watch(cartProvider);
    cartData.whenData((items) {
      if (items.isNotEmpty && !_isAuthenticated) {
        setState(() {
          _isAuthenticated = true;
        });
      }
    });
  }

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Check if there is a valid token in both SharedPreferences and ApiClient
      ApiClient apiClient = ApiClient();
      bool apiHasToken = apiClient.accessToken != null;

      final isAuthenticated = token != null && token.isNotEmpty && apiHasToken;

      print(
          '🔑 Auth check: ${isAuthenticated ? 'Authenticated' : 'Not authenticated'} '
          '(token in prefs: ${token != null}, API token: ${apiHasToken ? 'exists' : 'missing'})');

      if (_isAuthenticated != isAuthenticated) {
        setState(() {
          _isAuthenticated = isAuthenticated;
        });

        // If authentication status changed and user is now logged out, invalidate cart
        if (!isAuthenticated) {
          ref.invalidate(cartProvider);
        }
      }
    } catch (e) {
      print('❌ Error checking auth status: $e');
      setState(() {
        _isAuthenticated = false;
      });
    }
  }

  void _refreshCart() {
    if (!_isAuthenticated) {
      print('⚠️ Not refreshing cart because user is not authenticated');
      return;
    }

    ref.read(cartProvider.notifier).getCart().then((_) {
      print('✅ Cart refresh completed');

      // Check cart data after refresh
      final cartData = ref.read(cartProvider);
      cartData.whenData((items) {
        if (items.isNotEmpty) {
          setState(() {
            _isAuthenticated = true;
          });
        }
      });
    }).catchError((error) {
      print('❌ Cart refresh failed: $error');
      // If we get a 401, update our authentication status
      if (error is DioException && error.response?.statusCode == 401) {
        setState(() {
          _isAuthenticated = false;
        });
      }
    });
  }

  void toggleSelectAll(List<CartItem> items) {
    setState(() {
      if (selectedItems.length == items.length) {
        selectedItems.clear();
      } else {
        selectedItems = items.map((item) => item.id).toSet();
      }
    });
  }

  void toggleItemSelection(int itemId) {
    setState(() {
      if (selectedItems.contains(itemId)) {
        selectedItems.remove(itemId);
      } else {
        selectedItems.add(itemId);
      }
    });
  }

  void deleteSelectedItems() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeleteConfirmationModal(
        title: 'store.cart.delete_selected_title'.tr(),
        message: 'store.cart.delete_selected_message'.tr(namedArgs: {
          'count': selectedItems.length.toString(),
        }),
        onConfirm: () {
          for (final itemId in selectedItems) {
            ref.read(cartProvider.notifier).removeItem(itemId);
          }
          selectedItems.clear();
        },
      ),
    );
  }

  Widget _buildSelectionHeader(List<CartItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Select All button
          InkWell(
            onTap: () => toggleSelectAll(items),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: selectedItems.length == items.length
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: selectedItems.length == items.length
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: selectedItems.length == items.length
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'store.cart.select_all'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Delete Selected button
          if (selectedItems.isNotEmpty)
            TextButton(
              onPressed: deleteSelectedItems,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.links,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'store.cart.delete_selected'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.links,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    print('🎨 CartPage building with state: ${cartAsync.toString()}');

    // Check if we have items in the cart
    bool hasCartItems = cartAsync.maybeWhen(
      data: (items) => items.isNotEmpty,
      orElse: () => false,
    );

    // If we have items, we must be authenticated
    if (hasCartItems && !_isAuthenticated) {
      setState(() {
        _isAuthenticated = true;
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'common.tabs.cart'.tr(),
      ),
      body: cartAsync.when(
        data: (items) {
          // If we have items, we are definitely authenticated
          if (items.isNotEmpty) {
            return Column(
              children: [
                _buildSelectionHeader(items),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length + 1, // +1 for the bottom bar
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return _buildBottomBar(context);
                      }
                      return _buildCartItem(items[index]);
                    },
                  ),
                ),
              ],
            );
          }

          // Otherwise, check authentication status
          if (!_isAuthenticated) {
            return _buildAuthRequiredView(context);
          }

          // Empty cart for authenticated user
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'store.cart.empty.title'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'store.cart.empty.description'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const Spacer(),
                  CustomButton(
                    label: 'store.cart.empty.to_catalog'.tr(),
                    onPressed: () => context.push('/store'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
        loading: () => const CartSkeleton(),
        error: (error, stackTrace) {
          print('❌ Cart error: $error');
          if (error is DioException && error.response?.statusCode == 401) {
            // Update authentication status and return the auth required view
            setState(() {
              _isAuthenticated = false;
            });
            return _buildAuthRequiredView(context);
          }
          return Center(
            child: Text(
              'store.cart.error'.tr(),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuthRequiredView(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'store.cart.auth_required'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                label: 'auth.login_button'.tr(),
                onPressed: () => context.push('/login'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    final isSelected = selectedItems.contains(item.id);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image with Checkbox overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.productImage,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ Error loading image: $error');
                    return Container(
                      width: 80,
                      height: 80,
                      color: AppColors.borderDark,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: GestureDetector(
                  onTap: () => toggleItemSelection(item.id),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Total Price
                    Text(
                      '${(double.parse(item.productVariant.price.toString()) * item.quantity).toStringAsFixed(0)} ${'common.currency'.tr()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    // Favorite button
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: item.productVariant.is_favourite
                            ? AppColors.buttonSecondary
                            : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.favorite,
                          color: item.productVariant.is_favourite
                              ? AppColors.primary
                              : Colors.grey,
                          size: 18,
                        ),
                        onPressed: () {
                          // TODO: Implement favorite toggle
                        },
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Price per unit
                Text(
                  '${item.productVariant.price} ${'common.currency'.tr()} / 1 ${'common.kg'.tr()}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                // Title
                Text(
                  item.productTitle[currentLocale] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                // Color and Weight
                if (item.colorId != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Color(int.parse(
                              '0xFF${item.colorId!['hex'].substring(1)}')),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Text(
                        item.colorId!['title'][currentLocale] ??
                            item.colorId!['title']['ru'] ??
                            '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Quantity Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Delete button
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => DeleteConfirmationModal(
                              title: 'store.cart.delete_item_title'.tr(),
                              message: 'store.cart.delete_item_message'.tr(),
                              onConfirm: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .removeItem(item.id);
                              },
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: item.quantity > 1
                                ? () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(
                                            item.id, item.quantity - 1);
                                  }
                                : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.quantity.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              ref
                                  .read(cartProvider.notifier)
                                  .updateQuantity(item.id, item.quantity + 1);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 20,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final totalAmount = cartAsync.whenOrNull(
          data: (items) => items
              .where((item) => selectedItems.contains(item.id))
              .fold<double>(
                0,
                (sum, item) =>
                    sum +
                    double.parse(item.productVariant.price.toString()) *
                        item.quantity,
              ),
        ) ??
        0.0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Promo code input
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'store.cart.promo.placeholder'.tr(),
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  // TODO: Apply promo code
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'store.cart.promo.apply'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Price breakdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'store.cart.summary.title'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'store.cart.summary.products'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${totalAmount.toStringAsFixed(0)} ₸',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'store.cart.summary.discount'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    '0 ₸',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'store.cart.summary.total'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${totalAmount.toStringAsFixed(0)} ₸',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Continue button
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              label: 'store.cart.summary.continue'.tr(namedArgs: {
                'count': selectedItems.length.toString(),
                'amount': totalAmount.toStringAsFixed(0),
              }),
              isEnabled: selectedItems.isNotEmpty,
              onPressed: () {
                context.push('/checkout');
              },
            ),
          ),
        ],
      ),
    );
  }
}
