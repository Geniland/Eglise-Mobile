import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/auth_service.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  bool _requestInProgress = false;
  String? _error;
  String _filterType = 'all';

  static const _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  static const _weekdays = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents(initial: true);
  }

  Future<void> _loadEvents({bool initial = false}) async {
    if (_requestInProgress) return;
    _requestInProgress = true;

    if (!initial && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final token = await geToken();
      if (token.isEmpty) {
        throw const _EventApiException(
          'Connecte-toi pour consulter les événements.',
        );
      }

      final firstPage = await _fetchEventsPage(token, 1);
      final events = <Map<String, dynamic>>[...firstPage.events];

      for (var page = 2; page <= firstPage.lastPage; page++) {
        final nextPage = await _fetchEventsPage(token, page);
        events.addAll(nextPage.events);
      }

      events.removeWhere((event) => event['status'] != 'published');
      events.sort(_compareEventsByDate);

      if (mounted) {
        setState(() {
          _events
            ..clear()
            ..addAll(events);
          _error = null;
          if (_filterType != 'all' &&
              !_events.any((event) => _eventType(event) == _filterType)) {
            _filterType = 'all';
          }
        });
      }
    } on _EventApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les événements. Vérifie ta connexion puis réessaie.';
        });
      }
    } finally {
      _requestInProgress = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<_EventsPage> _fetchEventsPage(String token, int page) async {
    final uri = Uri.parse('$baseurl/api/events').replace(
      queryParameters: {
        'status': 'published',
        'per_page': '100',
        'page': '$page',
      },
    );

    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      throw const _EventApiException('Ta session a expiré. Reconnecte-toi.');
    }
    if (response.statusCode == 403) {
      throw const _EventApiException(
        'Ton compte n’est pas autorisé à consulter les événements.',
      );
    }
    if (response.statusCode != 200) {
      throw _EventApiException(
        'Le serveur n’a pas pu charger les événements (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    final dynamic rawEvents = decoded is List
        ? decoded
        : decoded is Map<String, dynamic>
        ? decoded['data']
        : null;

    if (rawEvents is! List) {
      throw const FormatException('Réponse événements invalide.');
    }

    final events = rawEvents
        .whereType<Map>()
        .map((event) => Map<String, dynamic>.from(event))
        .toList();

    final metadata = decoded is Map<String, dynamic> && decoded['meta'] is Map
        ? Map<String, dynamic>.from(decoded['meta'] as Map)
        : const <String, dynamic>{};
    final lastPage = int.tryParse('${metadata['last_page'] ?? 1}') ?? 1;

    return _EventsPage(events: events, lastPage: lastPage < 1 ? 1 : lastPage);
  }

  int _compareEventsByDate(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    final firstDate = _eventDate(first);
    final secondDate = _eventDate(second);

    if (firstDate == null && secondDate == null) return 0;
    if (firstDate == null) return 1;
    if (secondDate == null) return -1;

    final dateOrder = firstDate.compareTo(secondDate);
    if (dateOrder != 0) return dateOrder;
    return _value(first['start_time']).compareTo(_value(second['start_time']));
  }

  List<Map<String, dynamic>> get _filteredEvents {
    if (_filterType == 'all') return _events;
    return _events.where((event) => _eventType(event) == _filterType).toList();
  }

  List<String> get _eventTypes {
    final types = _events
        .map(_eventType)
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList();
    types.sort(
      (first, second) => _typeLabelFor(first).compareTo(_typeLabelFor(second)),
    );
    return types;
  }

  String _eventType(Map<String, dynamic> event) => _value(event['type']);

  String _typeLabelFor(String type) {
    for (final event in _events) {
      if (_eventType(event) == type) {
        final label = _value(event['type_label']);
        if (label.isNotEmpty) return label;
      }
    }
    return type.isEmpty ? 'Événement' : type;
  }

  DateTime? _eventDate(Map<String, dynamic> event) {
    final value = _value(event['event_date']);
    return value.isEmpty ? null : DateTime.tryParse(value);
  }

  String _value(dynamic value) => value == null ? '' : '$value'.trim();

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date non précisée';
    return '${_weekdays[date.weekday - 1]} ${date.day} '
        '${_months[date.month - 1]} ${date.year}';
  }

  String _formatTime(Map<String, dynamic> event) {
    final start = _value(event['start_time']);
    final end = _value(event['end_time']);
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start → $end';
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'conference':
        return const Color(0xFF1976D2);
      case 'special_service':
        return const Color(0xFF388E3C);
      case 'seminar':
      case 'formation':
        return const Color(0xFF7B1FA2);
      case 'meeting':
        return const Color(0xFF00838F);
      case 'retreat':
        return const Color(0xFF5E35B1);
      case 'evangelism':
        return const Color(0xFFE65100);
      case 'youth':
        return const Color(0xFFC2185B);
      case 'women':
        return const Color(0xFFAD1457);
      default:
        return const Color(0xFF5C6BC0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Événements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loading ? null : () => _loadEvents(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadEvents(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildFilterBar()),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildMessageState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Événements indisponibles',
                  message: _error!,
                  action: TextButton.icon(
                    onPressed: () => _loadEvents(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ),
              )
            else if (_events.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyEventsState(
                  message: 'Il n’y a aucun événement pour le moment.',
                ),
              )
            else if (_filteredEvents.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyEventsState(
                  message: 'Aucun événement ne correspond à ce type.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildEventCard(_filteredEvents[index]),
                    childCount: _filteredEvents.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final types = _eventTypes;

    return SizedBox(
      height: 60,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _buildFilterChip(
              type: 'all',
              label: 'Tous',
              color: const Color(0xFF5C6BC0),
            ),
            for (final type in types)
              _buildFilterChip(
                type: type,
                label: _typeLabelFor(type),
                color: _typeColor(type),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String type,
    required String label,
    required Color color,
  }) {
    final isSelected = _filterType == type;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        selectedColor: color,
        backgroundColor: color.withValues(alpha: 0.1),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (selected) {
          if (!selected || _filterType == type) return;
          setState(() => _filterType = type);
        },
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 12), action],
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final date = _eventDate(event);
    final type = _eventType(event);
    final typeColor = _typeColor(type);
    final title = _value(event['title']);
    final description = _value(event['description']);
    final location = _value(event['location']);
    final time = _formatTime(event);
    final isFeatured =
        event['is_featured'] == true || event['is_featured'] == 1;
    final today = DateTime.now();
    final eventDay = date == null
        ? null
        : DateTime(date.year, date.month, date.day);
    final isPast =
        eventDay != null &&
        eventDay.isBefore(DateTime(today.year, today.month, today.day));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isFeatured
            ? BorderSide(color: typeColor, width: 1.5)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: isPast ? Colors.blueGrey : typeColor,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        date == null
                            ? 'DATE'
                            : _months[date.month - 1]
                                  .substring(0, 3)
                                  .toUpperCase(),
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        date == null ? '—' : '${date.day}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _typeLabelFor(type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title.isEmpty ? 'Événement' : title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFeatured) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.star, color: Colors.amber, size: 21),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description.isNotEmpty) ...[
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                ],
                if (time.isNotEmpty) ...[
                  _buildInfoRow(Icons.access_time, typeColor, time),
                  if (location.isNotEmpty) const SizedBox(height: 8),
                ],
                if (location.isNotEmpty)
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    typeColor,
                    location,
                  ),
                if ((time.isNotEmpty || location.isNotEmpty))
                  const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _formatDate(date),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isPast)
                      const Chip(
                        label: Text('Passé'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: TextStyle(fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _EmptyEventsState extends StatelessWidget {
  const _EmptyEventsState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, size: 68, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucun événement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _EventsPage {
  const _EventsPage({required this.events, required this.lastPage});

  final List<Map<String, dynamic>> events;
  final int lastPage;
}

class _EventApiException implements Exception {
  const _EventApiException(this.message);

  final String message;
}
