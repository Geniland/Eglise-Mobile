import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yafintech/core/theme/app_theme.dart';
import 'package:yafintech/core/theme/theme_service.dart';
import 'package:yafintech/screen/fenetre/chat.dart';
import 'package:yafintech/screen/fenetre/chatIA.dart';
import 'package:yafintech/screen/home_screen/evenement.dart';
import 'package:yafintech/screen/fenetre/pdf_page.dart';
import 'package:yafintech/screen/fenetre/pdf_widget.dart';
import 'package:yafintech/screen/fenetre/ongle.dart';

import "screen/auth/connexion.dart";
import 'screen/auth/inscription.dart';
import 'screen/auth/inscription_local.dart';
import 'screen/auth/inscription_mail.dart';
import 'screen/auth/inscription_nom.dart';
import 'screen/auth/inscription_profile.dart';
import 'screen/auth/inscription_statut.dart';
import 'screen/auth/password.dart';
import 'screen/fenetre/live_page.dart';
import 'screen/fenetre/message.dart';
import 'screen/fenetre/qr_page.dart';
import 'screen/fenetre/scanner.dart';
import 'screen/fenetre/profile.dart';
import 'screen/fenetre/role_home.dart';
import 'services/audio_handler.dart';
import 'services/secure_storage.dart';

late GoRouter routes;
late MyAudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? token = await SecureStorageService.getAccessToken();

  final themeService = ThemeService();
  await themeService.loadTheme();

  routes = GoRouter(
    initialLocation: token == null || token.isEmpty ? '/connexion' : '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const RoleAwareHomePage()),
      GoRoute(path: '/inscription', builder: (context, state) => Inscription()),
      GoRoute(
        path: '/inscriptionNom',
        builder: (context, state) => InscriptionNom(),
      ),
      GoRoute(
        path: '/inscriptionMail',
        builder: (context, state) {
          final nouveauUtilisateur = state.extra as Map<String, dynamic>;
          return InscriptionMail(nouveauUtilisateur: nouveauUtilisateur);
        },
      ),
      GoRoute(
        path: '/inscriptionLocal',
        builder: (context, state) {
          final nouveauUtilisateur = state.extra as Map<String, dynamic>;
          return InscriptionLocal(nouveauUtilisateur: nouveauUtilisateur);
        },
      ),
      GoRoute(
        path: '/inscriptionStatut',
        builder: (context, state) {
          final nouveauUtilisateur = state.extra as Map<String, dynamic>;
          return InscriptionStatut(nouveauUtilisateur: nouveauUtilisateur);
        },
      ),
      GoRoute(path: '/connexion', builder: (context, state) => Connexion()),
      GoRoute(
        path: '/password',
        builder: (context, state) {
          final nouveauUtilisateur = state.extra as Map<String, dynamic>;
          return Password(nouveauUtilisateur: nouveauUtilisateur);
        },
      ),
      GoRoute(
        path: '/inscriptionProfile',
        builder: (context, state) {
          final nouveauUtilisateur = state.extra as Map<String, dynamic>;
          return InscriptionProfile(nouveauUtilisateur: nouveauUtilisateur);
        },
      ),
      GoRoute(path: '/message', builder: (context, state) => Message()),
      GoRoute(path: '/scanner', builder: (context, state) => ScannerPage()),
      GoRoute(path: '/profile', builder: (context, state) => ProfilePage()),
      GoRoute(path: '/live', builder: (context, state) => LivePage()),
      GoRoute(path: '/qrPage', builder: (context, state) => QrCodePage()),
      GoRoute(
        path: '/pdf',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};

          return PdfPage(
            pdfPath: extra['pdfPath'] ?? '',
            pdfName: extra['pdfName'] ?? 'Document PDF',
            pdfDescription: extra['pdfDescription'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/chart',
        builder: (context, state) {
          final extra = state.extra as int;
          return ChatPage(id: extra);
        },
      ),
      GoRoute(
        path: '/chatia',
        builder: (context, state) {
          return ChatIAPage();
        },
      ),
      GoRoute(path: '/event', builder: (context, state) => EventPage()),
      GoRoute(
        path: '/ongle',
        builder: (context, state) {
          final extra = state.extra as int? ?? 0;
          return Onglets(index: extra);
        },
      ),
    ],
  );

  // ✅ Initialiser le service audio en arrière-plan
  /* audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.yafintech.audio',
      androidNotificationChannelName: 'Lecture audio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  ); */

  runApp(
    ChangeNotifierProvider.value(value: themeService, child: const MyApp()),
  );
}

// ============================================================
// MYAPP
// ============================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          routerConfig: routes,
        );
      },
    );
  }
}
