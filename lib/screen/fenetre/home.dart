import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yafintech/screen/fenetre/chatIA.dart';
import 'package:yafintech/screen/fenetre/profile.dart';
import 'package:yafintech/screen/home_screen/acceuil.dart';
import 'package:yafintech/screen/home_screen/discussion.dart';
import 'package:yafintech/screen/home_screen/evenement.dart';
import 'package:yafintech/services/reload_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pageIndex = 0;
  int _unreadCount = 0;

  final List<Widget> _pages = const [
    Acceuil(),
    DiscussionPage(),
    ChatIAPage(),
    EventPage(),
    ProfilePage(),
  ];

  final unreadMsg _unreadService = unreadMsg();
  StreamSubscription? _unreadSubscription;

  @override
  void initState() {
    super.initState();
    _unreadSubscription = _unreadService.unreadMsgStream.listen((data) {
      if (!mounted) return;
      final count = data?['unread_count'];
      setState(() {
        _unreadCount = count is int ? count : int.tryParse('$count') ?? 0;
      });
    });
    _unreadService.demarrer(interval: const Duration(seconds: 20));
  }

  void _selectPage(int index) {
    if (index == _pageIndex) return;
    setState(() => _pageIndex = index);
  }

  Widget _messageIcon(IconData icon) {
    return Badge(
      isLabelVisible: _unreadCount > 0,
      label: Text(_unreadCount > 99 ? '99+' : '$_unreadCount'),
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _pageIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pageIndex,
        onDestinationSelected: _selectPage,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: _messageIcon(Icons.chat_bubble_outline_rounded),
            selectedIcon: _messageIcon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Assistant',
          ),
          const NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Agenda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    _unreadService.arreter();
    super.dispose();
  }
}
