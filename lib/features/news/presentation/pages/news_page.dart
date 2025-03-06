import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/features/home/presentation/providers/news_provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';

class NewsPage extends ConsumerWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Новости',
      ),
      body: newsAsync.when(
        data: (news) {
          if (news.isEmpty) {
            return const Center(
              child: Text('Нет новостей'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: news.length,
            itemBuilder: (context, index) {
              final newsItem = news[index];

              if (index == 0) {
                // Первая новость - крупный формат
                return Container(
                  padding: const EdgeInsets.all(0),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: GestureDetector(
                    onTap: () => context.push('/news/${newsItem.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            newsItem.imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                newsItem.title['ru'] ?? '',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Html(
                                data: newsItem.description['ru'] ?? '',
                                style: {
                                  "body": Style(
                                    fontSize: FontSize(15),
                                    lineHeight: const LineHeight(1.4),
                                    color:
                                        AppColors.textPrimary.withOpacity(0.6),
                                    margin: Margins.zero,
                                    padding: HtmlPaddings.zero,
                                    maxLines: 3,
                                    textOverflow: TextOverflow.ellipsis,
                                  ),
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Остальные новости - компактный формат в карточках
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => context.push('/news/${newsItem.id}'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12),
                          ),
                          child: Image.network(
                            newsItem.imageUrl,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  newsItem.title['ru'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Html(
                                  data: newsItem.description['ru'] ?? '',
                                  style: {
                                    "body": Style(
                                      fontSize: FontSize(13),
                                      color: AppColors.textPrimary
                                          .withOpacity(0.6),
                                      margin: Margins.zero,
                                      padding: HtmlPaddings.zero,
                                      maxLines: 2,
                                      textOverflow: TextOverflow.ellipsis,
                                    ),
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('Ошибка: $error'),
        ),
      ),
    );
  }
}
