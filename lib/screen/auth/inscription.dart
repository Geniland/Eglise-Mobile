import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yafintech/core/outils/brand.dart';
import 'package:yafintech/core/theme/app_color.dart';
import 'package:yafintech/core/theme/app_font.dart';

//import 'package:yafintech/services/auth_service.dart';

class Inscription extends StatefulWidget {
  const Inscription({super.key});

  @override
  State<Inscription> createState() => _InscriptionState();
}

class _InscriptionState extends State<Inscription> {
  final _formKey = GlobalKey<FormState>();

  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final ageController = TextEditingController();
  final emailController = TextEditingController();
  bool loginError = false;

  int? selectedrole;

  final Map<String, dynamic> donnes = {};

  final List<Map<String, dynamic>> roles = [
    {'id': 1, 'label': 'role1'},
    {'id': 2, 'label': 'role2'},
    {'id': 3, 'label': 'role3'},
    {'id': 4, 'label': 'role4'},
  ];

  int? selectedfonction;

  final List<Map<String, dynamic>> fonctions = [
    {'id': 1, 'label': 'fonction1'},
    {'id': 2, 'label': 'fonction2'},
    {'id': 3, 'label': 'fonction3'},
    {'id': 4, 'label': 'fonction4'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            //color: Colors.red,
            margin: EdgeInsets.only(top: 20),
            child: Column(
              children: [
                const YafiBrand(),
                SizedBox(height: 5),
                Text(
                  'Créez votre compte',
                  style: AppFonts.font1.copyWith(
                    color: AppColors.couleur1,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                        TextFormField(
                          controller: nomController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez entrer votre Nom';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'nom complete',
                            //prefixIcon: const Icon(Icons.email),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                width: 3,
                                color: AppColors.couleur1,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(width: 3),
                            ),
                            // Bordure erreur
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                width: 3,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

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
                          decoration: InputDecoration(
                            //labelText: 'Email',
                            hintText: 'exemple@email.com',
                            //prefixIcon: const Icon(Icons.email),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                width: 3,
                                color: AppColors.couleur1,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(width: 3),
                            ),
                            // Bordure erreur
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                width: 3,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                        // SizedBox(height: 20),
                        // age
                        SizedBox(height: 20),

                        DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            hintText: 'Sélectionnez votre role',
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                width: 3,
                                color: AppColors.couleur1,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(width: 3),
                            ),
                            // Bordure erreur
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                width: 3,
                                color: Colors.red,
                              ),
                            ),
                            //prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: roles.map((genre) {
                            return DropdownMenuItem<int>(
                              value: genre['id'], // L'ID est la valeur
                              child: Text(genre['label']), // Le texte affiché
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            setState(() {
                              selectedrole = newValue; // Stocke l'ID
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Veuillez sélectionner un role';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            hintText: 'Sélectionnez votre fonction',
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                width: 3,
                                color: AppColors.couleur1,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(width: 3),
                            ),
                            // Bordure erreur
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                width: 3,
                                color: Colors.red,
                              ),
                            ),
                          ),

                          items: fonctions.map((fonction) {
                            return DropdownMenuItem<int>(
                              value: fonction['id'], // L'ID est la valeur
                              child: Text(
                                fonction['label'],
                              ), // Le texte affiché
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            setState(() {
                              selectedfonction = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Veuillez sélectionner un role';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                if (_formKey.currentState!.validate()) {
                                  donnes['nom'] = nomController.text;
                                  donnes['email'] = emailController.text;
                                  donnes['role'] = selectedrole;
                                  donnes['fonction'] = selectedfonction;
                                  await context.push(
                                    '/password',
                                    extra: donnes,
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
                SizedBox(height: 40),
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
      ),
    );
  }
}

Widget Age() {
  return TextFormField(
    //controller: ageController,
    keyboardType: TextInputType.number,
    validator: (value) {
      if (value == null || value.isEmpty) {
        return null; // Pas d'erreur
      }
      // S
      if (int.tryParse(value) == null) {
        return 'Veuillez entrer un nombre valide';
      }
      int age = int.parse(value);
      if (age < 1 || age > 120) {
        return 'Âge invalide (1-120)';
      }
      return null;
    },
    decoration: InputDecoration(
      //labelText: 'Mot de passe',
      hintText: 'age',
      // Bordure active (au focus)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide(width: 3, color: AppColors.couleur1),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide(width: 3),
      ),
      // Bordure erreur
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide(width: 3, color: Colors.red),
      ),
    ),
  );
}
