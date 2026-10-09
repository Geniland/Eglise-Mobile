import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:yafintech/core/outils/brand.dart';
import 'package:yafintech/core/outils/outils.dart';
import 'package:yafintech/core/theme/app_color.dart';
import 'package:yafintech/core/theme/app_font.dart';

//import 'package:yafintech/services/auth_service.dart';

class InscriptionMail extends StatefulWidget {
  final Map<String, dynamic> nouveauUtilisateur;
  const InscriptionMail({super.key, required this.nouveauUtilisateur});
  static bool authError = false;
  static String authMessage = '';
  @override
  State<InscriptionMail> createState() => _InscriptionState();
}

class _InscriptionState extends State<InscriptionMail> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final telController = TextEditingController();
  final paysController = TextEditingController();
  final villeController = TextEditingController();
  final addressController = TextEditingController();

  bool loginError = false;

  String? selectgenre;
  String? numero;
  String? telError;

  final Map<String, dynamic> donnes = {};

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
            child: AuthProgressIndicator(step: 2),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Vos coordonnées',
                style: AppFonts.font1.copyWith(
                  color: AppColors.couleur1,
                  fontSize: 20,
                ),
              ),
              AppOutils.espace10,
              Visibility(
                visible: InscriptionMail.authError,
                child: Text(
                  InscriptionMail.authMessage,
                  style: GoogleFonts.daiBannaSil(
                    fontSize: 18,
                    color: Colors.red,
                  ),
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
                      AppOutils.espace10,
                      TextFormField(
                        controller: emailController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer votre email';
                          }
                          if (!value.contains('@')) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                        decoration: AppOutils.inputDecoration(
                          hintText: 'example@gmail.com',
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
                                if (numero == null || numero == '') {
                                  print(numero);
                                } else {
                                  await (
                                    InscriptionMail.authError = false,
                                    InscriptionMail.authError = false,
                                    widget.nouveauUtilisateur['email'] =
                                        emailController.text,
                                    widget.nouveauUtilisateur['phone'] = numero,
                                    context.push(
                                      '/password',
                                      extra: widget.nouveauUtilisateur,
                                    ),
                                  );
                                }
                                ;
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
                child: Text('retour', style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
