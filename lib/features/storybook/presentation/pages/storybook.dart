import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storybook_flutter/storybook_flutter.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';

class StorybookScreen extends StatelessWidget {
  const StorybookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storybook'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Storybook(
        stories: [
          Story(
            name: 'Custom Button',
            description: 'A simple customizable button.',
            builder: (context) {
              final label =
                  context.knobs.text(label: 'Label', initial: 'Click Me');
              final enabled =
                  context.knobs.boolean(label: 'Enabled', initial: true);

              return Center(
                child: CustomButton(
                  label: label,
                  onPressed:
                      enabled ? () => debugPrint('Button pressed') : () {},
                  type: ButtonType.normal,
                  isFullWidth: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
