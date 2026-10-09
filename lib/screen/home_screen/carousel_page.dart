import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yafintech/core/theme/app_color.dart';
import 'package:yafintech/services/auth_service.dart';
import 'package:yafintech/services/reload_service.dart';

class MonCarrousel extends StatefulWidget {
  const MonCarrousel({super.key});

  @override
  State<MonCarrousel> createState() => _MonCarrouselState();
}

class _MonCarrouselState extends State<MonCarrousel> {
  final PageController _pageController = PageController(viewportFraction: 0.94);
  final getFormationService _formationService = getFormationService();
  final getRessourceService _resourceService = getRessourceService();

  StreamSubscription? _formationSubscription;
  StreamSubscription? _resourceSubscription;
  List<Map<String, dynamic>> _formations = [];
  List<Map<String, dynamic>> _resources = [];
  bool _formationsLoaded = false;
  bool _resourcesLoaded = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _formationSubscription = _formationService.formationStream.listen((data) {
      if (!mounted) return;
      setState(() {
        _formations = _normalizeItems(data);
        _formationsLoaded = true;
      });
    });
    _resourceSubscription = _resourceService.ressourceStream.listen((data) {
      if (!mounted) return;
      setState(() {
        _resources = _normalizeItems(data);
        _resourcesLoaded = true;
      });
    });

    _formationService.demarrer(interval: const Duration(seconds: 30));
    _resourceService.demarrer(interval: const Duration(seconds: 30));
  }

  List<Map<String, dynamic>> _normalizeItems(dynamic value) {
    dynamic rawItems = value;
    if (rawItems is Map && rawItems.containsKey('data')) {
      rawItems = rawItems['data'];
    }

    if (rawItems is List) {
      return rawItems
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (rawItems is Map) {
      return [Map<String, dynamic>.from(rawItems)];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _Feature(
        label: 'FORMATIONS',
        title: _formations.isEmpty
            ? 'Apprenez à votre rythme'
            : (_formations.first['title']?.toString() ?? 'Vos formations'),
        subtitle: _formationsLoaded
            ? _countLabel(_formations.length, 'formation')
            : 'Chargement des formations…',
        image: _formations.isEmpty
            ? null
            : _formations.first['cover_image']?.toString(),
        icon: Icons.menu_book_rounded,
        color: AppColors.primary,
        routeIndex: 0,
      ),
      _Feature(
        label: 'RESSOURCES',
        title: _resources.isEmpty
            ? 'Des contenus à découvrir'
            : (_resources.first['title']?.toString() ?? 'Vos ressources'),
        subtitle: _resourcesLoaded
            ? _countLabel(_resources.length, 'ressource')
            : 'Chargement des ressources…',
        image: _resources.isEmpty
            ? null
            : (_resources.first['cover_image'] ??
                      _resources.first['thumbnail'] ??
                      _resources.first['image'])
                  ?.toString(),
        icon: Icons.library_books_rounded,
        color: AppColors.secondary,
        routeIndex: 1,
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 214,
          child: PageView.builder(
            controller: _pageController,
            itemCount: cards.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildFeatureCard(context, cards[index]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            cards.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _countLabel(int count, String item) {
    if (count == 0) return 'Parcourez les contenus disponibles';
    final plural = count > 1 ? 's' : '';
    return '$count $item$plural disponible$plural';
  }

  Widget _buildFeatureCard(BuildContext context, _Feature feature) {
    final imagePath = feature.image?.trim() ?? '';
    final imageUrl = imagePath.isEmpty
        ? null
        : (imagePath.startsWith('http')
              ? imagePath
              : '$storageUrl/$imagePath');

    return Material(
      color: feature.color,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/ongle', extra: feature.routeIndex),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(feature),
              )
            else
              _fallback(feature),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x08000000),
                    Color(0xC9000000),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  child: Text(
                    feature.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          feature.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          feature.subtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const CircleAvatar(
                    radius: 21,
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF24243A),
                    child: Icon(Icons.arrow_forward_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback(_Feature feature) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [feature.color, feature.color.withValues(alpha: 0.65)],
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Icon(
            feature.icon,
            size: 92,
            color: Colors.white.withValues(alpha: 0.16),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _formationSubscription?.cancel();
    _resourceSubscription?.cancel();
    _formationService.dispose();
    _resourceService.dispose();
    super.dispose();
  }
}

class _Feature {
  const _Feature({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.icon,
    required this.color,
    required this.routeIndex,
  });

  final String label;
  final String title;
  final String subtitle;
  final String? image;
  final IconData icon;
  final Color color;
  final int routeIndex;
}
