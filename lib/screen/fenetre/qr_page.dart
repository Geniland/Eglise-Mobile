import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yafintech/services/auth_service.dart';
import 'package:yafintech/services/secure_storage.dart';

class QrCodePage extends StatefulWidget {
  const QrCodePage({super.key});

  @override
  State<QrCodePage> createState() => _QrCodePageState();
}

class _QrCodePageState extends State<QrCodePage> {
  Map<String, dynamic> _user = {};
  Uint8List? _qrImage;
  String? _loadError;
  bool _isLoading = true;
  bool _requestInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadData(initial: true);
  }

  Future<void> _loadData({bool initial = false}) async {
    if (_requestInProgress) return;
    _requestInProgress = true;

    if (!initial && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final token = await geToken();
      if (token.isEmpty) {
        throw const _QrCodeLoadException(
          'Ta session a expiré. Reconnecte-toi pour afficher ton QR code.',
        );
      }

      final response = await http
          .get(
            Uri.parse('$baseurl/api/me/qr-code'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = jsonDecode(response.body);
      final responseData = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};

      if (response.statusCode == 401) {
        throw const _QrCodeLoadException(
          'Ta session a expiré. Reconnecte-toi pour afficher ton QR code.',
        );
      }
      if (response.statusCode == 403) {
        throw const _QrCodeLoadException(
          'Ton compte n’est pas autorisé à afficher ce QR code.',
        );
      }
      if (response.statusCode == 404) {
        throw _QrCodeLoadException(
          responseData['message']?.toString() ??
              'Aucun profil fidèle n’est rattaché à ce compte.',
        );
      }
      if (response.statusCode != 200) {
        throw _QrCodeLoadException(
          responseData['message']?.toString() ??
              'Le serveur n’a pas pu charger ton QR code.',
        );
      }

      final qrDataUrl = responseData['qr_data_url']?.toString().trim() ?? '';
      if (qrDataUrl.isEmpty) {
        throw const _QrCodeLoadException(
          'Le serveur n’a pas fourni le QR code de ce compte.',
        );
      }

      final separatorIndex = qrDataUrl.indexOf(',');
      final encodedImage = separatorIndex >= 0
          ? qrDataUrl.substring(separatorIndex + 1)
          : qrDataUrl;
      late final Uint8List qrImage;
      try {
        qrImage = base64Decode(encodedImage.replaceAll(RegExp(r'\s'), ''));
      } on FormatException {
        throw const _QrCodeLoadException(
          'L’image QR reçue du serveur est illisible. Réessaie plus tard.',
        );
      }

      final userData = await SecureStorageService.getAccessUser();
      final Map<String, dynamic> user = userData == null || userData.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(userData) as Map);

      final rawMember = responseData['member'];
      if (rawMember is Map) {
        final cachedMember = user['member'];
        user['member'] = {
          if (cachedMember is Map) ...Map<String, dynamic>.from(cachedMember),
          ...Map<String, dynamic>.from(rawMember),
        };
      }

      if (!mounted) return;
      setState(() {
        _user = user;
        _qrImage = qrImage;
        _loadError = null;
      });
    } on _QrCodeLoadException catch (error) {
      if (mounted) setState(() => _loadError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError = 'Impossible de joindre le serveur. Vérifie ta connexion puis réessaie.';
        });
      }
    } finally {
      _requestInProgress = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawMember = _user['member'];
    final member = rawMember is Map ? rawMember : const <dynamic, dynamic>{};
    final memberCode = member['member_code']?.toString();
    final memberName = [
      member['first_name']?.toString().trim() ?? '',
      member['last_name']?.toString().trim() ?? '',
    ].where((part) => part.isNotEmpty).join(' ');
    final displayName = memberName.isNotEmpty
        ? memberName
        : (_user['name']?.toString().trim().isNotEmpty == true
              ? _user['name'].toString()
              : 'Votre compte');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon QR code'),
        actions: [
          IconButton(
            tooltip: 'Actualiser le QR code',
            onPressed: _isLoading ? null : () => _loadData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final qrSize = constraints.maxWidth < 360
                ? constraints.maxWidth - 88
                : 260.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Votre code d’accès',
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Présentez ce QR code lorsque l’application vous le demande.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 260,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : _loadError != null || _qrImage == null
                              ? _buildUnavailable(theme)
                              : Semantics(
                                  label: 'QR code du compte',
                                  child: Container(
                                    alignment: Alignment.center,
                                    color: Colors.white,
                                    padding: const EdgeInsets.all(8),
                                    child: Image.memory(
                                      _qrImage!,
                                      width: qrSize,
                                      height: qrSize,
                                      fit: BoxFit.contain,
                                      gaplessPlayback: true,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) => _buildUnavailable(theme),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        displayName,
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      if (memberCode != null && memberCode.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'N° membre : $memberCode',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUnavailable(ThemeData theme) {
    final message =
        _loadError ??
        'Le QR code de ce compte n’a pas encore été fourni par le serveur.';

    return SizedBox(
      height: 260,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_2, size: 52, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'QR code indisponible',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _isLoading ? null : () => _loadData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrCodeLoadException implements Exception {
  const _QrCodeLoadException(this.message);

  final String message;
}
