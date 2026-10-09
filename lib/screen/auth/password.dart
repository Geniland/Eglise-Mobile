import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yafintech/core/outils/brand.dart';
import 'package:yafintech/core/outils/outils.dart';
import 'package:yafintech/core/theme/app_color.dart';
import 'package:yafintech/core/theme/app_font.dart';
import 'package:yafintech/screen/auth/inscription_mail.dart';
import 'package:yafintech/screen/auth/inscription_nom.dart';
//import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yafintech/services/auth_service.dart';

// ignore: must_be_immutable
class Password extends StatefulWidget {
  final Map<String, dynamic> nouveauUtilisateur;
  const Password({super.key, required this.nouveauUtilisateur});

  @override
  State<Password> createState() => _PasswordState();
}

class _PasswordState extends State<Password> {
  //Map<String, dynamic> donnes = {};
  bool _passevisible = false;
  bool _passeconfirmevisible = false;
  final _formKey = GlobalKey<FormState>();

  final passwordController = TextEditingController();
  final passwordConfimController = TextEditingController();

  bool passeError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            //color: Colors.red,
            margin: EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                const YafiBrand(),
                const SizedBox(height: 22),
                const SizedBox(
                  width: 320,
                  child: AuthProgressIndicator(step: 5),
                ),
                SizedBox(height: 20),
                Text(
                  'Sécurisez votre compte',
                  style: AppFonts.font1.copyWith(
                    color: AppColors.couleur1,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 30),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Visibility(
                          visible: passeError,
                          child: Text(
                            'Mot de passe non identique',
                            style: GoogleFonts.daiBannaSil(
                              fontSize: 18,
                              color: Colors.red,
                            ),
                          ),
                        ),

                        SizedBox(height: 10),
                        TextFormField(
                          controller: passwordController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe';
                            }
                            return null;
                          },

                          decoration: AppOutils.inputDecoration(
                            //labelText: 'Mot de passe',
                            hintText: 'mot de passe',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passevisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passevisible = !_passevisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !_passevisible,
                        ),
                        SizedBox(height: 30),
                        TextFormField(
                          controller: passwordConfimController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe';
                            }
                            return null;
                          },
                          decoration: AppOutils.inputDecoration(
                            hintText: 'confirmer le mot de passe',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passeconfirmevisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passeconfirmevisible =
                                      !_passeconfirmevisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !_passeconfirmevisible,
                        ),

                        SizedBox(height: 50),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                role_fonction();
                                if (passwordController.text !=
                                    passwordConfimController.text) {
                                  passeError = true;
                                } else {
                                  widget.nouveauUtilisateur['password'] =
                                      passwordController.text;
                                  String reponse = await register(
                                    widget.nouveauUtilisateur,
                                  );
                                  InscriptionMail.authError = false;
                                  InscriptionMail.authError = false;
                                  print(
                                    '🀄🀄🀄🀄🀄🀄🀄🀄🀄🀄🀄🀄🀄🀄🀄 $reponse',
                                  );
                                  if (reponse == "Compte créé avec succès") {
                                    print('🏐🏐🏐🏐🏐🏐🏐🏐🏐🏐🏐🏐🏐🏐');
                                    setState(() {
                                      context.go('/');
                                    });
                                  } else if (reponse ==
                                      'The email has already been taken.') {
                                    setState(() {
                                      InscriptionMail.authError = true;
                                      InscriptionMail.authMessage = reponse;
                                      context.pop('/inscriptionMail');
                                    });
                                  } else if (reponse ==
                                      "Code d'église invalide.") {
                                    setState(() {
                                      InscriptionNom.authError = true;
                                      InscriptionNom.authMessage = reponse;
                                      context.go('/inscriptionNom');
                                    });
                                  }
                                  passeError = false;
                                }
                                ;
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColors.couleur1,
                            ),
                            child: Text(
                              'Enregistre',
                              style: GoogleFonts.daiBannaSil(fontSize: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 40),
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
      ),
    );
  }
}
