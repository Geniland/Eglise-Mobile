import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yafintech/services/auth_service.dart';
import 'package:geolocator/geolocator.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool scanned = false;
  var lastbarcode;
  final MobileScannerController controller = MobileScannerController();

  Future<Position?> getCurrentLocation() async {
    // Vérifier si la localisation est activée
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      //print('La localisation est désactivée');
      return null;
    }

    // Vérifier l'autorisation
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        //print('Permission refusée');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // Récupérer la position
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scanner un QR code'),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            tooltip: 'Activer ou désactiver le flash',
            onPressed: controller.toggleTorch,
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
        ],
      ),

      body: Stack(
        children: [
          MobileScanner(
            controller: controller,

            onDetect: (capture) async {
              if (scanned) return;

              for (final barcode in capture.barcodes) {
                final String? value = barcode.rawValue;
                if (lastbarcode != value) {
                  if (value != null) {
                    scanned = true;

                    try {
                      final jsValue = jsonDecode(value);
                      if (jsValue['t'] == null) {
                        throw Exception('QR invalide');
                      }
                      final position = await getCurrentLocation();
                      if (position == null) {
                        scanned = false;
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Activez la localisation pour valider votre présence.',
                            ),
                          ),
                        );
                        return;
                      }

                      final presence = await Qr_presence(
                        jsValue['t'],
                        position.latitude,
                        position.longitude,
                      );

                      await controller.stop();
                      if (presence == 200 || presence == 201) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('presence validé '),
                            duration: Duration(seconds: 3),
                            backgroundColor: Color.fromARGB(255, 35, 134, 38),
                          ),
                        );
                      } else if (presence == 409) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('vous ete deja verifier '),
                            duration: Duration(seconds: 3),
                            backgroundColor: Color.fromARGB(255, 56, 58, 56),
                          ),
                        );
                      } else if (presence == 400) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('localisaton invalide '),
                            duration: Duration(seconds: 3),
                            backgroundColor: Color.fromARGB(255, 171, 47, 38),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('QR_CODE expiré !'),
                            duration: Duration(seconds: 3),
                            backgroundColor: Color.fromARGB(255, 171, 47, 38),
                          ),
                        );
                      }

                      if (!mounted) return;

                      context.pop();
                    } catch (e) {
                      scanned = false;

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Impossible de valider ce code. Réessayez.',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    lastbarcode = value;
                    return;
                  }
                }
              }
            },
          ),

          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 28,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Placez le code dans le cadre pour confirmer votre présence.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
