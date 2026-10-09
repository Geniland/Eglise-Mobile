import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:yafintech/core/theme/app_color.dart';
import 'package:yafintech/services/auth_service.dart';
import 'package:yafintech/services/reload_service.dart';

// ============================================================
// PAGE DE CHAT IA
// ============================================================

class ChatIAPage extends StatefulWidget {
  const ChatIAPage({super.key});

  @override
  State<ChatIAPage> createState() => _ChatIAPageState();
}

class _ChatIAPageState extends State<ChatIAPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  //  Service des discussions
  Map<String, dynamic>? disIAData;
  late final convIA _disiaservice = convIA();
  StreamSubscription? _streamSubscription;

  Map<String, dynamic>? chatIAData;
  int chatid = 0;
  chatIA? _chatiaservice;
  StreamSubscription? _streamChatia;

  bool selcdisc = false;

  bool _shouldAutoScroll = true;

  // ✅ Flags pour la nouvelle discussion
  bool newDisc = true;
  bool clicNewdisc = false;

  // ✅ Flag pour l'animation "réfléchit"
  bool _isAIThinking = false;

  bool _hasText = false;

  List<dynamic> _discutions = [];
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

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final isAtBottom =
            _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50;
        _shouldAutoScroll = isAtBottom;
      }
    });

    _streamSubscription = _disiaservice.msiaidStream.listen(
      (data) {
        if (!mounted || _isDisposed) return;

        if (data != null) {
          final discussions = data is Map ? (data['data'] ?? []) : (data ?? []);

          setState(() {
            // ✅ NE PAS écraser newDisc si l'utilisateur a cliqué "Nouvelle discussion"
            if (!clicNewdisc) {
              newDisc = discussions.isEmpty;
            }
            _discutions = discussions is List ? discussions : [];
          });

          print('💫 ${_discutions.length} discussions');

          // - Pas déjà sélectionnée
          // - Pas en mode "nouvelle discussion"
          // - La liste n'est pas vide
          if (!selcdisc && !clicNewdisc && _discutions.isNotEmpty) {
            final firstId = _discutions[0]?['id'];
            if (firstId != null && firstId is int && firstId > 0 && !newDisc) {
              _chargerConversation(firstId);
            }
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Erreur discussions : $error');
      },
      cancelOnError: false,
    );

    _disiaservice.demarrer(interval: const Duration(seconds: 10));
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
  // CHARGER UNE CONVERSATION
  // ============================================================

  void _chargerConversation(int id) async {
    print('🔄 Chargement conversation : $id');

    setState(() {
      chatid = id;
      newDisc = false;
      clicNewdisc = false;
    });

    _streamChatia?.cancel();
    _streamChatia = null;
    _chatiaservice?.arreter();
    _chatiaservice = null;

    // ✅ 3. Créer le nouveau service
    _chatiaservice = chatIA(id);

    _streamChatia = _chatiaservice!.chatiaStream.listen(
      (data) {
        if (!mounted || _isDisposed) return;

        if (data != null) {
          try {
            final messagesList = data is Map
                ? (data['messages'] ?? [])
                : (data ?? []);

            setState(() {
              _messages = messagesList is List
                  ? List<dynamic>.from(messagesList)
                  : [];
            });

            print('💫 ${_messages.length} messages chargés');

            if (_shouldAutoScroll) {
              _scrollToBottom();
            }
          } catch (e) {
            debugPrint('❌ Erreur traitement messages : $e');
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Erreur chat : $error');
      },
      cancelOnError: false,
    );

    _chatiaservice!.demarrer(interval: const Duration(seconds: 10));
  }

  // ============================================================
  // ENVOYER UN MESSAGE
  // ============================================================

  void _envoyerMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final bool isNewDiscussion = newDisc;

    if (isNewDiscussion) {
      final now = DateTime.now();

      setState(() {
        _messages.clear();
        _messages.add({
          "id": 0,
          "assistant_conversation_id": chatid,
          "expediteur": "utilisateur",
          "contenu": text,
          "created_at": now.toIso8601String(),
          "updated_at": now.toIso8601String(),
        });

        _shouldAutoScroll = true;
        _isAIThinking = true;

        newDisc = false;
        clicNewdisc = false;
      });

      _envoyerMessageAPI(text, isNewDiscussion);

      _controller.clear();
      _focusNode.requestFocus();
    } else {
      //  Vérifier qu'une conversation est chargée
      if (chatid <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sélectionnez une conversation d\'abord'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final now = DateTime.now();

      // ✅ Ajouter dans _messages
      setState(() {
        _messages.add({
          "id": 0,
          "assistant_conversation_id": chatid,
          "expediteur": "utilisateur",
          "contenu": text,
          "created_at": now.toIso8601String(),
          "updated_at": now.toIso8601String(),
        });

        _shouldAutoScroll = true;
        _isAIThinking = true;
      });

      _envoyerMessageAPI(text, isNewDiscussion);

      _controller.clear();
      _focusNode.requestFocus();
    }

    // ✅ Scroll après envoi
    _scrollToBottom();
  }

  // ============================================================
  // ENVOYER MESSAGE À L'API
  // ============================================================

  Future<void> _envoyerMessageAPI(String text, bool isNewDiscussion) async {
    if (isNewDiscussion) {
      print('💫💫 nouvelle discussion');
      try {
        final response = await newIADisc(text);
        print('📥 Réponse newIADisc : $response');

        if (!mounted || _isDisposed) return;

        // ✅ 3. Essayer d'extraire l'ID
        int? newConvId;

        if (response is Map) {
          if (response['id'] is int) {
            newConvId = response['id'];
            sendIAMsg(response['id'], text);
          } else if (response['data'] is Map && response['data']['id'] is int) {
            newConvId = response['data']['id'];
          } else if (response['conversation_id'] is int) {
            newConvId = response['conversation_id'];
          } else if (response['conversation'] is Map &&
              response['conversation']['id'] is int) {
            newConvId = response['conversation']['id'];
          }
        }

        setState(() {
          _isAIThinking = false;
        });

        if (newConvId != null && newConvId > 0) {
          print('✅ Nouvelle conversation créée avec ID : $newConvId');

          setState(() {
            selcdisc = true;
            clicNewdisc = false;
            newDisc = false;
          });

          _chargerConversation(newConvId);
        } else {
          print('⚠️ Impossible d\'extraire l\'ID de la réponse');

          setState(() {
            newDisc = false;
            selcdisc = false;
            clicNewdisc = false;
          });
        }
      } catch (e) {
        debugPrint('❌ Erreur envoi message : $e');
        if (!mounted || _isDisposed) return;
        setState(() {
          _isAIThinking = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'envoyer le message'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      print('💫 discussion existante');
      try {
        await sendIAMsg(chatid, text);

        if (mounted && !_isDisposed) {
          setState(() {
            _isAIThinking = false;
          });
        }
      } catch (e) {
        debugPrint('❌ Erreur envoi message IA : $e');
        if (!mounted || _isDisposed) return;

        setState(() {
          _isAIThinking = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'envoyer le message'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ============================================================
  // SCROLL TO BOTTOM
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Assistance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Column(
                children: [
                  const Text(
                    'Discussion',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Center(
                      child: FloatingActionButton.extended(
                        backgroundColor: AppColors.couleur2,
                        onPressed: () {
                          Navigator.pop(context);

                          // ✅ 1. Arrêter l'ancien service de chat
                          _streamChatia?.cancel();
                          _streamChatia = null;
                          _chatiaservice?.arreter();
                          _chatiaservice = null;

                          setState(() {
                            newDisc = true;
                            selcdisc = true;
                            clicNewdisc = true;
                            chatid = 0;
                            _messages.clear();
                            _isAIThinking = false;
                            _controller.clear();
                            _focusNode.requestFocus();
                          });

                          print('🆕 Nouvelle discussion créée (mode)');
                        },
                        label: const Text(
                          'Nouvelle discussion',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_discutions.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(
                  child: Text(
                    'Aucune discussion',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            else
              for (var msg in _discutions)
                _builDiscution(
                  id: msg?['id'] ?? 0,
                  titre: msg?['titre'] ?? 'Sans titre',
                ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (newDisc)
            Expanded(
              child: Center(
                child: Text(
                  'Nouvelle discussion',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),

          // =========================
          // LISTE DES MESSAGES
          // =========================
          if (!newDisc)
            Expanded(
              child: (_messages.isEmpty && !_isAIThinking)
                  ? const Center(child: Text('Aucun message'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      // +1 si l'IA réfléchit
                      itemCount: _messages.length + (_isAIThinking ? 1 : 0),
                      itemBuilder: (context, index) {
                        //  Dernier élément = animation
                        if (_isAIThinking && index == _messages.length) {
                          return const AIThinkingBubble();
                        }

                        final msg = _messages[index];

                        return _buildChatBubble(
                          message: msg['contenu']?.toString() ?? '',
                          created_at: _formatHeure(
                            msg['created_at']?.toString(),
                          ),
                          expediteur:
                              msg['expediteur']?.toString() ?? 'assistant',
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
  // ITEM DE DISCUSSION (DRAWER)
  // ============================================================

  Widget _builDiscution({required int id, required String titre}) {
    return InkWell(
      onTap: () {
        selcdisc = true;
        clicNewdisc = false;
        newDisc = false;
        _shouldAutoScroll = true;
        _chargerConversation(id);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                titre,
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BULLE DE MESSAGE
  // ============================================================

  Widget _buildChatBubble({
    required String message,
    required String created_at,
    required String expediteur,
    required int index,
  }) {
    final isMe = expediteur == "utilisateur";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: GestureDetector(
              onLongPress: () {}, //_afficherOptionsMessage(index),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isMe
                      ? MediaQuery.of(context).size.width * 0.85
                      : MediaQuery.of(context).size.width * 1,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color.fromARGB(255, 49, 48, 60)
                      : Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        color: isMe
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      created_at,
                      style: TextStyle(
                        color: isMe
                            ? Colors.white.withOpacity(0.7)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _isDisposed = true;

    _scrollController.dispose();
    _controller.dispose();
    _focusNode.dispose();

    _streamSubscription?.cancel();
    _streamChatia?.cancel();

    _chatiaservice?.arreter();
    _disiaservice.arreter();

    super.dispose();
  }
}

// ============================================================
// WIDGET : Animation "L'assistant réfléchit..."
// ============================================================

class AIThinkingBubble extends StatefulWidget {
  const AIThinkingBubble({super.key});

  @override
  State<AIThinkingBubble> createState() => _AIThinkingBubbleState();
}

class _AIThinkingBubbleState extends State<AIThinkingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ 3 points animés
                for (int i = 0; i < 3; i++)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final delay = i * 0.2;
                      final value = (_controller.value - delay) % 1.0;
                      final offset = value < 0.5
                          ? -6.0 * (value * 2)
                          : -6.0 * (1 - (value - 0.5) * 2);

                      return Container(
                        margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                        child: Transform.translate(
                          offset: Offset(0, offset),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[600],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
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
