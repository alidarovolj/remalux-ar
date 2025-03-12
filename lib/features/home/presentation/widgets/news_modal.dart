import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/home/presentation/providers/news_provider.dart';
import 'package:remalux_ar/features/home/presentation/widgets/news_skeleton.dart';

class NewsModal extends ConsumerWidget {
  final int newsId;

  const NewsModal({
    super.key,
    required this.newsId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(preloadedNewsProvider(newsId));

    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Новость'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: newsAsync.when(
                  data: (news) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          news.imageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        news.title['ru'] ?? '',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(news.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Text(news.content?['ru'] ?? news.description['ru'] ?? ''),
                    ],
                  ),
                  loading: () => const NewsModalSkeleton(),
                  error: (error, stackTrace) => Center(
                    child: Text('Ошибка: $error'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
