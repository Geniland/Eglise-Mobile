import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yafintech/services/auth_service.dart';

class LiveServiceActive {
  Timer? _pollingTimer;
  final _liveController = StreamController<Map<String, dynamic>?>.broadcast();

  // ✅ Stream qui émet les données du live en cours (ou null)
  Stream<Map<String, dynamic>?> get liveStream => _liveController.stream;

  Map<String, dynamic>? _currentLive;
  Map<String, dynamic>? get currentLive => _currentLive;

  bool _isPolling = false;

  // ------------------------------------------------------------
  // DÉMARRER LE POLLING
  // ------------------------------------------------------------

  void demarrer({Duration interval = const Duration(seconds: 2)}) {
    if (_isPolling) return;
    _isPolling = true;

    debugPrint(
      '▶️ Démarrage du polling live (toutes les ${interval.inSeconds}s)',
    );

    // Premier appel immédiat
    _fetchActiveLive();

    // Puis appels réguliers
    _pollingTimer = Timer.periodic(interval, (_) => _fetchActiveLive());
  }

  // ------------------------------------------------------------
  // ARRÊTER LE POLLING
  // ------------------------------------------------------------

  void arreter() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    debugPrint('⏹️ Arrêt du polling live');
  }

  // ------------------------------------------------------------
  // APPEL API
  // ------------------------------------------------------------

  Future<void> _fetchActiveLive() async {
    try {
      //('$baseurl/api/live-streams/active');
      final tkn = await geToken();
      final response = await http
          .get(
            Uri.parse('$baseurl/api/live-streams/active'),
            headers: {
              'Authorization': 'Bearer $tkn',
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
          )
          .timeout(const Duration(seconds: 10));

      // ✅ 200 OK : un live est en cours
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Détecter un changement (nouveau live)
        final newLiveId = data['id'];
        final oldLiveId = _currentLive?['id'];

        _currentLive = data;

        if (newLiveId != oldLiveId) {
          debugPrint('🔴 Nouveau live détecté : ${data['title']}');
        }

        _liveController.add(data);
      }
      // ✅ 204 No Content (ou 404) : pas de live en cours
      else if (response.statusCode == 204 || response.statusCode == 404) {
        if (_currentLive != null) {
          debugPrint('⚫ Le live est terminé');
        }

        _currentLive = null;
        _liveController.add(null);
      }
      // ❌ Autre erreur
      else {
        debugPrint('❌ Erreur API : ${response.statusCode}');
        debugPrint('Body : ${response.body}');
      }
    } on TimeoutException {
      debugPrint('⏱️ Timeout lors du fetch du live');
    } catch (e) {
      debugPrint('❌ Exception : $e');
    }
  }

  // ------------------------------------------------------------
  // FORCER UN RAFRAÎCHISSEMENT
  // ------------------------------------------------------------

  Future<void> refresh() async {
    await _fetchActiveLive();
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  void dispose() {
    arreter();
    _liveController.close();
  }
}

class LiveService {
  Timer? _pollingTimer;
  final _liveController = StreamController<Map<String, dynamic>?>.broadcast();

  // ✅ Stream qui émet les données du live en cours (ou null)
  Stream<Map<String, dynamic>?> get liveStream => _liveController.stream;

  Map<String, dynamic>? _currentLive;
  Map<String, dynamic>? get currentLive => _currentLive;

  bool _isPolling = false;

  // ------------------------------------------------------------
  // DÉMARRER LE POLLING
  // ------------------------------------------------------------

  void demarrer({Duration interval = const Duration(seconds: 2)}) {
    if (_isPolling) return;
    _isPolling = true;

    debugPrint(
      '▶️ Démarrage du polling live (toutes les ${interval.inSeconds}s)',
    );

    // Premier appel immédiat
    _fetchLive();

    // Puis appels réguliers
    _pollingTimer = Timer.periodic(interval, (_) => _fetchLive());
  }

  // ------------------------------------------------------------
  // ARRÊTER LE POLLING
  // ------------------------------------------------------------

