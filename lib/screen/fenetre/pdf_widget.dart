import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yafintech/services/auth_service.dart';
import 'package:gal/gal.dart';
import 'package:yafintech/services/telecharge_service.dart';

class PdfCard extends StatefulWidget {
  final String pdfCover;
  final String pdfPath;
  final String pdfName;
  final String pdfDescription;
  final bool is_free;
  final String price;
  final Map<String, dynamic> infos;

  const PdfCard({
    super.key,
    required this.pdfPath,
    required this.pdfCover,
    required this.pdfName,
    required this.pdfDescription,
    required this.is_free,
    required this.price,
    required this.infos,
  });

  @override
  State<PdfCard> createState() => _PdfCardState();
}

class _PdfCardState extends State<PdfCard> {
  bool visible = true;
  bool connected = false;

  bool _isLoading = true;
  bool _hasError = false;

  int _loadId = 0;

  // ============================================================
  // VISIBILITE
  // ============================================================

  // ============================================================
  // VERIFICATION CONNEXION
  // ============================================================

  Future<bool> checkConnection() async {
    final result = await checkconnecte();

    if (!mounted) return result;

    setState(() {
      connected = result;
    });

    return result;
  }

  // ============================================================
  // INITIALISATION
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadPdf();
  }

  // ============================================================
  // CHARGEMENT IMAGE
  // ============================================================

  Future<void> _loadPdf() async {
    final int currentLoad = ++_loadId;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // ----------------------------------------------------------
      // VERIFICATION URL
      // ----------------------------------------------------------

      final uri = Uri.tryParse(widget.pdfCover);

      if (uri == null ||
          !uri.hasScheme ||
          (uri.scheme != 'http' && uri.scheme != 'https')) {
        throw Exception('URL pdf invalide');
      }

      // ----------------------------------------------------------
      // VERIFICATION INTERNET
      // ----------------------------------------------------------

      final hasConnection = await checkconnecte();

      if (!mounted || currentLoad != _loadId) {
        return;
      }

      setState(() {
        connected = hasConnection;
      });

      // ----------------------------------------------------------
      // PAS INTERNET
      // ----------------------------------------------------------

      if (!hasConnection) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });

        return;
      }

      // ----------------------------------------------------------
      // INTERNET DISPONIBLE
      //
      // Image.network sera maintenant affichée.
      // ----------------------------------------------------------

      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      debugPrint('ERREUR PDF : $e');

      if (!mounted || currentLoad != _loadId) {
        return;
      }

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // ============================================================
  // REESSAYER
  // ============================================================

  Future<void> _retry() async {
    if (_isLoading) return;

    await _loadPdf();
  }

  // ============================================================
  // ERREUR / PAS INTERNET
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      height: 230,
      color: Colors.black,

      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const Icon(Icons.wifi_off, color: Colors.white70, size: 50),

              const SizedBox(height: 12),

              const Text(
                'pdf indisponible',
                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Vérifiez votre connexion Internet.',
                textAlign: TextAlign.center,

                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),

              const SizedBox(height: 15),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _retry,

                icon: const Icon(Icons.refresh),

                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      height: 230,
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 35,
              height: 35,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 15),

            Text(
              'Chargement du pdf...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          if (widget.is_free) {
            context.push(
              '/pdf',
              extra: {
                'pdfPath': widget.pdfPath,
                'pdfName': widget.pdfName,
                'pdfDescription': widget.pdfDescription,
              },
            );
          }
        },
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),

                child: _hasError
                    ? _buildError()
                    : _isLoading
                    ? _buildLoading()
                    : Image.network(
                        widget.pdfCover,

                        // 100% de la largeur
                        width: double.infinity,

                        // conserve le ratio original
                        fit: BoxFit.fitWidth,

                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return _buildLoading();
                        },

                        // ==================================================
                        // ERREUR DE TELECHARGEMENT
                        // ==================================================
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Erreur chargement pdf : $error');

                          return _buildError();
                        },
                      ),
              ),
            ),

            // ======================================================
            // INFORMATIONS
            // ======================================================
            if (!_hasError && !_isLoading)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text(
                                widget.pdfName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.pdfDescription,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (widget.is_free)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 8, 179, 88),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  telechargerPdf(
                                    context,
                                    widget.pdfPath,
                                    widget.pdfName,
                                  );
                                },
                                icon: Icon(
                                  Icons.download,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            )
                          else
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    '${widget.price} FCFA',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
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
    _loadId++;
    super.dispose();
  }
}
