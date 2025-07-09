import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Утилиты для конвертации изображений
class ImageConverter {
  /// Конвертирует [CameraImage] в [img.Image] из пакета image.
  ///
  /// Поддерживает форматы YUV420 и BGRA8888.
  /// Возвращает `null` если формат не поддерживается.
  static img.Image? convertCameraImage(CameraImage image) {
    try {
      switch (image.format.group) {
        case ImageFormatGroup.yuv420:
          return _convertYUV420ToImage(image);
        case ImageFormatGroup.bgra8888:
          return _convertBGRA8888ToImage(image);
        default:
          return null;
      }
    } catch (e) {
      print("Ошибка конвертации изображения: $e");
      return null;
    }
  }

  /// Конвертирует BGRA8888 в [img.Image]
  static img.Image _convertBGRA8888ToImage(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  /// Конвертирует YUV420 в [img.Image]
  static img.Image _convertYUV420ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int? uvPixelStride = image.planes[1].bytesPerPixel;

    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    final convertedImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      final int yRowIndex = y * width;
      for (int x = 0; x < width; x++) {
        final int yIndex = yRowIndex + x;

        // UV-индексы
        final int uvx = (x / 2).floor();
        final int uvy = (y / 2).floor();
        final int uvIndex = uvy * uvRowStride + uvx * (uvPixelStride ?? 1);

        final int yValue = yPlane[yIndex];
        final int uValue = uPlane[uvIndex];
        final int vValue = vPlane[uvIndex];

        // Формулы для конвертации YUV в RGB
        final int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        final int g =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .round()
                .clamp(0, 255);
        final int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        convertedImage.setPixelRgb(x, y, r, g, b);
      }
    }
    return convertedImage;
  }
}
