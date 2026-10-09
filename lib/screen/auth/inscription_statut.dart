import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:yafintech/core/outils/brand.dart';
import 'package:yafintech/core/outils/outils.dart';
import 'package:yafintech/core/theme/app_color.dart';
import 'package:yafintech/core/theme/app_font.dart';

//import 'package:yafintech/services/auth_service.dart';

class InscriptionStatut extends StatefulWidget {
  final Map<String, dynamic> nouveauUtilisateur;
  const InscriptionStatut({super.key, required this.nouveauUtilisateur});

  @override
  State<InscriptionStatut> createState() => _InscriptionState();
}

class _InscriptionState extends State<InscriptionStatut> {
  final _formKey = GlobalKey<FormState>();

  final epousController = TextEditingController();
  final urgenceController = TextEditingController();
  final urgenceTelController = TextEditingController();

  bool loginError = false;

  bool? marie = false;

  String? selectgenre;

  String? numero;

  DateTime? convertiondate;
  String? convertiondates;
  DateTime? baptemedate;
  String? baptemedates;
  DateTime? integrationdate;
  String? integrationdates;

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
            child: AuthProgressIndicator(step: 4),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Quelques informations supplémentaires',
                style: AppFonts.font1.copyWith(
                  color: AppColors.couleur1,
                  fontSize: 20,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppOutils.espace10,

                      RadioGroup<bool>(
                        groupValue: marie,
                        onChanged: (value) {
                          setState(() {
                            marie = value;
                            epousController.text = '';
                          });
                        },
                        child: Row(
                          children: [
                            Radio<bool>(value: false),
                            const Text('Célibataire'),

                            Radio<bool>(value: true),
                            const Text('Marié'),
                          ],
                        ),
                      ),
                      TextFormField(
                        enabled: marie,
                        controller: epousController,
                        decoration: AppOutils.inputDecoration(
                          hintText: 'nom complet de lepous/e',
                        ),
                      ),

                      AppOutils.espace20,
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: convertiondate == null
                              ? ''
                              : '${convertiondate!.day.toString().padLeft(2, '0')}/'
                                    '${convertiondate!.month.toString().padLeft(2, '0')}/'
                                    '${convertiondate!.year}',
                        ),
                        decoration: AppOutils.inputDecoration(
                          hintText: 'Date de convertion',
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
                              convertiondates = DateFormat('yyyy-MM-dd')
                                  .format(date);
                              convertiondate = DateTime(
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
                        readOnly: true,
                        controller: TextEditingController(
                          text: baptemedate == null
                              ? ''
                              : '${baptemedate!.day.toString().padLeft(2, '0')}/'
                                    '${baptemedate!.month.toString().padLeft(2, '0')}/'
                                    '${baptemedate!.year}',
                        ),
                        decoration: AppOutils.inputDecoration(
                          hintText: 'Date de bapteme',
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
                              baptemedates = DateFormat('yyyy-MM-dd')
                                  .format(date);
                              baptemedate = DateTime(
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
                        readOnly: true,
                        controller: TextEditingController(
                          text: integrationdate == null
                              ? ''
                              : '${integrationdate!.day.toString().padLeft(2, '0')}/'
                                    '${integrationdate!.month.toString().padLeft(2, '0')}/'
                                    '${integrationdate!.year}',
                        ),
                        decoration: AppOutils.inputDecoration(
                          hintText: "Date d'integration",
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
                              integrationdates = DateFormat('yyyy-MM-dd')
                                  .format(date);
                              integrationdate = DateTime(
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
                        controller: urgenceController,
                        decoration: AppOutils.inputDecoration(
                          hintText: "contact d'urgence",
                        ),
                      ),
                      AppOutils.espace20,
                      IntlPhoneField(
                        //controller: telController,
                        initialCountryCode: 'TG',
                        decoration: AppOutils.inputDecoration(
                          hintText: 'numéro de téléphone',
                        ),
                        validator: (value) {
                          numero = value?.completeNumber;
                          if (value == null || value.number.trim().isEmpty) {
                            return 'Veuillez entrer votre numéro de téléphone';
                          }

                          try {
                            if (!value.isValidNumber()) {
                              return 'Veuillez entrer un numéro de téléphone valide';
                            }
                          } catch (e) {
                            return 'Veuillez entrer un numéro de téléphone valide';
                          }

                          return null;
                        },
                      ),

                      AppOutils.espace20,
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (_formKey.currentState!.validate()) {
                                await {
                                  widget.nouveauUtilisateur['marital_status'] =
                                      marie,
                                  widget.nouveauUtilisateur['spouse_name'] =
                                      epousController.text,
                                  widget.nouveauUtilisateur['emergency_contact'] =
                                      urgenceController.text,
                                  widget.nouveauUtilisateur['emergency_phne'] =
                                      numero,
                                  context.push(
                                    '/inscriptionProfile',
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
