import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/home/presentation/providers/ideas_provider.dart';
import 'package:remalux_ar/features/home/domain/models/idea.dart';
import 'package:remalux_ar/features/ideas/presentation/widgets/idea_detail_skeleton.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:remalux_ar/core/widgets/detailed_color_card.dart';
import 'package:remalux_ar/features/home/presentation/widgets/color_detail_modal.dart';
import 'package:remalux_ar/features/home/data/models/detailed_color_model.dart';

class IdeaDetailPage extends ConsumerStatefulWidget {
  final int ideaId;

  const IdeaDetailPage({
    super.key,
    required this.ideaId,
  });

  @override
  ConsumerState<IdeaDetailPage> createState() => _IdeaDetailPageState();
}

class _IdeaDetailPageState extends ConsumerState<IdeaDetailPage> {
  late ScrollController _scrollController;
  bool _showSafeArea = false;
  String currentLocale = 'ru';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        currentLocale = context.locale.languageCode;
      });
    });
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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showSafeArea = _scrollController.offset > 100;
    if (showSafeArea != _showSafeArea) {
      setState(() {
        _showSafeArea = showSafeArea;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ideaAsync = ref.watch(ideaDetailProvider(widget.ideaId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: ideaAsync.when(
        data: (idea) {
          return Stack(
            children: [
              ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  Image.network(
                    idea.imageUrl,
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.4,
                    fit: BoxFit.cover,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          idea.title[currentLocale] ?? '',
                          style: GoogleFonts.ysabeau(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          idea.shortDescription[currentLocale] ?? '',
                          style: const TextStyle(
                              fontSize: 15, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 24),

                        // Values section
                        if (idea.values != null) ...[
                          for (final section in idea.values!)
                            _buildValueSection(section),
                        ],

                        // Colors section
                        if (idea.colors != null && idea.colors!.isNotEmpty) ...[
                          Text(
                            'ideas.used_colors'.tr(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: idea.colors!.length,
                              itemBuilder: (context, index) {
                                final colorMap = idea.colors![index];
                                final color = DetailedColorModel(
                                  id: colorMap['id'] as int,
                                  hex: colorMap['hex'] as String,
                                  title: Map<String, String>.from(
                                      colorMap['title'] as Map),
                                  ral: colorMap['ral'] as String,
                                  catalog: Catalog(
                                    id: 1, // НОВА 2024
                                    title: 'NOVA 2024',
                                    code: 'NOVA_2024',
                                  ),
                                  isFavourite:
                                      colorMap['is_favourite'] as bool? ??
                                          false,
                                );
                                return Container(
                                  width: 180,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: DetailedColorCard(
                                    color: color,
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) =>
                                            ColorDetailModal(color: color),
                                      );
                                    },
                                    onFavoritePressed: () {
                                      // TODO: Implement favorite functionality
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // SafeArea overlay
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showSafeArea ? MediaQuery.of(context).padding.top : 0,
                color: Colors.white.withOpacity(_showSafeArea ? 1.0 : 0.0),
                width: double.infinity,
              ),
              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const IdeaDetailSkeleton(),
        error: (error, stackTrace) => Center(
          child: Text(
            'ideas.error'.tr(args: [error.toString()]),
          ),
        ),
      ),
    );
  }

  Widget _buildValueSection(List<Map<String, dynamic>> section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final value in section) _buildValueContent(value),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildValueContent(Map<String, dynamic> value) {
    switch (value['type']) {
      case 'text':
        return _buildTextContent(value['content']);
      case 'photos':
        return _buildPhotosContent(value['content']);
      case 'colors_ral':
        return _buildColorsRalContent(value['content']);
      case 'color_combinations':
        final ideaAsync = ref.watch(ideaDetailProvider(widget.ideaId));
        final idea = ideaAsync.value;
        return _buildColorCombinationsContent(value['content'], idea);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextContent(Map<String, dynamic> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final text in content['texts'])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (text['heading'] != null)
                  Text(
                    text['heading'][currentLocale] ?? '',
                    style: GoogleFonts.ysabeau(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  text['text'][currentLocale] ?? '',
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPhotosContent(Map<String, dynamic> content) {
    final photos = List<String>.from(content['photos']);
    if (photos.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content['title'] != null &&
              content['title'][currentLocale] != null) ...[
            Text(
              content['title'][currentLocale],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Фотографии в сетке
          photos.length == 1
              ? _buildSinglePhoto(photos[0])
              : _buildPhotoGrid(photos),
        ],
      ),
    );
  }

  Widget _buildSinglePhoto(String photoUrl) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(List<String> photos) {
    return Column(
      children: [
        // Верхняя большая фотография
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              photos[0],
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Нижние две фотографии
        if (photos.length > 1)
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      photos.length > 1 ? photos[1] : photos[0],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          photos.length > 2
                              ? photos[2]
                              : (photos.length > 1 ? photos[1] : photos[0]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (photos.length > 3)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Center(
                              child: Text(
                                '+${photos.length - 3}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildColorsRalContent(Map<String, dynamic> content) {
    final colors = List<Map<String, dynamic>>.from(content['colors_ral']);
    return Column(
      children: [
        for (final color in colors)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFEEEEEE),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Color info section
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Color square
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: _parseHexColor(color['hex']),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Color name and code
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              color['title'][currentLocale] ?? '',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'NOVA 2024 ${color['ral']}',
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Favorite icon
                      IconButton(
                        icon: const Icon(
                          Icons.favorite_border,
                          color: Color(0xFF666666),
                        ),
                        onPressed: () {
                          // TODO: Implement favorite functionality
                        },
                      ),
                    ],
                  ),
                ),
                // Visualization button
                GestureDetector(
                  onTap: () {
                    // TODO: Implement visualization
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ideas.visualization_coming_soon'.tr()),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.buttonSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('lib/core/assets/images/cube.svg',
                            width: 40, height: 40),
                        const SizedBox(width: 8),
                        Text(
                          'ideas.visualize'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                GestureDetector(
                  onTap: () {
                    final detailedColor = DetailedColorModel(
                      id: color['id'] as int,
                      hex: color['hex'] as String,
                      title: Map<String, String>.from(color['title'] as Map),
                      ral: color['ral'] as String,
                      catalog: Catalog(
                        id: 1,
                        title: 'NOVA 2024',
                        code: 'NOVA_2024',
                      ),
                      isFavourite: color['is_favourite'] as bool? ?? false,
                    );

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          ColorDetailModal(color: detailedColor),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    margin:
                        const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.buttonSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ideas.select_paint'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildColorCombinationsContent(
      Map<String, dynamic> content, Idea? idea) {
    final colors = content['colors'] as List<dynamic>?;
    final texts = content['texts'] as List<dynamic>?;

    // Если цвета не указаны в content, используем эти два цвета по умолчанию
    final List<Map<String, String>> defaultColors = [
      {'hex': '#A9B178'}, // Зеленый
      {'hex': '#F5B199'}, // Персиковый
    ];

    final colorsToShow =
        colors != null && colors.isNotEmpty ? colors : defaultColors;

    String _getImageNameFromTitle(Map<String, dynamic>? colorTitle) {
      if (colorTitle == null) {
        print('DEBUG: colorTitle is null, using default grey.png');
        return 'grey.png';
      }

      final ruTitle = colorTitle['ru']?.toLowerCase() ?? '';
      print('DEBUG: colorTitle ru value: "$ruTitle"');

      String imageName;
      switch (ruTitle) {
        case 'серый':
          imageName = 'grey.png';
          break;
        case 'синий':
          imageName = 'Blue.png';
          break;
        case 'розовый':
          imageName = 'Pink.png';
          break;
        case 'оранжевый':
          imageName = 'Yellow.png';
          break;
        case 'фиолетовый':
          imageName = 'Purple.png';
          break;
        case 'коричневый':
          imageName = 'Brown.png';
          break;
        case 'белый':
          imageName = 'aqua.png';
          break;
        case 'зеленый':
          imageName = 'Green.png';
          break;
        case 'желтый':
          imageName = 'Yellow.png';
          break;
        default:
          imageName = 'grey.png';
          break;
      }

      print('DEBUG: Selected image: $imageName for color: $ruTitle');
      return imageName;
    }

    // Давайте также проверим сам объект idea и его colorTitle
    print('DEBUG: Full idea.colorTitle: ${idea?.colorTitle}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 80),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background color palettes
              Positioned(
                left: -50,
                top: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  color: Colors.white,
                  child: Image.asset(
                    'lib/core/assets/images/colors/${_getImageNameFromTitle(idea?.colorTitle)}',
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(1.0),
                  ),
                ),
              ),
              // Right center palette
              Positioned(
                right: -50,
                top: 0,
                child: Container(
                  width: 125,
                  height: 125,
                  color: Colors.white,
                  child: Image.asset(
                    'lib/core/assets/images/colors/${_getImageNameFromTitle(idea?.colorTitle)}',
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(1.0),
                  ),
                ),
              ),
              // Bottom right palette
              Positioned(
                right: -50,
                bottom: 0,
                child: Container(
                  width: 150,
                  height: 150,
                  color: Colors.white,
                  child: Image.asset(
                    'lib/core/assets/images/colors/${_getImageNameFromTitle(idea?.colorTitle)}',
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(1.0),
                  ),
                ),
              ),
              // Main content container with gradient and blur
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment(-0.87, -0.5),
                    end: Alignment(0.87, 0.5),
                    colors: [
                      Color.fromRGBO(255, 255, 255, 0.75),
                      Color.fromRGBO(255, 255, 255, 0.5),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Цветовая схема:',
                            style: GoogleFonts.ysabeau(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Описание цвета
                          if (texts != null && texts.isNotEmpty)
                            Text(
                              texts[0][currentLocale] ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color.fromRGBO(38, 53, 79, 1),
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Цветовые круги
                          Row(
                            children: [
                              for (final color in colorsToShow)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _parseHexColor(color['hex']),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Дополнительные тексты после блока
        if (texts != null && texts.length > 1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final textItem in texts.skip(1))
                if (textItem[currentLocale] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      textItem[currentLocale],
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
            ],
          ),
      ],
    );
  }

  Color _parseHexColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
