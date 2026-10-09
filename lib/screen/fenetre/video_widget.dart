import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoCard extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String description;
  final bool autoPlay;
  final bool is_free;
  final String price;

  const VideoCard({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.description,
    required this.is_free,
    required this.price,
    this.autoPlay = false,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  VideoPlayerController? _controller;

  Timer? _loadingTimer;

  bool _isLoading = false;
  bool _hasError = false;
  bool _showControls = true;

  int _requestId = 0;

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    // On démarre le chargement après le premier affichage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startVideo();
      }
    });
  }

  // ------------------------------------------------------------
  // CHARGER LA VIDEO
  // ------------------------------------------------------------

  Future<void> _startVideo() async {
    final int request = ++_requestId;

    // Annuler l'ancien timer
    _loadingTimer?.cancel();
    _loadingTimer = null;

    // Arrêter et supprimer l'ancien controller
    final oldController = _controller;
    _controller = null;

    if (oldController != null) {
      try {
        await oldController.dispose();
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    VideoPlayerController? newController;

    try {
      // ----------------------------------------------------------
      // VERIFICATION URL
      // ----------------------------------------------------------

      final uri = Uri.tryParse(widget.videoUrl);

      if (uri == null ||
          !uri.hasScheme ||
          (uri.scheme != 'http' && uri.scheme != 'https')) {
        throw Exception('URL vidéo invalide');
      }

      debugPrint('VIDEO URL : ${widget.videoUrl}');

      // ----------------------------------------------------------
      // CREATION CONTROLLER
      // ----------------------------------------------------------

      newController = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: {
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'FlutterApp/1.0',
        },
      );

      // ----------------------------------------------------------
      // TIMEOUT
      // ----------------------------------------------------------

      await newController.initialize().timeout(const Duration(seconds: 8));

      // ----------------------------------------------------------
      // VERIFICATIONS
      // ----------------------------------------------------------

      if (!mounted || request != _requestId) {
        try {
          await newController.dispose();
        } catch (_) {}

        return;
      }

      if (!newController.value.isInitialized || newController.value.hasError) {
        throw Exception('Impossible d\'initialiser la vidéo');
      }

      // ----------------------------------------------------------
      // CONTROLLER VALIDE
      // ----------------------------------------------------------

      _controller = newController;
      newController = null;

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = false;
      });

      // ----------------------------------------------------------
      // AUTOPLAY
      // ----------------------------------------------------------

      if (widget.autoPlay && mounted) {
        try {
          await _controller?.play();
        } catch (e) {
          debugPrint('Erreur autoplay : $e');
        }
      }
    } on TimeoutException {
      debugPrint('VIDEO TIMEOUT');

      if (newController != null) {
        try {
          await newController.dispose();
        } catch (_) {}

        newController = null;
      }

      if (!mounted || request != _requestId) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    } catch (e) {
      debugPrint('ERREUR VIDEO : $e');

      if (newController != null) {
        try {
          await newController.dispose();
        } catch (_) {}

        newController = null;
      }

      if (!mounted || request != _requestId) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // ------------------------------------------------------------
  // RETRY
  // ------------------------------------------------------------

  Future<void> _retry() async {
    if (_isLoading) return;

    await _startVideo();
  }

  // ------------------------------------------------------------
  // PLAY / PAUSE
  // ------------------------------------------------------------

  Future<void> _playPause() async {
    final controller = _controller;

    if (controller == null) return;

    if (!controller.value.isInitialized) return;

    if (controller.value.hasError) return;

    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        await controller.play();
      }
    } catch (e) {
      debugPrint('Erreur play/pause : $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  // ------------------------------------------------------------
  // RECULER
  // ------------------------------------------------------------

  Future<void> _rewind() async {
    final controller = _controller;

    if (controller == null) return;

    if (!controller.value.isInitialized) return;

    try {
      final position = controller.value.position;

      Duration newPosition = position - const Duration(seconds: 10);

      if (newPosition < Duration.zero) {
        newPosition = Duration.zero;
      }

      await controller.seekTo(newPosition);
    } catch (e) {
      debugPrint('Erreur rewind : $e');
    }
  }

  // ------------------------------------------------------------
  // AVANCER
  // ------------------------------------------------------------

  Future<void> _forward() async {
    final controller = _controller;

    if (controller == null) return;

    if (!controller.value.isInitialized) return;

    try {
      final position = controller.value.position;
      final duration = controller.value.duration;

      Duration newPosition = position + const Duration(seconds: 10);

      if (newPosition > duration) {
        newPosition = duration;
      }

      await controller.seekTo(newPosition);
    } catch (e) {
      debugPrint('Erreur forward : $e');
    }
  }

  // ------------------------------------------------------------
  // FORMAT TEMPS
  // ------------------------------------------------------------

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    String two(int number) {
      return number.toString().padLeft(2, '0');
    }

    if (hours > 0) {
      return '${two(hours)}:${two(minutes)}:${two(seconds)}';
    }

    return '${two(minutes)}:${two(seconds)}';
  }

  // ------------------------------------------------------------
  // ECRAN DE CHARGEMENT
  // ------------------------------------------------------------

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 35,
              height: 35,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 15),

            Text(
              'Chargement de la vidéo...',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ECRAN ERREUR
  // ------------------------------------------------------------

  Widget _buildError() {
    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Colors.white70, size: 50),

              const SizedBox(height: 12),

              const Text(
                'Vidéo indisponible',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Vérifiez votre connexion Internet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),

              const SizedBox(height: 15),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // VIDEO
  // ------------------------------------------------------------

  Widget _buildVideo() {
    final controller = _controller;

    if (controller == null) {
      return _buildError();
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,

      builder: (context, value, child) {
        // --------------------------------------------------------
        // ERREUR
        // --------------------------------------------------------

        if (value.hasError) {
          return _buildError();
        }

        // --------------------------------------------------------
        // PAS INITIALISE
        // --------------------------------------------------------

        if (!value.isInitialized) {
          return _buildLoading();
        }

        // --------------------------------------------------------
        // ASPECT RATIO
        // --------------------------------------------------------

        double aspectRatio = value.aspectRatio;

        if (aspectRatio <= 0 || aspectRatio.isNaN || aspectRatio.isInfinite) {
          aspectRatio = 16 / 9;
        }

        // --------------------------------------------------------
        // VIDEO
        // --------------------------------------------------------

        return GestureDetector(
          onTap: () {
            if (!mounted) return;

            setState(() {
              _showControls = !_showControls;
            });
          },

          child: AspectRatio(
            aspectRatio: aspectRatio,

            child: Stack(
              fit: StackFit.expand,

              children: [
                // ------------------------------------------------
                // VIDEO
                // ------------------------------------------------

                VideoPlayer(controller),

                // ------------------------------------------------
                // CONTROLES
                // ------------------------------------------------
                if (_showControls)
                  Container(
                    color: Colors.black26,

                    child: Column(
                      children: [
                        // ========================================
                        // TITRE
                        // ========================================

                        Padding(
                          padding: const EdgeInsets.all(8),

                          child: Column(
                            children: [
                              Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 1),

                              Text(
                                widget.description,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ========================================
                        // BOUTONS CENTRAUX
                        // ========================================
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              IconButton(
                                onPressed: _rewind,

                                icon: const Icon(
                                  Icons.replay_10,
                                  color: Colors.white,
                                  size: 35,
                                ),
                              ),

                              const SizedBox(width: 20),
                              if (widget.is_free)
                                IconButton(
                                  onPressed: _playPause,

                                  icon: Icon(
                                    value.isPlaying
                                        ? Icons.pause_circle
                                        : Icons.play_circle,

                                    color: Colors.white,
                                    size: 55,
                                  ),
                                )
                              else
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    child: Text(
                                      '${widget.price} FCFA',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(width: 20),

                              IconButton(
                                onPressed: _forward,

                                icon: const Icon(
                                  Icons.forward_10,
                                  color: Colors.white,
                                  size: 35,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ========================================
                        // TEMPS + PROGRESSION
                        // ========================================
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 8),

                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,

                                children: [
                                  Text(
                                    _formatDuration(value.position),

                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),

                                  Text(
                                    _formatDuration(value.duration),

                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),

                              VideoProgressIndicator(
                                controller,

                                allowScrubbing: true,

                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Card(
      //margin: const EdgeInsets.all(10),
      elevation: 3,

      clipBehavior: Clip.antiAlias,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),

        child: _hasError
            ? _buildError()
            : _isLoading
            ? _buildLoading()
            : _buildVideo(),
      ),
    );
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void deactivate() {
    // On ne détruit pas le controller ici.
    // Flutter peut appeler deactivate() temporairement.
    super.deactivate();
  }

  @override
  void didUpdateWidget(covariant VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si l'URL change, recharger la vidéo.
    if (oldWidget.videoUrl != widget.videoUrl) {
      _startVideo();
    }
  }

  @override
  void dispose() {
    // Invalider toutes les anciennes requêtes.
    _requestId++;

    // Annuler les timers.
    _loadingTimer?.cancel();
    _loadingTimer = null;

    // Récupérer le controller.
    final controller = _controller;
    _controller = null;

    // Libérer la vidéo.
    if (controller != null) {
      controller.dispose();
    }

    super.dispose();
  }
}
