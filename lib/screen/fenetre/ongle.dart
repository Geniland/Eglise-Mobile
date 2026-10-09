import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yafintech/screen/home_screen/formation.dart';
import 'package:yafintech/screen/home_screen/mesRessource.dart';
import 'package:yafintech/screen/home_screen/ressource.dart';

class Onglets extends StatefulWidget {
  final int index;
  const Onglets({super.key, required this.index});

  @override
  State<Onglets> createState() => _OngletsState();
}

class _OngletsState extends State<Onglets> {
  @override
  Widget build(BuildContext context) {
    final TabBarView listOngle = TabBarView(
      children: [
        Center(child: Formation()),
        Center(child: Ressource()),
        Center(child: MesRessource()),
      ],
    );
    return DefaultTabController(
      length: listOngle.children.length,
      initialIndex: widget.index,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Etudes'),
          leading: IconButton(
            onPressed: () {
              context.pop();
            },
            icon: Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              onPressed: () {
                debugPrint('🔍 Recherche');
              },
              icon: const Icon(Icons.search),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Formations'),
              Tab(text: 'Ressources'),
              Tab(text: 'Téléchargées'),
            ],
            // Optionnel : rendre les onglets défilables horizontalement
            isScrollable: true,
            // Optionnel : changer la couleur de l'indicateur
          ),
        ),

        body: listOngle,
      ),
    );
  }
}
