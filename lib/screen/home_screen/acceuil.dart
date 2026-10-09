import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yafintech/core/theme/app_color.dart';
import 'package:yafintech/screen/home_screen/carousel_page.dart';
import 'package:yafintech/services/auth_service.dart';
import 'package:yafintech/services/reload_service.dart';

class Acceuil extends StatefulWidget {
  const Acceuil({super.key});

  @override
  State<Acceuil> createState() => _AcceuilState();
}

class _AcceuilState extends State<Acceuil> with SingleTickerProviderStateMixin {
  Map<String, dynamic> _user = {};
  final LiveServiceActive _liveService = LiveServiceActive();
  StreamSubscription<Map<String, dynamic>?>? _liveSubscription;
  Map<String, dynamic>? _live;
  bool _liveLoaded = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadUser();

    _liveSubscription = _liveService.liveStream.listen((live) {
      if (!mounted) return;
      setState(() {
        _live = live;
        _liveLoaded = true;
      });
      _updateLiveAnimation();
    });
    _liveService.demarrer(interval: const Duration(seconds: 30));
  }

  Future<void> _loadUser() async {
    try {
      final data = await getUser();
      if (!mounted) return;
      setState(() => _user = Map<String, dynamic>.from(data));
    } catch (error) {
      debugPrint('Chargement du profil impossible : $error');
    }
  }

  bool get _isLiveActive {
    return _liveDetails?['status'] == 'live';
  }

  Map<String, dynamic>? get _liveDetails {
    final data = _live?['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return _live;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  void _updateLiveAnimation() {
    if (_isLiveActive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!_isLiveActive && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (_user['name'] ?? '').toString().trim();
    final churchName = (_user['church_name'] ?? '').toString().trim();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_greeting, style: theme.textTheme.bodySmall),
            Text(
              name.isEmpty ? 'sur Yafintech' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isLiveActive ? 'Regarder le direct' : 'Direct',
            onPressed: () => context.push('/live'),
            icon: _isLiveActive
                ? ScaleTransition(
                    scale: _pulseAnimation,
                    child: const Icon(
                      Icons.radio_button_checked_rounded,
                      color: AppColors.error,
                    ),
                  )
                : const Icon(Icons.podcasts_rounded),
          ),
          IconButton(
            tooltip: 'Scanner un QR code',
            onPressed: () => context.push('/scanner'),
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VOTRE ESPACE COMMUNAUTAIRE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      churchName.isEmpty ? 'Grandissons ensemble' : churchName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Retrouvez vos formations, vos ressources et les actualités de votre communauté.',
                      style: TextStyle(color: Colors.white, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _liveSummaryCard(theme),
              const SizedBox(height: 24),
              Text('Accès rapides', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _quickAction(
                        context,
                        width: itemWidth,
                        icon: Icons.menu_book_rounded,
                        title: 'Formations',
                        subtitle: 'Apprendre et progresser',
                        onTap: () => context.push('/ongle', extra: 0),
                      ),
                      _quickAction(
                        context,
                        width: itemWidth,
                        icon: Icons.library_books_rounded,
                        title: 'Ressources',
                        subtitle: 'Explorer les contenus',
                        onTap: () => context.push('/ongle', extra: 1),
                      ),
                      _quickAction(
                        context,
                        width: itemWidth,
                        icon: Icons.event_available_rounded,
                        title: 'Agenda',
                        subtitle: 'Voir le programme',
                        onTap: () => context.push('/event'),
                      ),
                      _quickAction(
                        context,
                        width: itemWidth,
                        icon: Icons.download_done_rounded,
                        title: 'Téléchargés',
                        subtitle: 'Mes contenus enregistrés',
                        onTap: () => context.push('/ongle', extra: 2),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 26),
              Text('À découvrir', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              const MonCarrousel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _liveSummaryCard(ThemeData theme) {
    final liveTitle = _liveDetails?['title']?.toString().trim();
    final hasTitle = liveTitle != null && liveTitle.isNotEmpty;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/live'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (_isLiveActive ? AppColors.error : AppColors.secondary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  _isLiveActive ? Icons.sensors_rounded : Icons.podcasts_rounded,
                  color: _isLiveActive ? AppColors.error : AppColors.secondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      !_liveLoaded
                          ? 'Vérification du direct…'
                          : _isLiveActive
                          ? (hasTitle
                                ? liveTitle!
                                : 'Une diffusion est en cours')
                          : 'Le direct',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      !_liveLoaded
                          ? 'Chargement du statut'
                          : _isLiveActive
                          ? 'En direct · Touchez pour regarder'
                          : 'Aucune diffusion en cours',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required double width,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.primary, size: 23),
                const SizedBox(height: 14),
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _liveSubscription?.cancel();
    _pulseController.dispose();
    _liveService.dispose();
    super.dispose();
  }
}
