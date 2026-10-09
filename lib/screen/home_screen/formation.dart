import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yafintech/core/outils/app_empty_state.dart';
import 'package:yafintech/screen/fenetre/audio_widget.dart';
import 'package:yafintech/screen/fenetre/image_widget.dart';
import 'package:yafintech/screen/fenetre/pdf_widget.dart';
import 'package:yafintech/screen/fenetre/video_widget.dart';
import 'package:yafintech/services/auth_service.dart';
import 'package:yafintech/services/reload_service.dart';

class Formation extends StatefulWidget {
  const Formation({super.key});

  @override
  State<Formation> createState() => _FormationState();
}

class _FormationState extends State<Formation> {
  Map<String, dynamic>? formationData;
  final getFormationService _formationservice = getFormationService();
  StreamSubscription? _streamSubscription;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _streamSubscription = _formationservice.formationStream.listen((data) {
      if (!mounted) return;

      if (data != null) {
        setState(() {
          // Si l'API renvoie directement une liste, on l'emballe dans un Map
          if (data is List) {
            formationData = {'data': data};
          } else {
            formationData = data as Map<String, dynamic>;
          }
          _hasLoaded = true;
          print('📚  : formationData');
        });
      } else {
        setState(() {
          formationData = null;
          _hasLoaded = true;
        });
      }
    });

    _formationservice.demarrer(interval: const Duration(seconds: 30));
  }

  @override
  Widget build(BuildContext context) {
    final dynamic rawData = formationData?['data'];

    final List<dynamic> dataList = rawData == null
        ? []
        : (rawData is List ? rawData : [rawData]);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      children: [
        if (dataList.isEmpty)
          SizedBox(
            height: 280,
            child: _hasLoaded
                ? const AppEmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'Aucune formation disponible',
                    message: 'Les nouvelles formations apparaîtront ici.',
                  )
                : const Center(child: CircularProgressIndicator.adaptive()),
          )
        else
          for (final element in dataList)
            if (element is Map)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PdfCard(
                  pdfPath: "$storageUrl/${element['file_path']}",
                  pdfCover: "$storageUrl/${element['cover_image']}",
                  pdfName: element['title'] ?? 'Sans titre',
                  pdfDescription: element['descripion'] ?? '',
                  is_free: element['is_free'] ?? true,
                  price: element['price'] ?? '00',
                  infos: element['creator'],
                ),
              ),
      ],
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _formationservice.arreter();
    super.dispose();
  }

  @override
  Widget FormationList() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(10),
        child: InkWell(
          onTap: () {
            print('Ressource tapped');
          },
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  image: DecorationImage(
                    image: AssetImage('assets/images/image (9).jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Titre de la formation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Description de la formation' * 3,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'gratuite',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '12/12/2023',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
