import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:yafintech/core/outils/brand.dart';
import 'package:yafintech/core/outils/outils.dart';
import 'package:yafintech/core/theme/app_color.dart';
import 'package:yafintech/core/theme/app_font.dart';

//import 'package:yafintech/services/auth_service.dart';

class InscriptionLocal extends StatefulWidget {
  final Map<String, dynamic> nouveauUtilisateur;
  const InscriptionLocal({super.key, required this.nouveauUtilisateur});

  @override
  State<InscriptionLocal> createState() => _InscriptionState();
}

class _InscriptionState extends State<InscriptionLocal> {
  final _formKey = GlobalKey<FormState>();

  final dateController = TextEditingController();
  final lieuController = TextEditingController();
  final paysController = TextEditingController();
  final villeController = TextEditingController();
  final addressController = TextEditingController();
  final professionController = TextEditingController();

  bool loginError = false;

  String? selectgenre;

  DateTime? dateNaissance;
  String? dateNaissances;

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
            child: AuthProgressIndicator(step: 3),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Votre adresse',
                style: AppFonts.font1.copyWith(
                  color: AppColors.couleur1,
                  fontSize: 20,
                ),
              ),
              AppOutils.espace10,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppOutils.espace10,
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: dateNaissance == null
                              ? ''
                              : '${dateNaissance!.day.toString().padLeft(2, '0')}/'
                                    '${dateNaissance!.month.toString().padLeft(2, '0')}/'
                                    '${dateNaissance!.year}',
                        ),
                        decoration: AppOutils.inputDecoration(
                          hintText: 'Date de naissance',
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          final DateTime? date = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );

                          if (date != null) {
                            setState(() {
                              dateNaissances = DateFormat('yyyy-MM-dd')
                                  .format(date);
                              dateNaissance = DateTime(
                                date.year,
                                date.month,
                                date.day,
                              );
                            });
                          }
                        },
                      ),
                      AppOutils.espace20,
                      TextFormField(
                        controller: lieuController,
                        decoration: AppOutils.inputDecoration(
                          hintText: 'lieu de naissance',
                        ),
                      ),
                      AppOutils.espace20,
                      TextFormField(
                        controller: addressController,
                        decoration: AppOutils.inputDecoration(
                          hintText: 'address de risidance',
                        ),
                      ),

                      AppOutils.espace20,
                      TextFormField(
                        controller: villeController,
                        decoration: AppOutils.inputDecoration(
                          hintText: 'ville de risidance',
                        ),
                      ),
                      AppOutils.espace20,
                      TextFormField(
                        controller: paysController,
                        decoration: AppOutils.inputDecoration(
                          hintText: 'pays de residance',
                          //counterText: ,
                        ),
                      ),
                      AppOutils.espace20,
                      TextFormField(
                        controller: professionController,
                        decoration: AppOutils.inputDecoration(
                          hintText: 'pays de proffession',
                          //counterText: ,
                        ),
                      ),
                      AppOutils.espace20,
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (_formKey.currentState!.validate()) {
                                await {
                                  widget.nouveauUtilisateur['birth_date'] =
                                      dateController.text,
                                  widget.nouveauUtilisateur['birth_place'] =
                                      lieuController.text,
                                  widget.nouveauUtilisateur['address'] =
                                      addressController.text,
                                  widget.nouveauUtilisateur['city'] =
                                      villeController.text,
                                  widget.nouveauUtilisateur['country'] =
                                      paysController.text,
                                  widget.nouveauUtilisateur['profession'] =
                                      professionController.text,
                                  context.push(
                                    '/inscriptionStatut',
                                    extra: widget.nouveauUtilisateur,
                                  ),
                                };
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
}
