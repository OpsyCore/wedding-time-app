import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// اشتراک‌گذاری فایل CSV (اکسل) روی موبایل/دسکتاپ
Future<void> shareCsvFile(String filename, String csvContent) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  // BOM برای نمایش درست فارسی در اکسل
  await file.writeAsString('\uFEFF$csvContent', flush: true);
  await Share.shareXFiles(
    [XFile(file.path)],
    subject: filename,
  );
}
