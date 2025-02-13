import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/providers/requests/story_provider.dart';

class StoryList extends ConsumerStatefulWidget {
  final String? module;

  const StoryList({
    super.key,
    this.module,
  });

  @override
  ConsumerState<StoryList> createState() => _StoryListState();
}

class _StoryListState extends ConsumerState<StoryList> {
  void markStoryAsRead(List<Story> stories, int index) {
    setState(() {
      stories[index].read = true;
      debugPrint("Story ${index + 1} marked as read");
    });
  }

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(storiesProvider(widget.module));

    return SizedBox(
      height: 102,
      child: storiesAsync.when(
        data: (stories) {
          if (stories.isEmpty) {
            return const Center(
              child: Text(
                'Нет доступных историй',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return GestureDetector(
                onTap: () {
                  markStoryAsRead(stories, index);
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: MaterialLocalizations.of(context)
                        .modalBarrierDismissLabel,
                    barrierColor: Colors.black.withOpacity(0.5),
                    transitionDuration: const Duration(milliseconds: 300),
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return StoryDetailsPage(
                        stories: stories,
                        initialIndex: index,
                        onStoryRead: (readIndex) {
                          markStoryAsRead(stories, readIndex);
                        },
                      );
                    },
                  );
                },
                child: Container(
                  width: 88,
                  margin: const EdgeInsets.only(right: AppLength.tiny),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppLength.body),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Container(
                      decoration: story.read
                          ? BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppLength.body),
                              border: Border.all(
                                color: Colors.grey,
                                width: 2,
                              ),
                            )
                          : BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppLength.body),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppLength.xs),
                          child: Stack(
                            children: [
                              Image.network(
                                story.image,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.broken_image, size: 40),
                                  );
                                },
                              ),
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF0B0B0E).withOpacity(0.7),
                                      const Color(0xFF0B0B0E).withOpacity(0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    story.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: AppLength.xxs,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 6.0, bottom: 2.0),
                                child: Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Container(
                                      width: 44,
                                      height: 16,
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(200),
                                      ),
                                      child: Image.network(
                                        story.partner.imageUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(Icons.error,
                                              size: AppLength.xs);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Ошибка загрузки историй: $error'),
        ),
      ),
    );
  }
}

class StoryDetailsPage extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final Function(int) onStoryRead;

  const StoryDetailsPage({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.onStoryRead,
  });

  @override
  _StoryDetailsPageState createState() => _StoryDetailsPageState();
}

class _StoryDetailsPageState extends State<StoryDetailsPage>
    with SingleTickerProviderStateMixin {
  late int currentStoryIndex;
  late PageController _pageController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    currentStoryIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressController.addListener(() {
      setState(() {});
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        handleNextStory();
      }
    });

    _markCurrentStoryAsRead();
    _progressController.forward();
  }

  void _markCurrentStoryAsRead() {
    if (!widget.stories[currentStoryIndex].read) {
      debugPrint("Story ${currentStoryIndex + 1} marked as read");
      widget.onStoryRead(currentStoryIndex);
    }
  }

  void handleNextStory() {
    if (currentStoryIndex < widget.stories.length - 1) {
      setState(() {
        currentStoryIndex++;
      });
      _markCurrentStoryAsRead();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _progressController.reset();
      _progressController.forward();
    } else {
      Navigator.of(context).pop();
    }
  }

  void handleStoryChange(int newIndex) {
    setState(() {
      currentStoryIndex = newIndex;
    });
    _markCurrentStoryAsRead();
    _progressController.reset();
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paddingTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: handleStoryChange,
            itemCount: widget.stories.length,
            itemBuilder: (context, index) {
              final story = widget.stories[index];
              return GestureDetector(
                onTap: handleNextStory,
                child: Image.network(
                  story.screen,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, size: 40),
                    );
                  },
                ),
              );
            },
          ),
          Positioned(
            top: paddingTop + AppLength.xxs,
            left: AppLength.body,
            right: AppLength.body,
            child: Row(
              children: List.generate(widget.stories.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: LinearProgressIndicator(
                      value: index < currentStoryIndex
                          ? 1.0
                          : (index == currentStoryIndex
                              ? _progressController.value
                              : 0.0),
                      backgroundColor: AppColors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Positioned(
            top: paddingTop + AppLength.xxxl,
            right: AppLength.body,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.buttonClose,
                  borderRadius: BorderRadius.circular(AppLength.xs),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(AppLength.tiny),
                  child: Icon(
                    Icons.close,
                    color: AppColors.textPrimary,
                    size: AppLength.xl,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
