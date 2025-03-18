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
import 'package:remalux_ar/features/profile/presentation/widgets/profile_menu_item.dart';
import 'package:remalux_ar/features/profile/presentation/widgets/language_selection_modal.dart';
import 'package:easy_localization/easy_localization.dart';

final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  return UserNotifier(ref);
});

class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref ref;

  UserNotifier(this.ref) : super(const AsyncValue.loading()) {
    print('📱 UserNotifier created');
    _initUser();
  }

  Future<void> _initUser() async {
    print('🔑 Checking token...');
    final token = await StorageService.getToken();
    if (token == null) {
      print('❌ No token found');
      state = const AsyncValue.data(null);
      return;
    }
    print('✅ Token found');

    await getCurrentUser();
  }

  Future<void> getCurrentUser() async {
    print('📡 Sending getCurrentUser request...');

    final token = await StorageService.getToken();
    if (token == null) {
      print('❌ No token available for getCurrentUser');
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final auth = ref.read(authProvider);
      final user = await auth.getCurrentUser();

      if (user != null) {
        print('✅ User data received: ${user.name}');
        state = AsyncValue.data(user);
      } else {
        print('❌ No user data received');
        await StorageService.removeToken();
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      print('❌ getCurrentUser failed: $e');
      await StorageService.removeToken();
      state = const AsyncValue.data(null);
    }
  }

  Future<void> refresh() async {
    print('🔄 Starting profile refresh...');

    final token = await StorageService.getToken();
    if (token == null) {
      print('❌ No token for refresh');
      state = const AsyncValue.data(null);
      return;
    }
    print('🔑 Token found for refresh');

    state = const AsyncValue.loading();
    await getCurrentUser();
  }

  Future<void> logout() async {
    print('👋 Logging out...');
    await StorageService.removeToken();
    state = const AsyncValue.data(null);
    print('✅ Logout completed');
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
    print('📱 ProfilePage initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).refresh().then((_) {
        print('✅ Initial profile refresh completed');
      }).catchError((error) {
        print('❌ Initial profile refresh failed: $error');
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
    print('🎨 ProfilePage building with state: ${userAsync.toString()}');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(
          title: 'Профиль',
          showBottomBorder: true,
        ),
        body: userAsync.when(
          data: (user) => user != null
              ? _buildAuthenticatedProfile(context, user)
              : _buildUnauthenticatedProfile(context),
          loading: () => const ProfileSkeleton(),
          error: (_, __) => _buildUnauthenticatedProfile(context),
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
                child: Center(
                  child: Text(
                    user.name[0].toUpperCase(),
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
                    const SizedBox(height: 4),
                    Text(
                      'Редактировать профиль',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Телефон',
                        style: TextStyle(
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Почта',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? 'Не указано',
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
                title: 'Заказы',
                onTap: () {
                  context.push('/orders');
                },
              ),

              // Favorites Section
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/heart.svg',
                title: 'Избранные товары',
                onTap: () {
                  context.push('/favorites');
                },
              ),

              // Colors Section
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/palette.svg',
                title: 'Избранные цвета',
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
                      'Сохраненные данные',
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
                title: 'Адреса доставок',
                onTap: () {
                  context.push('/addresses');
                },
              ),

              // Recipients
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/person.svg',
                title: 'Получатели',
                onTap: () {
                  context.push('/recipients');
                },
              ),

              // Menu Items
              // const SizedBox(height: 16),
              // ProfileMenuItem(
              //   icon: Icons.location_on_outlined,
              //   title: 'Адреса доставок',
              //   onTap: () => context.push('/addresses'),
              // ),
              // ProfileMenuItem(
              //   icon: Icons.business_outlined,
              //   title: 'Наши филиалы',
              //   onTap: () => context.push('/contacts'),
              // ),

              const SizedBox(height: 32),

              // About Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'О нас',
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
                title: 'О Remalux',
                onTap: () {},
              ),

              // Contacts
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/phone.svg',
                title: 'Контакты',
                onTap: () {
                  context.push('/contacts');
                },
              ),

              // Projects
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/projects.svg',
                title: 'Проекты',
                onTap: () {
                  context.push('/projects');
                },
              ),

              // Become a Partner
              // _buildSettingsItem(
              //   context,
              //   icon: 'lib/core/assets/icons/profile/handshake.svg',
              //   title: 'Стать партнером',
              //   onTap: () {},
              // ),

              // FAQ
              _buildSettingsItem(
                context,
                icon: 'lib/core/assets/icons/profile/question.svg',
                title: 'Часто задаваемые вопросы',
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
                      'Настройки приложения',
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
                title: 'Язык приложения',
                subtitle: context.locale.languageCode == 'kk'
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
                title: 'Выйти из профиля',
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
            const Text(
              'Еще нет аккаунта?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement registration
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text(
                'Зарегистрироваться',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Уже есть аккаунт?',
                  style: TextStyle(
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
                  child: const Text(
                    'Войти',
                    style: TextStyle(
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
          'Настройки приложения',
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
          title: 'Язык приложения',
          subtitle: context.locale.languageCode == 'kk'
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
          'О нас',
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
          title: 'О Remalux',
          onTap: () {
            // TODO: Navigate to About page
          },
        ),
        _buildSettingsItem(
          context,
          icon: 'lib/core/assets/icons/profile/phone.svg',
          title: 'Контакты',
          onTap: () {
            context.push('/contacts');
          },
        ),
        _buildSettingsItem(
          context,
          icon: 'lib/core/assets/icons/profile/projects.svg',
          title: 'Проекты',
          onTap: () {
            context.push('/projects');
          },
        ),
        // _buildSettingsItem(
        //   context,
        //   icon: 'lib/core/assets/icons/profile/handshake.svg',
        //   title: 'Стать партнером',
        //   onTap: () {
        //     // TODO: Navigate to Partnership page
        //   },
        // ),
        _buildSettingsItem(
          context,
          icon: 'lib/core/assets/icons/profile/question.svg',
          title: 'Часто задаваемые вопросы',
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
                  SvgPicture.asset(icon, width: 24, height: 24),
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
