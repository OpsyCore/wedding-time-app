// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// دانلود فایل CSV (اکسل) روی وب
Future<void> shareCsvFile(String filename, String csvContent) async {
  final bytes = Uint8List.fromList('\uFEFF$csvContent'.codeUnits);
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final a = html.AnchorElement(href: url)..download = filename;
  html.document.body?.append(a);
  a.click();
  a.remove();
  html.Url.revokeObjectUrl(url);
}
