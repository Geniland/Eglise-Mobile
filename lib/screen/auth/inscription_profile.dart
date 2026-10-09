import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yafintech/core/outils/brand.dart';
import 'package:yafintech/core/outils/outils.dart';
import 'package:yafintech/core/theme/app_color.dart';
import 'package:yafintech/core/theme/app_font.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yafintech/services/auth_service.dart';

//import 'package:yafintech/services/auth_service.dart';

class InscriptionProfile extends StatefulWidget {
  final Map<String, dynamic> nouveauUtilisateur;
  const InscriptionProfile({super.key, required this.nouveauUtilisateur});

  @override
  State<InscriptionProfile> createState() => _InscriptionState();
}

class _InscriptionState extends State<InscriptionProfile> {
  File? photoProfil;

  final Map<String, dynamic> donnes = {};

  final List<String> genres = ['Homme', 'Femme', 'Je prefere ne pas definire'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const YafiBrand(compact: true),
        automaticallyImplyLeading: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(36),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: AuthProgressIndicator(step: 6),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Ajoutez une photo de profil',
                style: AppFonts.font1.copyWith(
                  color: AppColors.couleur1,
                  fontSize: 20,
                ),
              ),
              AppOutils.espace20,
              AppOutils.espace20,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: choisirPhoto,
                  child: CircleAvatar(
                    radius: 64,
                    backgroundImage: photoProfil != null
                        ? FileImage(photoProfil!)
                        : null,
                    child: photoProfil == null
                        ? const Icon(Icons.camera_alt, size: 35)
                        : null,
                  ),
                ),
              ),
              AppOutils.espace20,
              AppOutils.espace20,
              AppOutils.espace20,
              ElevatedButton(
                onPressed: () async {
                  await {
                    widget.nouveauUtilisateur['photo'] = photoProfil,
                    widget.nouveauUtilisateur['status'] = '',
                    widget.nouveauUtilisateur['created_by'] = '',
                    widget.nouveauUtilisateur['updated_by'] = '',
                    widget.nouveauUtilisateur['family_id'] = '',
                    widget.nouveauUtilisateur['member_type'] = '',
                    register_Menber(widget.nouveauUtilisateur),
                    //context.push('/', extra: widget.nouveauUtilisateur),
                  };
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.couleur1,
                ),
                child: Text(
                  'terminé',
                  style: GoogleFonts.daiBannaSil(fontSize: 20),
                ),
              ),
              AppOutils.espace20,
              TextButton(
                onPressed: () {
                  context.pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.couleur1,
                  overlayColor: Colors.transparent,
                ),
                child: Text('retour ', style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> choisirPhoto() async {
    final ImagePicker picker = ImagePicker();

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Galerie'),
                onTap: () {
                  Navigator.pop(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Caméra'),
                onTap: () {
                  Navigator.pop(context, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      // setState(() async { photoProfil = File(image.path);final fichier = await enregistrerPhoto(image);});
    }
  }

  Future<File> enregistrerPhoto(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();

    final chemin = '${directory.path}/photo_profil.jpg';

    final fichier = File(chemin);

    return await File(image.path).copy(fichier.path);
  }
}
