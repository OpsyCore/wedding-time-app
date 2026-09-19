import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/app_lang.dart';
import 'export_csv_web.dart'
    if (dart.library.io) 'export_csv_io.dart' as csv_share;

/// خروجی PDF/اکسل (ویژهٔ پرمیوم) — مهمان‌ها و بودجه
class ExportService {
  ExportService._();

  static String _fa(String input) {
    const d = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return input.split('').map((p) {
      final i = int.tryParse(p);
      return i != null ? d[i] : p;
    }).join();
  }

  static String _money(int v) => _fa(v.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      ));

  static Future<pw.Font> _font() async {
    final data = await rootBundle.load('assets/fonts/Estedad-Regular.ttf');
    return pw.Font.ttf(data);
  }

  static pw.ThemeData _theme(pw.Font font) => pw.ThemeData.withFont(
        base: font,
        bold: font,
      );

  static PdfColor _headerColor() => const PdfColor.fromInt(0xFF3E5A43);

  // ─────────────────────────── مهمان‌ها ───────────────────────────

  static Future<void> guestsPdf({
    required String coupleTitle,
    required List<Map<String, dynamic>> guests,
  }) async {
    final font = await _font();
    final isFa = AppLang.I.isFa;
    final pdf = pw.Document(theme: _theme(font));

    final rows = guests.map((g) {
      final name = (g['name'] ?? '').toString();
      final phone = (g['phone'] ?? '').toString();
      final group = (g['group'] ?? '').toString();
      final status = (g['status'] ?? '').toString();
      final statusLabel = status == 'yes'
          ? (isFa ? 'تأیید' : 'Confirmed')
          : status == 'no'
              ? (isFa ? 'عدم تأیید' : 'Declined')
              : (isFa ? 'در انتظار' : 'Pending');
      return [name, phone, group, statusLabel];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            isFa ? 'فهرست مهمان‌ها — $coupleTitle' : 'Guest list — $coupleTitle',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _headerColor(),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            isFa
                ? 'تعداد کل: ${_fa(guests.length.toString())} نفر'
                : 'Total: ${guests.length}',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            textDirection: pw.TextDirection.rtl,
            headerAlignment: pw.Alignment.centerRight,
            cellAlignment: pw.Alignment.centerRight,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFFFFFFFF),
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF3E5A43),
            ),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFDDDDDD),
                  width: 0.5,
                ),
              ),
            ),
            headers: [
              isFa ? 'نام' : 'Name',
              isFa ? 'شماره تماس' : 'Phone',
              isFa ? 'گروه' : 'Group',
              isFa ? 'وضعیت' : 'Status',
            ],
            data: rows,
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'wedding-guests.pdf',
    );
  }

  static Future<void> guestsCsv({
    required String coupleTitle,
    required List<Map<String, dynamic>> guests,
  }) async {
    final sb = StringBuffer();
    sb.writeln('name,phone,group,status,note');
    for (final g in guests) {
      final esc = (Object? v) =>
          '"${(v ?? '').toString().replaceAll('"', '""')}"';
      sb.writeln([
        esc(g['name']),
        esc(g['phone']),
        esc(g['group']),
        esc(g['status']),
        esc(g['note']),
      ].join(','));
    }
    await csv_share.shareCsvFile('wedding-guests.csv', sb.toString());
  }

  // ─────────────────────────── بودجه ───────────────────────────

  static Future<void> budgetPdf({
    required String coupleTitle,
    required List<Map<String, dynamic>> expenses,
  }) async {
    final font = await _font();
    final isFa = AppLang.I.isFa;
    final pdf = pw.Document(theme: _theme(font));

    var estTotal = 0;
    var actTotal = 0;
    final rows = expenses.map((e) {
      final est = (e['estimatedAmount'] as num?)?.toInt() ?? 0;
      final act = (e['actualAmount'] as num?)?.toInt() ?? 0;
      estTotal += est;
      actTotal += act;
      return [
        (e['title'] ?? '').toString(),
        (e['category'] ?? '').toString(),
        (e['payer'] ?? '').toString(),
        _money(est),
        _money(act),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            isFa ? 'گزارش بودجه — $coupleTitle' : 'Budget report — $coupleTitle',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _headerColor(),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            isFa
                ? 'جمع برآورد: ${_money(estTotal)} تومان — جمع واقعی: ${_money(actTotal)} تومان'
                : 'Estimated: $estTotal — Actual: $actTotal',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            textDirection: pw.TextDirection.rtl,
            headerAlignment: pw.Alignment.centerRight,
            cellAlignment: pw.Alignment.centerRight,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFFFFFFFF),
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF3E5A43),
            ),
            headers: [
              isFa ? 'عنوان' : 'Title',
              isFa ? 'دسته' : 'Category',
              isFa ? 'پرداخت‌کننده' : 'Payer',
              isFa ? 'برآورد' : 'Estimated',
              isFa ? 'واقعی' : 'Actual',
            ],
            data: rows,
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'wedding-budget.pdf');
  }

  static Future<void> budgetCsv({
    required String coupleTitle,
    required List<Map<String, dynamic>> expenses,
  }) async {
    final sb = StringBuffer();
    sb.writeln('title,category,payer,estimated,actual,note');
    for (final e in expenses) {
      final esc = (Object? v) =>
          '"${(v ?? '').toString().replaceAll('"', '""')}"';
      sb.writeln([
        esc(e['title']),
        esc(e['category']),
        esc(e['payer']),
        esc(e['estimatedAmount']),
        esc(e['actualAmount']),
        esc(e['note']),
      ].join(','));
    }
    await csv_share.shareCsvFile('wedding-budget.csv', sb.toString());
  }
}
