import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show rootBundle;

class FileService {
  static Future<void> openPdfAsset(String assetPath) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/temp.pdf');

      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );

      final url = Uri.file(file.path);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<String> downloadPdfAsset(
      String assetPath, String fileName) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');

      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );

      return file.path;
    } catch (e) {
      rethrow;
    }
  }
}
