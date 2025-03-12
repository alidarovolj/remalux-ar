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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
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
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
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
                          idea.title['ru'] ?? '',
                          style: GoogleFonts.ysabeau(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          idea.shortDescription['ru'] ?? '',
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
                          const Text(
                            'Использованные цвета',
                            style: TextStyle(
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
                                final color = idea.colors![index];
                                return _ColorCard(color: color);
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
          child: Text('Ошибка: $error'),
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
                    text['heading']['ru'] ?? '',
                    style: GoogleFonts.ysabeau(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  text['text']['ru'] ?? '',
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
          if (content['title'] != null && content['title']['ru'] != null) ...[
            Text(
              content['title']['ru'],
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
                              color['title']['ru'] ?? '',
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
                      const SnackBar(
                        content: Text(
                            'Визуализация будет доступна в ближайшее время'),
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
                        const Text(
                          'Визуализировать',
                          style: TextStyle(
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
                    // TODO: Implement visualization
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Визуализация будет доступна в ближайшее время'),
                      ),
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Выбрать краску',
                          style: TextStyle(
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

    // Используем цвет из color_title.hex с прозрачностью 60%
    final backgroundColor =
        idea?.colorTitle != null && idea!.colorTitle!['hex'] != null
            ? _parseHexColor(idea.colorTitle!['hex']).withOpacity(0.4)
            : (colorsToShow.isNotEmpty
                ? _parseHexColor(colorsToShow[0]['hex']).withOpacity(0.4)
                : const Color(0xFFF5B199).withOpacity(0.4));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Блок с градиентом и блюром
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Text(
                      'Цветовая схема:',
                      style: GoogleFonts.ysabeau(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Название цвета (title)
                    if (content['title'] != null &&
                        content['title']['ru'] != null)
                      Text(
                        '(${content['title']['ru']})',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Цветовые круги
                    Row(
                      children: [
                        for (final color in colorsToShow)
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _parseHexColor(color['hex']),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
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

        // Тексты после блока
        if (texts != null && texts.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final textItem in texts)
                if (textItem['ru'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      textItem['ru'],
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

class _ColorCard extends StatelessWidget {
  final Map<String, dynamic> color;

  const _ColorCard({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(59, 77, 139, 0.1),
            blurRadius: 5,
            offset: Offset(0, 1),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _parseHexColor(color['hex']),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  color['title']['ru'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'NOVA 2024 ${color['ral']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