  void arreter() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    debugPrint('⏹️ Arrêt du polling live');
  }

  // ------------------------------------------------------------
  // APPEL API
  // ------------------------------------------------------------

  Future<void> _fetchLive() async {
    try {
      final tkn = await geToken();
      final response = await http
          .get(
            Uri.parse('$baseurl/api/live-streams'),
            headers: {
              'Authorization': 'Bearer $tkn',
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
          )
          .timeout(const Duration(seconds: 10));

      // ✅ 200 OK : un live est en cours
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Détecter un changement (nouveau live)
        final newLiveId = data['id'];
        final oldLiveId = _currentLive?['id'];

        _currentLive = data;

        if (newLiveId != oldLiveId) {
          debugPrint('🔴 Nouveau live détecté : ${data['title']}');
        }

        _liveController.add(data);
      }
      // ✅ 204 No Content (ou 404) : pas de live en cours
      else if (response.statusCode == 204 || response.statusCode == 404) {
        if (_currentLive != null) {
          debugPrint('⚫ Le live est terminé');
        }

        _currentLive = null;
        _liveController.add(null);
      }
      // ❌ Autre erreur
      else {
        debugPrint('❌ Erreur API : ${response.statusCode}');
        debugPrint('Body : ${response.body}');
      }
    } on TimeoutException {
      debugPrint('⏱️ Timeout lors du fetch du live');
    } catch (e) {
      debugPrint('❌ Exception : $e');
    }
  }

  // ------------------------------------------------------------
  // FORCER UN RAFRAÎCHISSEMENT
  // ------------------------------------------------------------

  Future<void> refresh() async {
    await _fetchLive();
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  void dispose() {
    arreter();
    _liveController.close();
  }
}

class getFormationService {
  Timer? _pollingTimer;
  final _formationController =
      StreamController<Map<String, dynamic>?>.broadcast();

  // ✅ Stream
  Stream<Map<String, dynamic>?> get formationStream =>
      _formationController.stream;

  Map<String, dynamic>? _currentFormation;
  Map<String, dynamic>? get currentFormation => _currentFormation;

  bool _isPolling = false;

  // ------------------------------------------------------------
  // DÉMARRER LE POLLING
  // ------------------------------------------------------------

  void demarrer({Duration interval = const Duration(seconds: 2)}) {
    if (_isPolling) return;
    _isPolling = true;

    debugPrint(
      '▶️ Démarrage du polling formation (toutes les ${interval.inSeconds}s)',
    );

    // Premier appel immédiat
    _fetchActiveFormation();

    // Puis appels réguliers
    _pollingTimer = Timer.periodic(interval, (_) => _fetchActiveFormation());
  }

  // ------------------------------------------------------------
  // ARRÊTER LE POLLING
  // ------------------------------------------------------------

