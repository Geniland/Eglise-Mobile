import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yafintech/core/outils/outils.dart';
import 'package:yafintech/services/secure_storage.dart';

class Moi extends StatefulWidget {
  const Moi({super.key});

  @override
  State<Moi> createState() => _MoiState();
}

class _MoiState extends State<Moi> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 25),
          InkWell(
            onTap: () {
              context.push('/profile');
            },
            child: Container(
              margin: EdgeInsets.only(left: 10, top: 5, bottom: 5, right: 5),
              child: Row(
                children: [
                  Container(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(
                        'assets/images/image (7).jpg',
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nom du fidele',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Statut du fidele',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 2,
            margin: EdgeInsets.symmetric(horizontal: 20),
            color: Colors.grey,
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Paramètres'),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Déconnexion'),
                  onTap: () async {
                    //await SecureStorageService.logout();
                    context.go('/connexion');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
