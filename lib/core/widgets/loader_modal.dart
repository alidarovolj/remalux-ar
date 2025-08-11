import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:remalux_ar/core/styles/constants.dart';

class LoaderModal extends StatefulWidget {
  final String title;
  final String imagePath;

  const LoaderModal({
    super.key,
    required this.title,
    required this.imagePath,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String imagePath,
  }) async {
    if (!context.mounted) return;

    // Show the modal and get the BuildContext from the modal
    BuildContext? modalContext;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (BuildContext context) {
        modalContext = context;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 1.0,
          minChildSize: 1.0,
          maxChildSize: 1.0,
          builder: (BuildContext context, ScrollController scrollController) {
            return LoaderModal(
              title: title,
              imagePath: imagePath,
            );
          },
        );
      },
    );

    // Wait for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    // Close the modal using the modal's context
    if (modalContext != null &&
        context.mounted &&
        Navigator.canPop(modalContext!)) {
      Navigator.pop(modalContext!);
    }
  }

  @override
  State<LoaderModal> createState() => _LoaderModalState();
}

class _LoaderModalState extends State<LoaderModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppLength.body),
          topRight: Radius.circular(AppLength.body),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppLength.body),
              child: SvgPicture.asset(
                'lib/core/assets/icons/logo.svg',
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppLength.xl),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: AppLength.lg,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppLength.xl),
            const CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