  void arreter() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    debugPrint('⏹️ Arrêt du polling formation');
  }

  // ------------------------------------------------------------
  // APPEL API
  // ------------------------------------------------------------

  Future<void> _fetchActiveFormation() async {
    try {
      final tkn = await geToken();
      final response = await http
          .get(
            Uri.parse('$baseurl/api/formations'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $tkn',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final newFormationId = data['id'];
        final oldFormationId = _currentFormation?['id'];

        _currentFormation = data;

        if (newFormationId != oldFormationId) {
          debugPrint('🔴 nouveau formation : ${data['title']}');
        }

        _formationController.add(data);
      } else if (response.statusCode == 204 || response.statusCode == 404) {
        if (_currentFormation != null) {
          debugPrint('⚫ Formation indisponible');
        }

        _currentFormation = null;
        _formationController.add(null);
      }
      // ❌ Autre erreur
      else {
        debugPrint('❌ Erreur API : ${response.statusCode}');
        debugPrint('Body : ${response.body}');
      }
    } on TimeoutException {
      debugPrint('⏱️ Timeout lors du fetch du live');
    } catch (e) {
      debugPrint('❌ Exception : $e');
    }
  }

  // ------------------------------------------------------------
  // FORCER UN RAFRAÎCHISSEMENT
  // ------------------------------------------------------------

  Future<void> refresh() async {
    await _fetchActiveFormation();
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  void dispose() {
    arreter();
    _formationController.close();
  }
}

class getRessourceService {
  Timer? _pollingTimer;

  // ✅ Utiliser 'dynamic' pour accepter à la fois les Maps et les Lists
  final _ressourceController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get ressourceStream => _ressourceController.stream;

  dynamic _currentRessource;
  dynamic get currentRessource => _currentRessource;

  bool _isPolling = false;

  void demarrer({Duration interval = const Duration(seconds: 2)}) {
    if (_isPolling) return;
    _isPolling = true;

    debugPrint('▶️ Démarrage du polling (toutes les ${interval.inSeconds}s)');
    _fetchActiveRessource();
    _pollingTimer = Timer.periodic(interval, (_) => _fetchActiveRessource());
  }

  void arreter() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    debugPrint('⏹️ Arrêt du polling');
  }

  Future<void> _fetchActiveRessource() async {
    try {
      final tkn = await geToken();
      final response = await http
          .get(
            Uri.parse('$baseurl/api/resources'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $tkn',
            },
          )
          .timeout(const Duration(seconds: 10));

      // ✅ VÉRIFICATION CRUCIALE : Ne pas continuer si le contrôleur est fermé
      if (_ressourceController.isClosed) return;

      if (response.statusCode == 200) {
        // ✅ Ne pas forcer le typage en Map, accepter le dynamic
        final dynamic data = jsonDecode(response.body);
        _currentRessource = data;

        if (!_ressourceController.isClosed) {
          _ressourceController.add(data);
        }
      } else if (response.statusCode == 204 || response.statusCode == 404) {
        _currentRessource = null;
        if (!_ressourceController.isClosed) {
          _ressourceController.add(null);
        }
      } else {
        debugPrint('❌ Erreur API : ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('⏱️ Timeout lors du fetch');
    } catch (e) {
      debugPrint('❌ Exception : $e');
    }
  }

  Future<void> refresh() async => await _fetchActiveRessource();

  void dispose() {
    arreter();
    _ressourceController.close();
  }
}

class getMyRessourceService {
  Timer? _pollingTimer;

  // ✅ Utiliser 'dynamic' pour accepter à la fois les Maps et les Lists
  final _myressourceController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get ressourceStream => _myressourceController.stream;

  dynamic _currentMycessource;
  dynamic get currentmyressource => _currentMycessource;

  bool _isPolling = false;

  void demarrer({Duration interval = const Duration(seconds: 2)}) {
    if (_isPolling) return;
    _isPolling = true;

    debugPrint('▶️ Démarrage du polling (toutes les ${interval.inSeconds}s)');
    _fetchActiveRessource();
    _pollingTimer = Timer.periodic(interval, (_) => _fetchActiveRessource());
  }

  void arreter() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    debugPrint('⏹️ Arrêt du polling');
  }

  Future<void> _fetchActiveRessource() async {
    try {
      final tkn = await geToken();
      final response = await http
          .get(
            Uri.parse(
              '$baseurl/api/my-formations',
            ), // Assurez-vous que baseurl est défini
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $tkn',
            },
          )
          .timeout(const Duration(seconds: 10));

      // ✅ VÉRIFICATION CRUCIALE : Ne pas continuer si le contrôleur est fermé
      if (_myressourceController.isClosed) return;

      if (response.statusCode == 200) {
        // ✅ Ne pas forcer le typage en Map, accepter le dynamic
        final dynamic data = jsonDecode(response.body);
        _currentMycessource = data;

        if (!_myressourceController.isClosed) {
          _myressourceController.add(data);
        }
      } else if (response.statusCode == 204 || response.statusCode == 404) {
        _currentMycessource = null;
        if (!_myressourceController.isClosed) {
          _myressourceController.add(null);
        }
      } else {
        debugPrint('❌ Erreur API : ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('⏱️ Timeout lors du fetch');
    } catch (e) {
      debugPrint('❌ Exception : $e');
    }
  }

  Future<void> refresh() async => await _fetchActiveRessource();

  void dispose() {
    arreter();
    _myressourceController.close();
  }
}

class iaConversation {
  Timer? _pollingTimer;

  final _iaConversationController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get iaConversationStream => _iaConversationController.stream;

  dynamic _currentIaConversation;
  dynamic get currentiaConversation => _currentIaConversation;

  bool _isPolling = false;

  void demarrer({Duration interval = const Duration(seconds: 2)}) {
    if (_isPolling) return;
    _isPolling = true;

    debugPrint('▶️ Démarrage du polling (toutes les ${interval.inSeconds}s)');
    _fetchIachate();
    _pollingTimer = Timer.periodic(interval, (_) => _fetchIachate());
  }

  void arreter() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    debugPrint('⏹️ Arrêt du polling');
  }

  Future<void> _fetchIachate() async {
    try {
      final tkn = await geToken();
      final response = await http
          .get(
            Uri.parse('$baseurl/api/my-formations'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $tkn',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (_iaConversationController.isClosed) return;

      if (response.statusCode == 200) {
        // ✅ Ne pas forcer le typage en Map, accepter le dynamic
        final dynamic data = jsonDecode(response.body);
        _currentIaConversation = data;

        if (!_iaConversationController.isClosed) {
          _iaConversationController.add(data);
        }
      } else if (response.statusCode == 204 || response.statusCode == 404) {
        _currentIaConversation = null;
        if (!_iaConversationController.isClosed) {
          _iaConversationController.add(null);
        }
      } else {
        debugPrint('❌ Erreur API : ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('⏱️ Timeout lors du fetch');
    } catch (e) {
      debugPrint('❌ Exception : $e');
    }
  }

  Future<void> refresh() async => await _fetchIachate();

  void dispose() {
    arreter();
    _iaConversationController.close();
  }
}

class ctConversation {
  Timer? _pollingTimer;

  final _ctConversationController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get ctConversationStream => _ctConversationController.stream;

  dynamic _currentCtConversation;
  dynamic get currentctConversation => _currentCtConversation;

  bool _isPolling = false;

  void demarrer({Duration interval = const Duration(seconds: 2)}) {
    if (_isPolling) return;
    _isPolling = true;

    debugPrint('▶️ Démarrage du polling (toutes les ${interval.inSeconds}s)');
    _fetchCtchate();
    _pollingTimer = Timer.periodic(interval, (_) => _fetchCtchate());
  }

  void arreter() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    debugPrint('⏹️ Arrêt du polling');
  }

  Future<void> _fetchCtchate() async {
    try {
      final tkn = await geToken();
      final response = await http
          .get(
            Uri.parse('$baseurl/api/chat/contacts'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $tkn',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (_ctConversationController.isClosed) return;

      if (response.statusCode == 200) {
        // ✅ Ne pas forcer le typage en Map, accepter le dynamic
        final dynamic data = jsonDecode(response.body);
        _currentCtConversation = data;

        if (!_ctConversationController.isClosed) {
          _ctConversationController.add(data);
        }
      } else if (response.statusCode == 204 || response.statusCode == 404) {
        _currentCtConversation = null;
        if (!_ctConversationController.isClosed) {
          _ctConversationController.add(null);
        }
      } else {
        debugPrint('❌ Erreur API : ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('⏱️ Timeout lors du fetch');
    } catch (e) {
      debugPrint('❌ Exception : $e');
    }
  }

  Future<void> refresh() async => await _fetchCtchate();

  void dispose() {
    arreter();
    _ctConversationController.close();
  }
}

class unreadMsg {
  Timer? _pollingTimer;

  final _unreadMsgController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get unreadMsgStream => _unreadMsgController.stream;

  dynamic _currentUnreadMsg;
  dynamic get currentLive => _currentUnreadMsg;

  bool _isPolling = false;

  void demarrer({Duration interval = const Duration(seconds: 2)}) {
    if (_isPolling) return;
    _isPolling = true;

    debugPrint('▶️ Démarrage du polling (toutes les ${interval.inSeconds}s)');
    _fetchUnreadMsg();
    _pollingTimer = Timer.periodic(interval, (_) => _fetchUnreadMsg());
  }

  void arreter() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    debugPrint('⏹️ Arrêt du polling');
  }

  Future<void> _fetchUnreadMsg() async {
    try {
      final tkn = await geToken();
      final response = await http
          .get(
            Uri.parse('$baseurl/api/chat/unread-count'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $tkn',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (_unreadMsgController.isClosed) return;

      if (response.statusCode == 200) {
        // ✅ Ne pas forcer le typage en Map, accepter le dynamic
        final dynamic data = jsonDecode(response.body);
        _currentUnreadMsg = data;

        if (!_unreadMsgController.isClosed) {
          _unreadMsgController.add(data);
        }
      } else if (response.statusCode == 204 || response.statusCode == 404) {
        _currentUnreadMsg = null;
        if (!_unreadMsgController.isClosed) {
          _unreadMsgController.add(null);
        }
      } else {
        debugPrint('❌ Erreur API : ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('⏱️ Timeout lors du fetch');
    } catch (e) {
      debugPrint('❌ Exception : $e');
    }
  }

  Future<void> refresh() async => await _fetchUnreadMsg();

  void dispose() {
    arreter();
    _unreadMsgController.close();
  }
}

class msgId(int id) {
  final ids = id;
  Timer? _pollingTimer;

  final _msidController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get msidStream => _msidController.stream;

  dynamic _currentMsid;
  dynamic get currentLive => _currentMsid;

  bool _isPolling = false;

  void demarrer({Duration interval = const Duration(seconds: 2)}) {
    if (_isPolling) return;
    _isPolling = true;

    debugPrint('▶️ Démarrage du polling (toutes les ${interval.inSeconds}s)');
    _fetchmsid();
    _pollingTimer = Timer.periodic(interval, (_) => _fetchmsid());
  }

  void arreter() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    debugPrint('⏹️ Arrêt du polling');
  }

  Future<void> _fetchmsid() async {
    try {
      final tkn = await geToken();
      final response = await http
          .get(
            Uri.parse('$baseurl/api/chat/conversations/$ids'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $tkn',
            },
          )
          .timeout(const Duration(seconds: 4));

      //if (_msidController.isClosed) return;

      if (response.statusCode == 200) {
        // ✅ Ne pas forcer le typage en Map, accepter le dynamic
        //print(response.body);
        final dynamic data = jsonDecode(response.body);
        _currentMsid = data;

        if (!_msidController.isClosed) {
          _msidController.add(data);
          //print(_currentMsid);
        }
      } else if (response.statusCode == 204 || response.statusCode == 404) {
        _currentMsid = null;
        if (!_msidController.isClosed) {
          _msidController.add(null);
        }
      } else {
        debugPrint('❌ Erreur API : ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('⏱️ Timeout lors du fetch');
    } catch (e) {
      debugPrint('❌ Exception : $e');
    }
  }

  Future<void> refresh() async => await _fetchmsid();

  void dispose() {
    arreter();
    _msidController.close();
  }
}

class convIA() {
  Timer? _pollingTimer;

  final _msiaidController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get msiaidStream => _msiaidController.stream;

  dynamic _currentMsiaid;
  dynamic get currentMsgiaid => _currentMsiaid;

  bool _isPolling = false;

  void demarrer({Duration interval = const Duration(seconds: 2)}) {
    if (_isPolling) return;
    _isPolling = true;

    debugPrint('▶️ Démarrage du polling (toutes les ${interval.inSeconds}s)');
    _fetchmsiaid();
    _pollingTimer = Timer.periodic(interval, (_) => _fetchmsiaid());
  }

  void arreter() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    debugPrint('⏹️ Arrêt du polling');
  }

  Future<void> _fetchmsiaid() async {
    try {
      final tkn = await geToken();
      final response = await http
          .get(
            Uri.parse('$baseurl/api/assistant/conversations'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $tkn',
            },
          )
          .timeout(const Duration(seconds: 4));

      //if (_msidController.isClosed) return;

      if (response.statusCode == 200) {
        // ✅ Ne pas forcer le typage en Map, accepter le dynamic
        //print(response.body);
        final dynamic data = jsonDecode(response.body);
        _currentMsiaid = data;

        if (!_msiaidController.isClosed) {
          _msiaidController.add(data);
          //print(_currentMsid);
        }
      } else if (response.statusCode == 204 || response.statusCode == 404) {
        _currentMsiaid = null;
        if (!_msiaidController.isClosed) {
          _msiaidController.add(null);
        }
      } else {
        debugPrint('❌ Erreur API : ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('⏱️ Timeout lors du fetch');
    } catch (e) {
      debugPrint('❌ Exception : $e');
    }
  }

  Future<void> refresh() async => await _fetchmsiaid();

  void dispose() {
    arreter();
    _msiaidController.close();
  }
}

class chatIA(int id) {
  var id = id;
  Timer? _pollingTimer;

  final _chatiaController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get chatiaStream => _chatiaController.stream;

  dynamic _currentChatia;
  dynamic get currentChatia => _currentChatia;

  bool _isPolling = false;

  void demarrer({Duration interval = const Duration(seconds: 2)}) {
    if (_isPolling) return;
    _isPolling = true;

    debugPrint('▶️ Démarrage du polling (toutes les ${interval.inSeconds}s)');
    _fetchchatia();
    _pollingTimer = Timer.periodic(interval, (_) => _fetchchatia());
  }

  void arreter() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    debugPrint('⏹️ Arrêt du polling');
  }

  Future<void> _fetchchatia() async {
    try {
      final tkn = await geToken();
      final response = await http
          .get(
            Uri.parse('$baseurl/api/assistant/conversations/$id'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $tkn',
            },
          )
          .timeout(const Duration(seconds: 4));

      //if (_msidController.isClosed) return;
      if (response.statusCode == 200) {
        // ✅ Ne pas forcer le typage en Map, accepter le dynamic
        //print(response.body);
        final dynamic data = jsonDecode(response.body);
        _currentChatia = data;

        if (!_chatiaController.isClosed) {
          _chatiaController.add(data);
          //print(_currentMsid);
        }
      } else if (response.statusCode == 204 || response.statusCode == 404) {
        _currentChatia = null;
        if (!_chatiaController.isClosed) {
          _chatiaController.add(null);
        }
      } else {
        debugPrint('❌ Erreur API : ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('⏱️ Timeout lors du fetch');
    } catch (e) {
      debugPrint('❌ Exception : $e');
    }
  }

  Future<void> refresh() async => await _fetchchatia();

  void dispose() {
    arreter();
    _chatiaController.close();
  }
}

class events(int id) {
  Timer? _pollingTimer;

  final _eventsController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get eventsStream => _eventsController.stream;

  dynamic _currentEvents;
  dynamic get currentMsgiaid => _currentEvents;

  bool _isPolling = false;

  void demarrer({Duration interval = const Duration(seconds: 2)}) {
    if (_isPolling) return;
    _isPolling = true;

    debugPrint('▶️ Démarrage du polling (toutes les ${interval.inSeconds}s)');
    _fetcheventsid();
    _pollingTimer = Timer.periodic(interval, (_) => _fetcheventsid());
  }

  void arreter() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    debugPrint('⏹️ Arrêt du polling');
  }

  Future<void> _fetcheventsid() async {
    try {
      final tkn = await geToken();
      final response = await http
          .get(
            Uri.parse('$baseurl/api/events'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $tkn',
            },
          )
          .timeout(const Duration(seconds: 4));

      //if (_msidController.isClosed) return;

      if (response.statusCode == 200) {
        // ✅ Ne pas forcer le typage en Map, accepter le dynamic
        //print(response.body);
        final dynamic data = jsonDecode(response.body);
        _currentEvents = data;

        if (!_eventsController.isClosed) {
          _eventsController.add(data);
          //print(_currentMsid);
        }
      } else if (response.statusCode == 204 || response.statusCode == 404) {
        _currentEvents = null;
        if (!_eventsController.isClosed) {
          _eventsController.add(null);
        }
      } else {
        debugPrint('❌ Erreur API : ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('⏱️ Timeout lors du fetch');
    } catch (e) {
      debugPrint('❌ Exception : $e');
    }
  }

  Future<void> refresh() async => await _fetcheventsid();

  void dispose() {
    arreter();
    _eventsController.close();
  }
}
