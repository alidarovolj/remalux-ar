import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/home/presentation/providers/ideas_provider.dart';
import 'package:remalux_ar/features/home/presentation/widgets/idea_item.dart';
import 'package:shimmer/shimmer.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/core/widgets/page_banner.dart';

class IdeasPage extends ConsumerWidget {
  const IdeasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideasAsync = ref.watch(ideasProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Идеи',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Баннер страницы
            const PageBanner(bannerType: BannerType.ideas),

            // Контент с идеями
            ideasAsync.when(
              data: (ideas) {
                if (ideas.isEmpty) {
                  return const Center(
                    child: Text('Нет идей'),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    itemCount: ideas.length,
                    itemBuilder: (context, index) {
                      final idea = ideas[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IdeaItem(idea: idea),
                      );
                    },
                  ),
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 12, bottom: 24),
                  itemCount: 6,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _IdeaItemSkeleton(),
                  ),
                ),
              ),
              error: (error, stackTrace) => Center(
                child: Text('Ошибка: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdeaItemSkeleton extends StatelessWidget {
  const _IdeaItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 200,
                      height: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 12,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
