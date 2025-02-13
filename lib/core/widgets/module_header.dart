import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'package:remalux_ar/core/widgets/location_bottom_sheet.dart';

class ModuleHeader extends StatefulWidget implements PreferredSizeWidget {
  final String type;

  const ModuleHeader({
    super.key,
    required this.type,
  });

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  _ModuleHeaderState createState() => _ModuleHeaderState();
}

class _ModuleHeaderState extends State<ModuleHeader> {
  late Timer _timer;
  final List<String> _searchHints = ["специализации", "имени", "клинике"];
  String _displayedHint = "Поиск по ";
  int _currentHintIndex = 0;
  int _currentCharIndex = 0;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        if (_isDeleting) {
          if (_currentCharIndex > 0) {
            _currentCharIndex--;
            _displayedHint =
                "Поиск по ${_searchHints[_currentHintIndex].substring(0, _currentCharIndex)}";
          } else {
            _isDeleting = false;
            _currentHintIndex = (_currentHintIndex + 1) % _searchHints.length;
          }
        } else {
          if (_currentCharIndex < _searchHints[_currentHintIndex].length) {
            _currentCharIndex++;
            _displayedHint =
                "Поиск по ${_searchHints[_currentHintIndex].substring(0, _currentCharIndex)}";
          } else {
            _isDeleting = true;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppLength.sm,
        right: AppLength.sm,
        bottom: AppLength.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LocationBottomSheet(),
            ],
          ),
          const SizedBox(height: AppLength.sm),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(AppLength.sm),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: _displayedHint,
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppLength.body,
                        vertical: AppLength.sm,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    onTap: () => context.push('/search-module'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(AppLength.xs),
                ),
                child: IconButton(
                  icon: SvgPicture.asset(
                    'lib/core/assets/icons/filters.svg',
                    width: 15,
                    height: 15,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
