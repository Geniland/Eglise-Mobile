import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart'; // ✅ Gardez uniquement celui-ci
import 'package:path_provider/path_provider.dart';

Future<void> sauvegarderDansGalerie(String imageUrl, String imageName) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      await Gal.putImageBytes(response.bodyBytes, name: imageName);

      const SnackBar(
        content: Text('video Télécharger'),
        duration: Duration(seconds: 2),
      );
    }
  } catch (e) {
    print('Erreur : $e');
  }
}

Future<void> telechargerPdf(
  BuildContext context,
  String pdfUrl,
  String pdfName,
) async {
  if (pdfUrl.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('URL du PDF invalide')));
    return;
  }

  // ✅ 1. Capturer le ScaffoldMessenger AVANT les appels asynchrones
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  try {
    // 2. Afficher un indicateur de chargement
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Téléchargement du PDF en cours...'),
        duration: Duration(seconds: 2),
      ),
    );

    // 3. Télécharger le fichier
    final response = await http.get(Uri.parse(pdfUrl));

    if (response.statusCode == 200) {
      // 4. Trouver le dossier de stockage
      final directory = await getApplicationDocumentsDirectory();

      // 5. Créer un nom de fichier unique
      final String nomFichier =
          //'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
          '$pdfName.pdf';
      final String cheminFichier = '${directory.path}/$nomFichier';

      // 6. Écrire le fichier sur le disque
      final File fichier = File(cheminFichier);
      await fichier.writeAsBytes(response.bodyBytes);

      // 7. Informer l'utilisateur (Utilisation du messenger capturé)
      messenger.showSnackBar(
        const SnackBar(content: Text('PDF téléchargé avec succès !')),
      );

      // 8. Ouvrir automatiquement le PDF
      await OpenFilex.open(cheminFichier);
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Erreur de téléchargement : ')),
    );
  }
}
