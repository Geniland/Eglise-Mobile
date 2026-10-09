import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yafintech/screen/fenetre/audio_widget.dart';
import 'package:yafintech/screen/fenetre/image_widget.dart';
import 'package:yafintech/screen/fenetre/video_widget.dart';
import 'package:yafintech/services/auth_service.dart';
import 'package:video_player/video_player.dart';
import 'package:yafintech/services/reload_service.dart';

class MesRessource extends StatefulWidget {
  const MesRessource({super.key});

  @override
  State<MesRessource> createState() => _MesRessourceState();
}

class _MesRessourceState extends State<MesRessource> {
  Map<String, dynamic>? ressourcesData;
  final getMyRessourceService _ressourceservice = getMyRessourceService();
  StreamSubscription? _streamSubscription;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();

    _streamSubscription = _ressourceservice.ressourceStream.listen((data) {
      if (!mounted) return;

      if (data != null) {
        setState(() {
          // Si l'API renvoie directement une liste, on l'emballe dans un Map
          if (data is List) {
            ressourcesData = {'data': data};
          } else {
            ressourcesData = data as Map<String, dynamic>;
          }
          _hasLoaded = true;
          print('🐩 : mesressourcesData');
        });
      } else {
        // Si data est null (204/404), on vide les données
        setState(() {
          ressourcesData = null;
          _hasLoaded = true;
        });
      }
    });

    _ressourceservice.demarrer(interval: const Duration(seconds: 30));
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLoaded) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final dynamic rawData = ressourcesData?['data'];

    final List<dynamic> dataList = rawData == null
        ? []
        : (rawData is List ? rawData : [rawData]);
    return Container(
      //margin: EdgeInsets.only(top: 10),
      child: ListView(
        shrinkWrap: true,
        children: [
          if (dataList.isEmpty)
            Container(
              margin: EdgeInsets.all(20),
              alignment: AlignmentGeometry.center,
              height: 220,
              width: double.infinity,
              child: Text(
                'aucune ressource telechargé ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          else
            for (final element in dataList)
              if (element is Map && element['type'] != null)
                if (element['type'] == "video")
                  VideoCard(
                    videoUrl: "$storageUrl/${element['file_path']}",
                    title: element['title'] ?? 'Sans titre',
                    description: element['description'] ?? '',
                    is_free: element['is_free'] ?? true,
                    price: element['price'] ?? 00,
                  )
                else if (element['type'] == "image")
                  ImageCard(
                    imagePath: "$storageUrl/${element['file_path']}",
                    imageName: element['title'] ?? 'Sans titre',
                    imageDescription: element['descripion'] ?? '',
                    is_free: element['is_free'] ?? true,
                    price: element['price'] ?? '00',
                  )
                else if (element['type'] == "audio")
                  AudioCard(
                    audioUrl: "$storageUrl/${element['file_path']}",
                    title: element['title'] ?? 'Sans titre',
                    description: element['descripion'] ?? '',
                    is_free: element['is_free'] ?? true,
                    price: element['price'] ?? '00',
                  ),

          //for (int i = 0; i < 16; i++) RessourceList(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _ressourceservice.arreter();
    super.dispose();
  }

  @override
  Widget RessourceList() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(10),
        child: InkWell(
          onTap: () {
            print('Ressource tapped');
            setState(() {
              context.push('/audio');
            });
          },
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  image: DecorationImage(
                    image: AssetImage('assets/images/image (6).jpg'),
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
                        'Titre de la ressource',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Description de la ressource',
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
