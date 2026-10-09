import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:yafintech/services/auth_service.dart';
import 'package:yafintech/services/secure_storage.dart';
import 'package:yafintech/screen/fenetre/mobile_qr_capture.dart';

class AdminPortalPage extends StatefulWidget {
  const AdminPortalPage({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<AdminPortalPage> createState() => _AdminPortalPageState();
}

class _AdminPortalPageState extends State<AdminPortalPage> {
  InAppWebViewController? _controller;
  late Future<UserScript> _bootstrapFuture;
  int _progress = 0;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _createBootstrapScript();
  }

  Future<UserScript> _createBootstrapScript() async {
    final token = await geToken();
    final tokenLiteral = jsonEncode(token);
    final userLiteral = jsonEncode(jsonEncode(widget.user));
    final apiBaseLiteral = jsonEncode('$baseurl/api');
    return UserScript(
      source: '''
        (() => {
          try {
            localStorage.setItem('auth_token', $tokenLiteral);
            localStorage.setItem('auth_user', $userLiteral);
            localStorage.setItem('current_church_id', 'all');
            window.__CHURCH_MOBILE_API_BASE_URL__ = $apiBaseLiteral;
            window.__CHURCH_MOBILE_NATIVE__ = true;
          } catch (_) {}
        })();
      ''',
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      forMainFrameOnly: true,
    );
  }

  void _registerLogoutBridge(InAppWebViewController controller) {
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    controller.addJavaScriptHandler(
      handlerName: 'churchNativeLogout',
      callback: (arguments) async {
        await SecureStorageService.clearAll();
        if (mounted) router.go('/connexion');
        return true;
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'churchStartQrScan',
      callback: (arguments) {
        if (!mounted) return null;
        return navigator.push<String>(
          MaterialPageRoute<String>(
            builder: (_) => const MobileQrCapturePage(),
          ),
        );
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'churchGetCurrentLocation',
      callback: (arguments) async {
        try {
          if (!await Geolocator.isLocationServiceEnabled()) {
            return {'success': false, 'message': 'Activez la localisation du téléphone.'};
          }

          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            return {'success': false, 'message': 'Autorisez la localisation pour cette application.'};
          }

          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );
          return {
            'success': true,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
          };
        } catch (_) {
          return {'success': false, 'message': 'La position GPS n’a pas pu être récupérée.'};
        }
      },
    );
  }

  Future<void> _reload() async {
    setState(() {
      _loadError = null;
      _progress = 0;
    });
    await _controller?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.user['role'];
    final roleName = role is Map ? (role['name'] ?? 'Administration') : 'Administration';
    final userName = (widget.user['name'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Espace administratif'),
            Text(
              [userName, roleName.toString()].where((value) => value.trim().isNotEmpty).join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Recharger le portail',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Se déconnecter',
            onPressed: () async {
              final router = GoRouter.of(context);
              await logout();
              if (mounted) router.go('/connexion');
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: FutureBuilder<UserScript>(
        future: _bootstrapFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('La session mobile ne peut pas être transmise au portail.'),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
              if (_loadError != null)
                MaterialBanner(
                  content: Text(_loadError!),
                  actions: [TextButton(onPressed: _reload, child: const Text('Réessayer'))],
                ),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(mobileAdminPortalUrl)),
                  initialUserScripts: UnmodifiableListView<UserScript>([snapshot.data!]),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    supportZoom: false,
                    mediaPlaybackRequiresUserGesture: false,
                  ),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                    _registerLogoutBridge(controller);
                  },
                  onProgressChanged: (controller, progress) {
                    if (!mounted) return;
                    setState(() => _progress = progress);
                  },
                  onReceivedError: (controller, request, error) {
                    if (!mounted || request.isForMainFrame != true) return;
                    setState(() {
                      _loadError =
                          'Le portail Vue est inaccessible. Vérifie que le serveur '
                          'frontend est démarré et joignable depuis le mobile.';
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
