import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PdfPreviewPage extends StatelessWidget {
  final List<Map<String, dynamic>> selectedTours;

  const PdfPreviewPage({super.key, required this.selectedTours});

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      build: (format) => _generatePdf(format, selectedTours),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, List<Map<String, dynamic>> tours) async {
    // If only one tour is selected and it has a PDF URL, try to download and return it directly
    if (tours.length == 1 && tours.first['pdfUrl'] != null) {
      try {
        final url = tours.first['pdfUrl'] as String;
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      } catch (e) {
        debugPrint('Error downloading PDF: $e');
      }
    }

    // If multiple tours or download failed, generate a new PDF combining them
    // Note: Merging existing PDFs is complex. We will regenerate the PDF content here
    // but we will include the QR code pointing to the existing PDF URL if available.
    
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final theme = pw.ThemeData.withFont(base: font, bold: font, italic: font);

    for (final tour in tours) {
      final displayData = Map<String, dynamic>.from(tour)..remove('id')..remove('pdfUrl');
      final tourId = tour['id']?.toString() ?? '';
      
      // Reconstruct the public URL for the QR code
      // This matches the logic used in uploads package
      String qrContent = tour['pdfUrl'] ?? '';
      if (qrContent.isEmpty && tourId.isNotEmpty) {
         try {
            final bucketName = FirebaseStorage.instance.app.options.storageBucket;
            final pdfPath = 'tour_pdfs/$tourId.pdf';
            final encodedPath = Uri.encodeComponent(pdfPath);
            qrContent = 'https://firebasestorage.googleapis.com/v0/b/$bucketName/o/$encodedPath?alt=media';
         } catch (e) {
            qrContent = tourId;
         }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: format,
          theme: theme,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(tour['tourName']?.toString() ?? 'Tên tour không có', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
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
                  ...displayData.entries.where((e) => e.key != 'tourName' && e.key != 'mediaUrls').map((entry) {
                     String key = entry.key;
                     String value = entry.value?.toString() ?? 'N/A';
                     
                     if (key == 'price' && entry.value != null) {
                        value = '${entry.value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ';
                     }

                     String displayKey = _translateKey(key);

                     return pw.Padding(
                       padding: const pw.EdgeInsets.only(bottom: 5),
                       child: pw.Row(
                         crossAxisAlignment: pw.CrossAxisAlignment.start,
                         children: [
                           pw.SizedBox(
                             width: 120,
                             child: pw.Text('$displayKey:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
                  pw.Text('Quét mã QR để xem chi tiết:', style: const pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 10),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: qrContent,
                    width: 150,
                    height: 150,
                  ),
                  pw.SizedBox(height: 5),
                  // pw.Text(qrContent, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return pdf.save();
  }

  String _translateKey(String key) {
    switch (key) {
      case 'tourName': return 'Tên tour';
      case 'departureDate': return 'Ngày khởi hành';
      case 'duration': return 'Thời gian';
      case 'transport': return 'Phương tiện';
      case 'departureLocation': return 'Điểm khởi hành';
      case 'destination': return 'Điểm đến';
      case 'price': return 'Giá tiền';
      case 'description': return 'Mô tả';
      default: return key;
    }
  }
}
