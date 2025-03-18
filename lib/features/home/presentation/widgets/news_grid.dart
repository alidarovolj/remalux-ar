import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/widgets/section_widget.dart';
import 'package:remalux_ar/features/home/presentation/providers/news_provider.dart';
import 'package:remalux_ar/features/home/presentation/widgets/news_item.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';

class NewsGrid extends ConsumerWidget {
  const NewsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    return SectionWidget(
      title: 'home.news.title'.tr(),
      buttonTitle: 'home.news.view_all'.tr(),
      onButtonPressed: () => context.push('/news'),
      child: SizedBox(
        height: 270,
        child: newsAsync.when(
          data: (news) {
            if (news.isEmpty) {
              return const Center(
                child: Text('Нет новостей'),
              );
            }

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: news.length,
              itemBuilder: (context, index) {
                final newsItem = news[index];
                return SizedBox(
                  width: 300,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                    ),
                    child: GestureDetector(
                      onTap: () => context.push('/news/${newsItem.id}'),
                      child: NewsItem(news: newsItem),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: 3,
            itemBuilder: (context, index) => const SizedBox(
              width: 300,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: _NewsItemSkeleton(),
              ),
            ),
          ),
          error: (error, stackTrace) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }
}

class _NewsItemSkeleton extends StatelessWidget {
  const _NewsItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
