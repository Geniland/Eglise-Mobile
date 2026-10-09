import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yafintech/core/outils/brand.dart';
import 'package:yafintech/core/outils/outils.dart';
import 'package:yafintech/core/theme/app_color.dart';
import 'package:yafintech/core/theme/app_font.dart';
import 'package:yafintech/screen/auth/inscription_mail.dart';

//import 'package:yafintech/services/auth_service.dart';

class InscriptionNom extends StatefulWidget {
  const InscriptionNom({super.key});
  static bool authError = false;
  static String authMessage = '';
  @override
  State<InscriptionNom> createState() => _InscriptionNomState();
}

class _InscriptionNomState extends State<InscriptionNom> {
  final _formKey = GlobalKey<FormState>();

  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final genreController = TextEditingController();
  final codeController = TextEditingController();

  static bool codeError = false;
  String? selectgenre;

  final Map<String, dynamic> nouveauUtilisateur = {};

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
            child: AuthProgressIndicator(step: 1),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Vos informations personnelles',
                style: AppFonts.font1.copyWith(
                  color: AppColors.couleur1,
                  fontSize: 20,
                ),
              ),
              AppOutils.espace10,
              Visibility(
                visible: InscriptionNom.authError,
                child: Text(
                  InscriptionNom.authMessage,
                  style: GoogleFonts.daiBannaSil(
                    fontSize: 18,
                    color: Colors.red,
                  ),
                ),
              ),

              AppOutils.espace05,

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppOutils.espace10,
                      TextFormField(
                        controller: nomController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer votre Nom';
                          }
                          return null;
                        },
                        decoration: AppOutils.inputDecoration(hintText: 'nom'),
                      ),
                      AppOutils.espace20,
                      TextFormField(
                        controller: prenomController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer votre Prenom';
                          }
                          return null;
                        },
                        decoration: AppOutils.inputDecoration(
                          hintText: 'prenom',
                        ),
                      ),
                      AppOutils.espace20,
                      DropdownButtonFormField<String>(
                        decoration: AppOutils.inputDecoration(
                          hintText: 'genre',
                        ),
                        items: genres.map((genre) {
                          return DropdownMenuItem<String>(
                            value: genre,
                            child: Text(genre),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectgenre = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Veuillez sélectionner votre genre';
                          }
                          return null;
                        },
                      ),
                      AppOutils.espace20,
                      Visibility(
                        visible: codeError,
                        child: Text(
                          "Code d'eglise invalide",
                          style: GoogleFonts.daiBannaSil(
                            fontSize: 15,
                            color: Colors.red,
                          ),
                        ),
                      ),

                      AppOutils.espace05,
                      TextFormField(
                        controller: codeController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer le code de votre eglise';
                          }
                          return null;
                        },
                        decoration: AppOutils.inputDecoration(
                          hintText: "code d'eglise",
                        ),
                      ),
                      AppOutils.espace20,
                      AppOutils.espace20,
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (_formKey.currentState!.validate()) {
                                await (
                                  InscriptionMail.authError = false,
                                  InscriptionNom.authError = false,
                                  nouveauUtilisateur['first_name'] =
                                      nomController.text,
                                  nouveauUtilisateur['last_name'] =
                                      prenomController.text,
                                  nouveauUtilisateur['church_code'] =
                                      codeController.text,
                                  nouveauUtilisateur['gender'] = selectgenre,
                                  context.push(
                                    '/inscriptionMail',
                                    extra: nouveauUtilisateur,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: AppColors.couleur1,
                          ),
                          child: Text(
                            'Suivante',
                            style: GoogleFonts.daiBannaSil(fontSize: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppOutils.espace20,
              AppOutils.espace20,
              TextButton(
                onPressed: () {
                  context.pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.couleur1,
                  overlayColor: Colors.transparent,
                ),
                child: Text(
                  'retour á la connexion',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
