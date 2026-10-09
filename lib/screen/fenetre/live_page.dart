import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yafintech/core/theme/app_color.dart';
import 'package:yafintech/services/reload_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> with WidgetsBindingObserver {
  // ------------------------------------------------------------
  // VARIABLES
  // ------------------------------------------------------------

  final TextEditingController _tcontroller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool commente = false;

  double _lastBottomInset = 0;

  List<dynamic> lives = [];
  final LiveService _liveService = LiveService();
  StreamSubscription? _streamSubscription;

  final PageController _pageController = PageController();
  YoutubePlayerController? _ytController;

  int _currentIndex = 0;

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _streamSubscription = _liveService.liveStream.listen((data) {
      if (!mounted) return;

      final List<dynamic> newLives = data is Map
          ? (data?['data'] ?? [])
          : (data ?? []);

      print('💫  : ${newLives.length} lives');

      if (newLives.isEmpty) return;

      setState(() {
        lives = newLives;
      });

      if (_ytController == null) {
        _startVideo(0);
      }
    });

    _liveService.demarrer(interval: const Duration(seconds: 10));
  }

  // ------------------------------------------------------------
  // CHARGER UNE VIDÉO
  // ------------------------------------------------------------

  Future<void> _startVideo(int index) async {
    if (index < 0 || index >= lives.length) {
      // print('⚠️ Index invalide : $index');
      return;
    }

    final String? videoId = lives[index]['provider_live_input_id']?.toString();

    if (videoId == null || videoId.isEmpty) {
      //print('⚠️ Pas d\'ID vidéo');
      return;
    }

    // print('🎬 Chargement YouTube ID : $videoId');

    // ✅ Dispose l'ancien
    _ytController?.dispose();

    // ✅ Créer le nouveau
    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: true,
        hideControls: true, // 🎯 Cache les contrôles
        disableDragSeek: true, // 🎯 Empêche le seek
        enableCaption: false,
        hideThumbnail: false, //true
        forceHD: false,
        useHybridComposition: true, //true // 🎯 Important pour Huawei
      ),
    );

    controller.addListener(() {
      if (controller.value.hasError) {
        print('❌ Erreur YouTube : ${controller.value.errorCode}');
      }
    });

    setState(() {
      _ytController = controller;
      _currentIndex = index;
    });
  }

  // ------------------------------------------------------------
  // CHANGEMENT DE PAGE
  // ------------------------------------------------------------

  void _onPageChanged(int index) {
    if (index == _currentIndex) return;

    // print('📄 Changement de page : $index');

    setState(() {
      _currentIndex = index;
      commente = false;
    });

    _startVideo(index);
  }

  // ------------------------------------------------------------
  // FERMER LE COMMENTAIRE
  // ------------------------------------------------------------

  void _fermerCommentaire() {
    _focusNode.unfocus();
    setState(() => commente = false);
  }

  // ------------------------------------------------------------
  // DÉTECTER FERMETURE CLAVIER
  // ------------------------------------------------------------

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    final bottomInset = View.of(context).viewInsets.bottom;

    if (_lastBottomInset > 0 && bottomInset == 0 && commente) {
      if (mounted) setState(() => commente = false);
    }

    _lastBottomInset = bottomInset;
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (lives.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Chargement des lives...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: lives.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) => _buildPage(index),
      ),
    );
  }

  // ------------------------------------------------------------
  // PAGE
  // ------------------------------------------------------------

  Widget _buildPage(int index) {
    final isCurrentPage = index == _currentIndex;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black),

        if (isCurrentPage && _ytController != null)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final autoRatio = constraints.maxWidth / constraints.maxHeight;

                return YoutubePlayer(
                  controller: _ytController!,
                  showVideoProgressIndicator: false,
                  aspectRatio: autoRatio,
                );
              },
            ),
          ),

        // ✅ Appeler avec l'index
        if (isCurrentPage) actionLive(index),
      ],
    );
  }

  // ------------------------------------------------------------
  // OVERLAY PERSONNALISÉ
  // ------------------------------------------------------------

  Widget actionLive(int index) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ==========================================
          // EN-TÊTE
          // ==========================================
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (commente) {
                    _fermerCommentaire();
                    return;
                  }
                  context.pop();
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // ✅ Valeur dynamique
                      lives[index]['title']?.toString() ?? 'Live',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lives[index]['description']?.toString() ?? 'Description',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              lives[index]['status'] == 'live'
                  // ✅ Badge LIVE (const OK car aucune valeur dynamique)
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 10),
                          SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 10),
                          SizedBox(width: 6),
                          Text(
                            'DIFUSION',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),

          const Expanded(child: SizedBox()),

          // ==========================================
          // COMMENTAIRES
          // ==========================================
          /* */
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tcontroller.dispose();
    _focusNode.dispose();

    print('🗑️ Dispose LivePage');

    _pageController.dispose();
    _ytController?.dispose();

    _streamSubscription?.cancel();
    _liveService.arreter();

    super.dispose();
  }
}
