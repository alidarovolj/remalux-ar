import 'package:flutter/material.dart';
import 'dart:async';

class AutoSizedImage extends StatefulWidget {
  final String imageUrl;

  const AutoSizedImage({
    super.key,
    required this.imageUrl,
  });

  @override
  State<AutoSizedImage> createState() => _AutoSizedImageState();
}

class _AutoSizedImageState extends State<AutoSizedImage> {
  late final Future<Size> _imageSizeFuture;

  @override
  void initState() {
    super.initState();
    _imageSizeFuture = _getImageSize();
  }

  Future<Size> _getImageSize() async {
    final image = Image.network(widget.imageUrl);
    final completer = Completer<Size>();

    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (info, _) {
          completer.complete(
            Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            ),
          );
        },
      ),
    );

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Size>(
      future: _imageSizeFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final size = snapshot.data!;
        final screenWidth = MediaQuery.of(context).size.width;
        final height = screenWidth * (size.height / size.width);

        return SizedBox(
          width: screenWidth,
          height: height,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.fill,
          ),
        );
      },
    );
  }
}
