import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:yafintech/services/telecharge_service.dart';

class PdfPage extends StatefulWidget {
  final String pdfPath;
  final String pdfName;
  final String pdfDescription;

  const PdfPage({
    super.key,
    required this.pdfPath,
    required this.pdfName,
    required this.pdfDescription,
  });

  @override
  State<PdfPage> createState() => _PdfPageState();
}

class _PdfPageState extends State<PdfPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ 1. Suppression du 'const' devant Text
      appBar: AppBar(
        title: Text(widget.pdfName),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Appelez votre fonction de téléchargement ici
              telechargerPdf(context, widget.pdfPath, widget.pdfName);
            },
          ),
        ],
      ),
      body: SfPdfViewer.network(
        // ✅ 2. Utilisation de l'URL dynamique
        widget.pdfPath,
      ),
    );
  }
}
