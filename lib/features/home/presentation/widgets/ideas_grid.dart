import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/widgets/section_widget.dart';
import 'package:remalux_ar/features/home/presentation/providers/ideas_provider.dart';
import 'package:remalux_ar/features/home/presentation/widgets/idea_item.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';

class IdeasGrid extends ConsumerWidget {
  const IdeasGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideasAsync = ref.watch(ideasProvider);

    return SectionWidget(
      title: 'Идеи для дома',
      buttonTitle: 'Все идеи',
      onButtonPressed: () => context.push('/ideas'),
      child: SizedBox(
        height: 270,
        child: ideasAsync.when(
          data: (ideas) {
            if (ideas.isEmpty) {
              return const Center(
                child: Text('Нет идей'),
              );
            }

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: ideas.length,
              itemBuilder: (context, index) {
                final idea = ideas[index];
                return SizedBox(
                  width: 300,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IdeaItem(idea: idea),
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
                child: _IdeaItemSkeleton(),
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
