import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  Future<Uint8List> generateTourPdf(Map<String, dynamic> tour, String qrContent) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final theme = pw.ThemeData.withFont(base: font, bold: font, italic: font);

    // Filter out ID and prepare data
    final displayData = Map<String, dynamic>.from(tour)..remove('id');
    // final tourId = tour['id']?.toString() ?? ''; // No longer needed for QR

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(tour['tourName']?.toString() ?? 'Tên tour không có',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 10),
                ...displayData.entries
                    .where((e) => e.key != 'tourName' && e.key != 'mediaUrls')
                    .map((entry) {
                  String key = entry.key;
                  String value = entry.value?.toString() ?? 'N/A';

                  // Format price if needed
                  if (key == 'price' && entry.value != null) {
                    value =
                        '${entry.value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ';
                  }

                  String displayKey = _translateKey(key);

                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(
                          width: 120,
                          child: pw.Text('$displayKey:',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Expanded(child: pw.Text(value)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text('Quét mã QR để xem chi tiết:',
                    style: const pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 10),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrContent,
                  width: 150,
                  height: 150,
                ),
                pw.SizedBox(height: 5),
                // pw.Text(tourId, style: const pw.TextStyle(fontSize: 10)), // Optional: hide raw URL or show it
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  String _translateKey(String key) {
    switch (key) {
      case 'tourName':
        return 'Tên tour';
      case 'departureDate':
        return 'Ngày khởi hành';
      case 'duration':
        return 'Thời gian';
      case 'transport':
        return 'Phương tiện';
      case 'departureLocation':
        return 'Điểm khởi hành';
      case 'destination':
        return 'Điểm đến';
      case 'price':
        return 'Giá tiền';
      case 'description':
        return 'Mô tả';
      default:
        return key;
    }
  }
}
