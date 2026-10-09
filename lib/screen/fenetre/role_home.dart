import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yafintech/screen/fenetre/admin_portal.dart';
import 'package:yafintech/screen/fenetre/home.dart';
import 'package:yafintech/services/auth_service.dart';
import 'package:yafintech/services/secure_storage.dart';

class RoleAwareHomePage extends StatefulWidget {
  const RoleAwareHomePage({super.key});

  @override
  State<RoleAwareHomePage> createState() => _RoleAwareHomePageState();
}

class _RoleAwareHomePageState extends State<RoleAwareHomePage> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = fetchAuthenticatedUser();
  }

  String _roleName(Map<String, dynamic> user) {
    final role = user['role'];
    if (role is Map) return (role['name'] ?? '').toString().trim();
    return (user['role_name'] ?? '').toString().trim();
  }

  String _normalizeRole(String value) => value
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .trim();

  Future<void> _signOut() async {
    await logout();
    if (mounted) context.go('/connexion');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Impossible de vérifier votre compte auprès du serveur.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Vérifiez la connexion réseau puis réessayez. '
                          'Les pages autorisées sont chargées depuis le backend.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => setState(
                            () => _profileFuture = fetchAuthenticatedUser(),
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Réessayer'),
                        ),
                        TextButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Se déconnecter'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final user = snapshot.data!;
        if (_normalizeRole(_roleName(user)) == 'fidele') {
          return const HomePage();
        }

        return AdminPortalPage(user: user);
      },
    );
  }
}
