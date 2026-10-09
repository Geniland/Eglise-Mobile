import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:yafintech/services/auth_service.dart';

class AudioCard extends StatefulWidget {
  final String audioUrl;
  final String title;
  final String description;
  final bool autoPlay;
  final bool is_free;
  final String price;

  const AudioCard({
    super.key,
    required this.audioUrl,
    required this.title,
    required this.description,
    required this.is_free,
    required this.price,
    this.autoPlay = false,
  });

  @override
  State<AudioCard> createState() => _AudioCardState();
}

class _AudioCardState extends State<AudioCard> {
  final AudioPlayer _player = AudioPlayer();

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _isLoading = false;
  bool _hasError = false;
  bool _isPlaying = false;

  double _volume = 1.0;

  int _loadId = 0;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<void>? _completeSubscription;
  StreamSubscription<String>? _errorSubscription;

  @override
  void initState() {
    super.initState();

    _initializePlayer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAudio();
      }
    });
  }

  // ============================================================
  // INITIALISATION DU PLAYER
  // ============================================================

  void _initializePlayer() {
    _positionSubscription = _player.onPositionChanged.listen((position) {
      if (!mounted) return;

      setState(() {
        _position = position;
      });
    });

    _durationSubscription = _player.onDurationChanged.listen((duration) {
      if (!mounted) return;

      setState(() {
        _duration = duration;
      });
    });

    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;

      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _completeSubscription = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;

      setState(() {
        _isPlaying = false;
        _position = _duration;
      });
    });

    _errorSubscription = _player.onLog.listen((message) {
      debugPrint('AUDIO LOG : $message');
    });
  }

  // ============================================================
  // CHARGEMENT AUDIO
  // ============================================================

  Future<void> _loadAudio() async {
    final int currentLoad = ++_loadId;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    try {
      // ============================================================
      // VERIFICATION URL
      // ============================================================

      final uri = Uri.tryParse(widget.audioUrl);

      if (uri == null ||
          !uri.hasScheme ||
          (uri.scheme != 'http' && uri.scheme != 'https')) {
        throw Exception('URL audio invalide');
      }

      debugPrint('Chargement audio : ${widget.audioUrl}');

      // ============================================================
      // VERIFICATION INTERNET
      // ============================================================

      final hasConnection = await checkconnecte();

      if (!mounted || currentLoad != _loadId) {
        return;
      }

      // ============================================================
      // PAS INTERNET
      // ============================================================

      if (!hasConnection) {
        debugPrint('Pas de connexion Internet');

        setState(() {
          _isLoading = false;
          _hasError = true;
        });

        return;
      }

      // ============================================================
      // ARRETER L'ANCIEN AUDIO
      // ============================================================

      await _player.stop();

      // ============================================================
      // VOLUME
      // ============================================================

      await _player.setVolume(_volume);

      // ============================================================
      // CHARGEMENT AUDIO
      // ============================================================

      await _player
          .setSourceUrl(widget.audioUrl)
          .timeout(const Duration(seconds: 8));

      // ============================================================
      // VERIFICATION
      // ============================================================

      if (!mounted || currentLoad != _loadId) {
        return;
      }

      setState(() {
        _isLoading = false;
        _hasError = false;
      });

      // ============================================================
      // AUTOPLAY
      // ============================================================

      if (widget.autoPlay && mounted) {
        try {
          await _player.resume();
        } catch (e) {
          debugPrint('Erreur autoplay audio : $e');
        }
      }
    } on TimeoutException {
      debugPrint('AUDIO TIMEOUT');

      if (!mounted || currentLoad != _loadId) {
        return;
      }

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    } catch (e) {
      debugPrint('ERREUR AUDIO : $e');

      if (!mounted || currentLoad != _loadId) {
        return;
      }

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // ============================================================
  // REESSAYER
  // ============================================================

  Future<void> _retry() async {
    if (_isLoading) return;

    await _loadAudio();
  }

  // ============================================================
  // PLAY / PAUSE
  // ============================================================

  Future<void> _playPause() async {
    if (_isLoading || _hasError) return;

    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.resume();
      }
    } catch (e) {
      debugPrint('Erreur play/pause : $e');

      if (!mounted) return;

      setState(() {
        _hasError = true;
      });
    }
  }

  // ============================================================
  // RECULER 10 SECONDES
  // ============================================================

  Future<void> _rewind() async {
    if (_isLoading || _hasError) return;

    try {
      Duration newPosition = _position - const Duration(seconds: 10);

      if (newPosition < Duration.zero) {
        newPosition = Duration.zero;
      }

      await _player.seek(newPosition);
    } catch (e) {
      debugPrint('Erreur rewind : $e');
    }
  }

  // ============================================================
  // AVANCER 10 SECONDES
  // ============================================================

  Future<void> _forward() async {
    if (_isLoading || _hasError) return;

    try {
      Duration newPosition = _position + const Duration(seconds: 10);

      if (newPosition > _duration) {
        newPosition = _duration;
      }

      await _player.seek(newPosition);
    } catch (e) {
      debugPrint('Erreur forward : $e');
    }
  }

  // ============================================================
  // CHANGER LE VOLUME
  // ============================================================

  Future<void> _changeVolume(double value) async {
    setState(() {
      _volume = value;
    });

    try {
      await _player.setVolume(value);
    } catch (e) {
      debugPrint('Erreur volume : $e');
    }
  }

  // ============================================================
  // FORMAT TEMPS
  // ============================================================

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    if (hours > 0) {
      return '${twoDigits(hours)}:'
          '${twoDigits(minutes)}:'
          '${twoDigits(seconds)}';
    }

    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      height: 230,
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
              'Chargement de l’audio...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERREUR
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      height: 230,
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
                'Audio indisponible',
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

  // ============================================================
  // AUDIO
  // ============================================================

  Widget _buildAudio() {
    return Container(
      width: double.infinity,
      height: 200,
      //color: Colors.black,
      decoration: BoxDecoration(
        //borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: NetworkImage(
            //'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&h=400&fit=crop',
            //'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800&h=400&fit=crop',
            //'https://images.unsplash.com/photo-1539375665275-f9de415ef9ac?w=800&h=400&fit=crop',
            'https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=800&h=400&fit=crop',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),

        child: Column(
          children: [
            // ==================================================
            // ICONE AUDIO
            // ==================================================

            const SizedBox(height: 8),

            // ==================================================
            // TITRE
            // ==================================================
            Row(
              children: [
                const Icon(Icons.headphones, color: Colors.white, size: 45),
                Column(
                  children: [
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    //const SizedBox(height: 4),

                    // ==================================================
                    // DESCRIPTION
                    // ==================================================
                    Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // ==================================================
            // CONTROLES
            // ==================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                // RECULER
                IconButton(
                  onPressed: _rewind,

                  icon: const Icon(
                    Icons.replay_10,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                const SizedBox(width: 15),

                // PLAY / PAUSE
                if (widget.is_free)
                  IconButton(
                    onPressed: _playPause,

                    icon: Icon(
                      _isPlaying ? Icons.pause_circle : Icons.play_circle,

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

                const SizedBox(width: 15),

                // AVANCER
                IconButton(
                  onPressed: _forward,

                  icon: const Icon(
                    Icons.forward_10,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                const SizedBox(width: 15),

                // VOLUME
                /* PopupMenuButton<double>(
                  tooltip: 'Volume',

                  icon: Icon(
                    _volume == 0
                        ? Icons.volume_off
                        : _volume < 0.5
                        ? Icons.volume_down
                        : Icons.volume_up,

                    color: Colors.white,
                  ),

                  itemBuilder: (context) {
                    return [
                      PopupMenuItem<double>(
                        enabled: false,

                        child: SizedBox(
                          width: 180,

                          child: StatefulBuilder(
                            builder: (context, setPopupState) {
                              return Slider(
                                min: 0,
                                max: 1,
                                value: _volume,

                                onChanged: (value) {
                                  setPopupState(() {
                                    _volume = value;
                                  });

                                  _changeVolume(value);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ];
                  },
                ), */
              ],
            ),
            // ==================================================
            // TEMPS
            // ==================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Text(
                  _formatDuration(_position),

                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),

                Text(
                  _formatDuration(_duration),

                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            // ==================================================
            // BARRE DE PROGRESSION
            // ==================================================
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),

              child: Slider(
                min: 0,

                max: _duration.inMilliseconds > 0
                    ? _duration.inMilliseconds.toDouble()
                    : 1,

                value: _position.inMilliseconds.toDouble().clamp(
                  0,
                  _duration.inMilliseconds > 0
                      ? _duration.inMilliseconds.toDouble()
                      : 1,
                ),

                onChanged: _duration.inMilliseconds <= 0
                    ? null
                    : (value) {
                        setState(() {
                          _position = Duration(milliseconds: value.toInt());
                        });
                      },

                onChangeEnd: (value) async {
                  try {
                    await _player.seek(Duration(milliseconds: value.toInt()));
                  } catch (e) {
                    debugPrint('Erreur déplacement audio : $e');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),

      elevation: 3,

      clipBehavior: Clip.antiAlias,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),

        child: _hasError
            ? _buildError()
            : _isLoading
            ? _buildLoading()
            : _buildAudio(),
      ),
    );
  }

  // ============================================================
  // URL MODIFIEE
  // ============================================================

  @override
  void didUpdateWidget(covariant AudioCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.audioUrl != widget.audioUrl) {
      _loadAudio();
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _loadId++;

    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _completeSubscription?.cancel();
    _errorSubscription?.cancel();

    _player.dispose();

    super.dispose();
  }
}
