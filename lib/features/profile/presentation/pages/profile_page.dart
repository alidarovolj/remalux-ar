import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/theme/colors.dart';
import 'package:remalux_ar/features/auth/domain/models/user.dart';
import 'package:remalux_ar/features/auth/domain/providers/auth_provider.dart';
import 'package:remalux_ar/core/services/storage_service.dart';
import 'package:remalux_ar/features/profile/presentation/widgets/profile_skeleton.dart';
import 'package:remalux_ar/features/profile/presentation/widgets/logout_confirmation_modal.dart';
import 'package:flutter/services.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/features/profile/presentation/widgets/language_selection_modal.dart';
import 'package:easy_localization/easy_localization.dart';

final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  return UserNotifier(ref);
});

class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref ref;

  UserNotifier(this.ref) : super(const AsyncValue.loading()) {
    _initUser();
  }

  Future<void> _initUser() async {
    final token = await StorageService.getToken();
    if (token == null) {
      state = const AsyncValue.data(null);
      return;
    }

    await getCurrentUser();
  }

  Future<void> getCurrentUser() async {
    final token = await StorageService.getToken();
    if (token == null) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final auth = ref.read(authProvider);
      final user = await auth.getCurrentUser();

      if (user != null) {
        state = AsyncValue.data(user);
      } else {
        await StorageService.removeToken();
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    // Keep the current state while refreshing
    final currentUser = state.valueOrNull;
    if (currentUser != null) {
      state = AsyncValue.loading();
    }

    try {
      await getCurrentUser();
    } catch (e) {
      // If refresh fails but we had a user before, restore the previous state
      // instead of showing an error or logging out
      if (currentUser != null) {
        state = AsyncValue.data(currentUser);
      } else {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> logout() async {
    await StorageService.removeToken();
    state = const AsyncValue.data(null);
  }
}

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(userProvider.notifier)
          .refresh()
          .then((_) {})
          .catchError((error) {
        debugPrint('❌ Initial profile refresh failed: $error');
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'profile.title'.tr(),
          showBottomBorder: true,
        ),
        body: userAsync.when(
          data: (user) => user != null
              ? _buildAuthenticatedProfile(context, user)
              : _buildUnauthenticatedProfile(context),
          loading: () => const ProfileSkeleton(),
          error: (error, stack) => _buildErrorState(context, error),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade800,
            ),
            const SizedBox(height: 16),
            Text(
              'profile.error_loading'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(userProvider.notifier).refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
              ),
              child: Text('profile.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticatedProfile(BuildContext context, User user) {
    return ListView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      children: [
        // User Info Section
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: user.imageUrl != null && user.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          user.imageUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),

        // Contact Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // Phone Container
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          'lib/core/assets/icons/profile/smartphone.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                              AppColors.textPrimary, BlendMode.srcIn),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'profile.phone'.tr(),
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.phoneNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Email Container
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          'lib/core/assets/icons/profile/mail.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                              AppColors.textPrimary, BlendMode.srcIn),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'profile.email'.tr(),
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email != null && user.email!.isNotEmpty
                            ? user.email!
                            : 'profile.no_email'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Orders Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/shopping-bag.svg',
                title: 'profile.orders'.tr(),
                onTap: () {
                  context.push('/orders');
                },
              ),

              // Favorites Section
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/heart.svg',
                title: 'profile.favorite_products'.tr(),
                onTap: () {
                  context.push('/favorites');
                },
              ),

              // Colors Section
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/palette.svg',
                title: 'profile.favorite_colors'.tr(),
                onTap: () {
                  context.push('/favorites', extra: {'initialTabIndex': 1});
                },
              ),

              // Reviews Section
              // _buildSettingsItem(
              //   context,
              //   icon: 'lib/core/assets/icons/profile/star.svg',
              //   title: 'Отзывы',
              //   onTap: () {},
              // ),

              const SizedBox(height: 32),

              // Saved Data Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile.saved_data'.tr(),
                      style: GoogleFonts.ysabeau(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: AppColors.borderLightGrey),
                  ],
                ),
              ),

              // Delivery Addresses
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/location.svg',
                title: 'profile.delivery_addresses'.tr(),
                onTap: () {
                  context.push('/addresses');
                },
              ),

              // Recipients
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/person.svg',
                title: 'profile.recipients'.tr(),
                onTap: () {
                  context.push('/recipients');
                },
              ),

              const SizedBox(height: 32),

              // About Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile.about_section'.tr(),
                      style: GoogleFonts.ysabeau(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: AppColors.borderLightGrey),
                  ],
                ),
              ),

              // About Remalux
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/info.svg',
                title: 'profile.about_remalux'.tr(),
                onTap: () {
                  context.push('/about');
                },
              ),

              // Contacts
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/phone.svg',
                title: 'profile.contacts'.tr(),
                onTap: () {
                  context.push('/contacts');
                },
              ),

              // Projects
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/projects.svg',
                title: 'profile.projects'.tr(),
                onTap: () {
                  context.push('/projects');
                },
              ),

              // Become a Partner
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/handshake.svg',
                title: 'partnership.title'.tr(),
                onTap: () {
                  context.push('/partnership');
                },
              ),

              // FAQ
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/question.svg',
                title: 'profile.faq'.tr(),
                onTap: () {
                  context.push('/faq');
                },
              ),

              const SizedBox(height: 32),

              // App Settings Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile.app_settings'.tr(),
                      style: GoogleFonts.ysabeau(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: AppColors.borderLightGrey),
                  ],
                ),
              ),

              // App Language
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/language.svg',
                title: 'profile.app_language'.tr(),
                subtitle: context.locale.languageCode == 'kz'
                    ? 'Қазақша'
                    : context.locale.languageCode == 'ru'
                        ? 'Русский'
                        : 'English',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const LanguageSelectionModal(),
                  );
                },
              ),

              // Logout
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/logout.svg',
                title: 'profile.logout'.tr(),
                titleColor: Colors.red,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const LogoutConfirmationModal(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnauthenticatedProfile(BuildContext context) {
    return ListView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        // Auth Section
        Column(
          children: [
            Text(
              'profile.no_account'.tr(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push('/registration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 52),
              ),
              child: Text(
                'profile.register'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'profile.have_account'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.push('/login');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'profile.login'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),

        // App Settings Section
        Text(
          'profile.app_settings'.tr(),
          style: GoogleFonts.ysabeau(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _buildSettingsItem(
          context,
          icon: 'lib/core/assets/icons/profile/language.svg',
          title: 'profile.app_language'.tr(),
          subtitle: context.locale.languageCode == 'kz'
              ? 'Қазақша'
              : context.locale.languageCode == 'ru'
                  ? 'Русский'
                  : 'English',
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => const LanguageSelectionModal(),
            );
          },
        ),
        const SizedBox(height: 32),

        // About Section
        Text(
          'profile.about_section'.tr(),
          style: GoogleFonts.ysabeau(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _buildSettingsItem(
          context,
          icon: 'lib/core/assets/icons/profile/info.svg',
          title: 'profile.about_remalux'.tr(),
          onTap: () {
            context.push('/about');
          },
        ),
        _buildSettingsItem(
          context,
          icon: 'lib/core/assets/icons/profile/phone.svg',
          title: 'profile.contacts'.tr(),
          onTap: () {
            context.push('/contacts');
          },
        ),
        _buildSettingsItem(
          context,
          icon: 'lib/core/assets/icons/profile/projects.svg',
          title: 'profile.projects'.tr(),
          onTap: () {
            context.push('/projects');
          },
        ),
        _buildSettingsItem(
          context,
          icon: 'lib/core/assets/icons/profile/handshake.svg',
          title: 'partnership.title'.tr(),
          onTap: () {
            context.push('/partnership');
          },
        ),
        _buildSettingsItem(
          context,
          icon: 'lib/core/assets/icons/profile/question.svg',
          title: 'profile.faq'.tr(),
          onTap: () {
            context.push('/faq');
          },
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required String icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SvgPicture.asset(
                    icon,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                        titleColor ?? AppColors.textPrimary, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            color: titleColor ?? AppColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: titleColor ?? AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          height: 1,
          color: AppColors.borderLightGrey,
        ),
      ],
    );
  }
}
