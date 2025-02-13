import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/widgets/section_widget.dart';
import 'package:remalux_ar/features/home/presentation/providers/news_provider.dart';
import 'package:remalux_ar/features/home/presentation/widgets/news_item.dart';
import 'package:shimmer/shimmer.dart';

class NewsGrid extends ConsumerWidget {
  const NewsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    return SectionWidget(
      title: 'Новости',
      buttonTitle: 'Все новости',
      onButtonPressed: () {
        context.push('/news');
      },
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: news.length,
              itemBuilder: (context, index) {
                final newsItem = news[index];
                return SizedBox(
                  width: 300,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: NewsItem(news: newsItem),
                  ),
                );
              },
            );
          },
          loading: () => ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) => const SizedBox(
              width: 300,
              child: Padding(
                padding: EdgeInsets.only(right: 8),
                child: _NewsItemSkeleton(),
              ),
            ),
          ),
          error: (error, stackTrace) => Center(
            child: Text('Ошибка: $error'),
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
