import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:remalux_ar/features/projects/presentation/providers/projects_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class ProjectsPage extends ConsumerStatefulWidget {
  const ProjectsPage({super.key});

  @override
  ConsumerState<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends ConsumerState<ProjectsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(projectsProvider.notifier).fetchProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: '',
        showLogo: true,
        showBottomBorder: true,
      ),
      body: projects.when(
        data: (projectsList) {
          if (projectsList.isEmpty) {
            return Center(
              child: Text('projects.no_projects'.tr()),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            itemCount: projectsList.length + 2, // +1 for header, +1 for footer
            itemBuilder: (context, index) {
              // Header
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Text(
                    'projects.title'.tr(),
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }

              // Footer with button
              if (index == projectsList.length + 1) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: CustomButton(
                    label: 'projects.to_products'.tr(),
                    onPressed: () => context.go('/store'),
                    type: ButtonType.normal,
                    backgroundColor: AppColors.primary,
                    textColor: Colors.white,
                  ),
                );
              }

              final project = projectsList[index - 1];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project title
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      context.locale.languageCode == 'ru'
                          ? project.title.ru
                          : context.locale.languageCode == 'kz'
                              ? project.title.kz
                              : project.title.en,
                      style: GoogleFonts.ysabeau(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  // Project images grid
                  if (project.images.isNotEmpty)
                    Column(
                      children: [
                        // First image - full width
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: double.infinity,
                            height: 186,
                            child: Image.network(
                              project.images[0],
                              width: double.infinity,
                              height: 186,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(color: Colors.white),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                        ),

                        // Second row - two images if available
                        if (project.images.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                // Left image
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      height: 186,
                                      child: Image.network(
                                        project.images[1],
                                        width: double.infinity,
                                        height: 186,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor: Colors.grey[100]!,
                                            child:
                                                Container(color: Colors.white),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Right image if available
                                if (project.images.length > 2)
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        height: 186,
                                        child: Image.network(
                                          project.images[2],
                                          width: double.infinity,
                                          height: 186,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Shimmer.fromColors(
                                              baseColor: Colors.grey[300]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: Container(
                                                  color: Colors.white),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.error),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),

                  // Project info with top margin
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description
                        Text(
                          context.locale.languageCode == 'ru'
                              ? project.description.ru
                              : context.locale.languageCode == 'kz'
                                  ? project.description.kz
                                  : project.description.en,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Project details
                        if (project.floors != null ||
                            project.area != null ||
                            project.year != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                if (project.floors != null)
                                  _buildDetailRow(
                                    'projects.details.floors'
                                        .tr(args: [project.floors.toString()]),
                                  ),
                                if (project.area != null)
                                  _buildDetailRow(
                                    'projects.details.area'
                                        .tr(args: [project.area!]),
                                  ),
                                if (project.year != null)
                                  _buildDetailRow(
                                    'projects.details.year'
                                        .tr(args: [project.year.toString()]),
                                  ),
                              ],
                            ),
                          ),

                        // Features list
                        if (project.features != null &&
                            project.features!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: project.features!.map((feature) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '•',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          feature,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => _buildSkeleton(),
        error: (error, stackTrace) => Center(
          child: Text('projects.error'.tr(args: [error.toString()])),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        // Image grid skeleton
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            childAspectRatio: 1.5,
            children: List.generate(
                4,
                (index) => Container(
                      color: Colors.white,
                    )),
          ),
        ),

        // Content skeleton
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description skeleton
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  children: List.generate(3, (index) {
                    return Container(
                      width: double.infinity,
                      height: 16,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // Details skeleton
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
