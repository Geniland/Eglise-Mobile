import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:yafintech/core/theme/app_color.dart';
import 'package:yafintech/services/auth_service.dart';
import 'package:yafintech/services/reload_service.dart';
import 'package:yafintech/services/secure_storage.dart';

// ============================================================
// PAGE DE CHAT COMPLÈTE
// ============================================================

class ChatPage extends StatefulWidget {
  final int id;
  const ChatPage({super.key, required this.id});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Map<String, dynamic>? msgData;
  late final msgId _msgidservice = msgId(widget.id);
  StreamSubscription? _streamSubscription;

  // ✅ Données hardcodées

  final bool isOnline = false; // Remplacez par la logique réelle pour vérifier si le contact est en ligne

  bool _hasText = false;
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  String? _filePath;
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;

  List<dynamic> _messages = [];

  bool _isDisposed = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });

    _recordSub = _recorder.onStateChanged().listen(
      (state) {
        if (mounted && !_isDisposed) {
          setState(() => _recordState = state);
        }
      },
      onError: (error) {
        debugPrint('❌ Erreur recorder state : $error');
      },
    );

    _streamSubscription = _msgidservice.msidStream.listen(
      (data) {
        if (!mounted || _isDisposed) return;

        //  Extraire les nouvelles données
        Map<String, dynamic>? newMsgData;
        List<dynamic> newMessages;

        if (data == null) {
          newMsgData = null;
          newMessages = [];
        } else {
          if (data is List) {
            newMsgData = {'messages': data};
          } else if (data is Map<String, dynamic>) {
            newMsgData = data;
          } else {
            newMsgData = {'messages': []};
          }
          final raw = newMsgData['messages'];
          newMessages = (raw is List) ? List<dynamic>.from(raw) : <dynamic>[];
        }

        // Vérifier si les données ont réellement changé
        if (_hasMessagesChanged(newMessages)) {
          setState(() {
            msgData = newMsgData;
            _messages = newMessages;
            print('🏈 _messages.length = ${_messages.length}');
          });

          if (_messages.isNotEmpty) {
            _scrollToBottom();
          }
        } else {
          print('✅ Aucun changement, pas de rebuild');
        }
      },
      onError: (error) {
        debugPrint('❌ Erreur messages : $error');
      },
      cancelOnError: false,
    );

    _msgidservice.demarrer(interval: const Duration(seconds: 5));
  }

  // ============================================================
  // VÉRIFIER SI LES MESSAGES ONT CHANGÉ (anti-flicker)
  // ============================================================

  bool _hasMessagesChanged(List<dynamic> newMessages) {
    if (newMessages.length != _messages.length) {
      return true;
    }

    // ✅ Comparer les ID (ou contenu + date + lu)
    for (int i = 0; i < newMessages.length; i++) {
      final oldMsg = _messages[i];
      final newMsg = newMessages[i];

      if (oldMsg is! Map || newMsg is! Map) return true;

      final oldId = oldMsg['id'];
      final newId = newMsg['id'];

      if (oldId != null && newId != null) {
        if (oldId != newId) return true;
        if (oldMsg['lu'] != newMsg['lu']) return true;
      } else {
        // Fallback : comparer contenu + created_at + lu
        if (oldMsg['contenu'] != newMsg['contenu'] ||
            oldMsg['created_at'] != newMsg['created_at'] ||
            oldMsg['lu'] != newMsg['lu']) {
          return true;
        }
      }
    }

    return false; // Aucun changement
  }

  // ============================================================
  // FORMAT HEURE
  // ============================================================

  String _formatHeure(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';

    try {
      final date = DateTime.parse(dateStr).toLocal();
      final h = date.hour.toString().padLeft(2, '0');
      final m = date.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (e) {
      debugPrint('❌ Erreur parsing date : $e');
      return '';
    }
  }

  // ============================================================
  // EXTRACTION DU MESSAGE ET DU QR CODE
  // ============================================================

  String _extraireTexteMessage(String contenu) {
    final indexData = contenu.indexOf('---QR_CODE_DATA---');
    if (indexData == -1) return contenu;

    return contenu.substring(0, indexData).trim();
  }

  String? _extraireQrCodeData(String contenu) {
    final start = contenu.indexOf('---QR_CODE_DATA---');
    final end = contenu.indexOf('---QR_CODE_IMAGE---');
    if (start == -1 || end == -1) return null;

    return contenu.substring(start + 18, end).trim();
  }

  String? _extraireQrCodeImage(String contenu) {
    final start = contenu.indexOf('---QR_CODE_IMAGE---');
    if (start == -1) return null;

    final base64Part = contenu.substring(start + 20).trim();
    return base64Part.isNotEmpty ? base64Part : null;
  }

  Uint8List? _decoderQrCodeImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;

    try {
      String cleaned = base64String;
      if (cleaned.contains(',')) {
        cleaned = cleaned.split(',').last;
      }
      saveQRCodeToFile(base64Decode(cleaned.trim()));
      return base64Decode(cleaned.trim());
    } catch (e) {
      debugPrint('❌ Erreur décodage base64 : $e');
      return null;
    }
  }

  void saveQRCodeToFile(Uint8List qrBytes) async {
    final svqr = await SecureStorageService.getQR();
    if (svqr == null || svqr.isEmpty) {
      await SecureStorageService.saveQR(qrCode: base64Encode(qrBytes));
      print('✅ QR Code sauvegardé dans le stockage sécurisé');
    } else {
      print('ℹ️ QR Code déjà présent dans le stockage sécurisé');
    }
  }
  // ============================================================
  // ENVOYER UN MESSAGE
  // ============================================================

  void _envoyerMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();

    setState(() {
      _messages.add({
        'id': 'local_${now.millisecondsSinceEpoch}', // ✅ ID unique local
        'contenu': text,
        'created_at': now.toString(),
        'is_mine': true,
        'lu': false,
      });
    });

    _envoyerMessageAPI(text);

    _controller.clear();
    _focusNode.requestFocus();

    _scrollToBottom();
  }

  Future<void> _envoyerMessageAPI(String text) async {
    try {
      await sendMsg(msgData?['contact']?['id'], text);
    } catch (e) {
      debugPrint('❌ Erreur envoi message : $e');
      if (!mounted || _isDisposed) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'envoyer le message'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      });
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.couleur4,
                  child: Text(
                    msgData?['contact']?['initiales']
                            ?.toString()
                            .toUpperCase() ??
                        '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msgData?['contact']?['name']?.toString() ?? 'Contact',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  /*
                  Text(
                    isOnline ? 'En ligne' : 'Hors ligne',
                    style: TextStyle(
                      color: isOnline ? Colors.green : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),*/
                ],
              ),
            ),
          ],
        ),
        /* actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.call, color: Color(0xFF6C63FF)),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.black),
          ),
        ], */
      ),
      body: Column(
        children: [
          // =========================
          // LISTE DES MESSAGES
          // =========================
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Aucun message'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];

                      // ✅ CLÉ UNIQUE pour éviter le flicker
                      final String key = msg['id']?.toString() ?? 'msg_$index';

                      return _buildChatBubble(
                        key: ValueKey(key),
                        message: msg['contenu']?.toString() ?? '',
                        time: _formatHeure(msg['created_at']?.toString()),
                        isMe: msg['is_mine'] ?? false,
                        isRead: msg['lu'] ?? false,
                        index: index,
                      );
                    },
                  ),
          ),

          // =========================
          // ZONE DE SAISIE
          // =========================
          _buildInput(),
        ],
      ),
    );
  }

  // ============================================================
  // BULLE DE MESSAGE (avec QR Code)
  // ============================================================

  Widget _buildChatBubble({
    Key? key,
    required String message,
    required String time,
    required bool isMe,
    required bool isRead,
    required int index,
  }) {
    // ✅ Extraire les 3 parties du message
    final texteMessage = _extraireTexteMessage(message);
    final qrData = _extraireQrCodeData(message);
    final qrImageBase64 = _extraireQrCodeImage(message);
    final qrBytes = _decoderQrCodeImage(qrImageBase64);

    final hasQrCode = qrBytes != null;

    return Padding(
      key: key, // ✅ Passer la clé au widget racine
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ✅ Avatar (si pas moi)
          if (!isMe) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[400],
              child: Text(
                msgData?['contact']?['initiales']?.toString().toUpperCase() ??
                    '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // BULLE DE MESSAGE
          Flexible(
            child: GestureDetector(
              onLongPress: () {}, //_afficherOptionsMessage(index),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.couleur4
                      : Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: isMe
                        ? const Radius.circular(18)
                        : const Radius.circular(4),
                    bottomRight: isMe
                        ? const Radius.circular(4)
                        : const Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom (si pas moi)
                    if (!isMe) ...[
                      Text(
                        msgData?['contact']?['name']?.toString() ?? 'Contact',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // ✅ TEXTE DU MESSAGE
                    if (texteMessage.isNotEmpty)
                      Text(
                        texteMessage,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),

                    // ✅ IMAGE DU QR CODE
                    if (hasQrCode) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _afficherQrCodePleinEcran(qrBytes),
                              child: Image.memory(
                                qrBytes,
                                width: 200,
                                height: 200,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 4),

                    // ✅ Heure + lu
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            color: isMe
                                ? Colors.white.withOpacity(0.7)
                                : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isRead ? Icons.done_all : Icons.done,
                            color: isRead
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white.withOpacity(0.7),
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _afficherQrCodePleinEcran(Uint8List qrBytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mon QR Code',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Image.memory(
                qrBytes,
                width: 280,
                height: 280,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Fermer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ZONE DE SAISIE
  // ============================================================

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Écrire un message...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 6),

            GestureDetector(
              onTap: _hasText ? _envoyerMessage : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _hasText
                      ? AppColors.couleur4
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: _hasText
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OPTIONS AU LONG PRESS
  // ============================================================

  void _afficherOptionsMessage(int index) {
    if (index < 0 || index >= _messages.length) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copier'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Message copié')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Répondre'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                if (index >= 0 && index < _messages.length) {
                  setState(() => _messages.removeAt(index));
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ENREGISTREMENT AUDIO (non utilisé)
  // ============================================================

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        debugPrint('❌ Permission refusée');
        return;
      }

      final Directory dir = await getApplicationDocumentsDirectory();
      final String path =
          'yaf/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      );

      await _recorder.start(config, path: path);

      if (!mounted) return;

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _filePath = path;
      });

      debugPrint('🎙️ Enregistrement démarré : $path');
    } catch (e) {
      debugPrint('❌ Erreur start : $e');
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _recorder.pause();
      if (!mounted) return;
      setState(() => _isPaused = true);
    } catch (e) {
      debugPrint('❌ Erreur pause : $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recorder.resume();
      if (!mounted) return;
      setState(() => _isPaused = false);
    } catch (e) {
      debugPrint('❌ Erreur resume : $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();

      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _isPaused = false;
        _filePath = path;
      });

      debugPrint('✅ Enregistrement sauvegardé : $path');
    } catch (e) {
      debugPrint('❌ Erreur stop : $e');
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _isDisposed = true;

    _scrollController.dispose();
    _controller.dispose();
    _focusNode.dispose();

    _recordSub?.cancel();
    _recorder.dispose();

    _streamSubscription?.cancel();
    _msgidservice.arreter();

    super.dispose();
  }
}
