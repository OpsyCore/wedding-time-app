import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import '../core/app_lang.dart';

class MediaUploadResult {
  const MediaUploadResult({
    required this.url,
    required this.deleteUrl,
    required this.providerId,
  });

  final String url;
  final String deleteUrl;
  final String providerId;
}

/// آپلود رایگان تصویر — بدون Firebase Storage
class MediaUploadService {
  static final _uri = Uri.parse('https://api.imgbb.com/1/upload');

  /// type: photo | video
  /// ویدیو در ImgBB پشتیبانی نمی‌شود → برای video خطا می‌دهد
  static Future<MediaUploadResult> uploadImageBytes({
    required List<int> bytes,
    String fileName = 'wedding.jpg',
  }) async {
    if (!AppConfig.hasImgbbKey) {
      throw Exception(AppLang.tr('err_imgbb_key_missing'));
    }

    if (bytes.isEmpty) {
      throw Exception(AppLang.tr('empty_file'));
    }
    // سقف تقریبی رایگان ImgBB ~32MB
    if (bytes.length > 32 * 1024 * 1024) {
      throw Exception(AppLang.tr('err_image_too_large'));
    }

    final b64 = base64Encode(bytes);

    final res = await http.post(
      _uri,
      body: {
        'key': AppConfig.imgbbApiKey,
        'image': b64,
        'name': fileName,
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        AppLang.tr('err_upload_failed_code').replaceAll(
          '{code}',
          '${res.statusCode}',
        ),
      );
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      final err = json['error']?.toString() ?? res.body;
      throw Exception(
        AppLang.tr('err_upload_failed_detail').replaceAll('{detail}', err),
      );
    }

    final data = json['data'] as Map<String, dynamic>? ?? {};
    final url = (data['url'] ?? data['display_url'] ?? '').toString();
    if (url.isEmpty) {
      throw Exception(AppLang.tr('err_image_url_missing'));
    }

    return MediaUploadResult(
      url: url,
      deleteUrl: (data['delete_url'] ?? '').toString(),
      providerId: (data['id'] ?? '').toString(),
    );
  }
}