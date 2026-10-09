import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yafintech/services/secure_storage.dart';

const String _configuredApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.1.89:8000',
);

const String _configuredMobileAdminPortalUrl = String.fromEnvironment(
  'ADMIN_PORTAL_URL',
  defaultValue: 'http://192.168.1.89:5173',
);

String get baseurl =>
    _configuredApiBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');

String get mobileAdminPortalUrl => _configuredMobileAdminPortalUrl
    .trim()
    .replaceFirst(RegExp(r'/+$'), '');

String get storageUrl => '$baseurl/storage';

Future<Map<String, dynamic>> getUser() async {
  final data = await SecureStorageService.getAccessUser();

  if (data == null || data.isEmpty) {
    return {};
  }

  return jsonDecode(data) as Map<String, dynamic>;
}

Future<String> geToken() async {
  final token = await SecureStorageService.getAccessToken();

  if (token == null || token.isEmpty) {
    return '';
  }
  return token;
}

Future<bool> checkconnecte() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult.contains(ConnectivityResult.mobile) ||
      connectivityResult.contains(ConnectivityResult.wifi) ||
      connectivityResult.contains(ConnectivityResult.ethernet);
}

Future<bool> login(String email, String password) async {
  // print("$email,  🧶🧶🧶🧶🧶🧶🧶  $password ");
  try {
    final response = await http
        .post(
          Uri.parse('$baseurl/api/login'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    final decoded = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        decoded is Map) {
      final token = decoded['token'] ?? decoded['access_token'];
      if (token is! String || token.trim().isEmpty) return false;
      //print('Connexion réussie');
      debugPrint('Connexion réussie.');
      //print(data['user']);

      await SecureStorageService.saveTokens(accessToken: token);
      await SecureStorageService.saveUser(
        accessUser: jsonEncode(decoded['user'] ?? <String, dynamic>{}),
      );
      return (true);
    } else {
      //print(data['message'] ?? 'Identifiants incorrects');
      return (false);
    }
  } catch (e) {
    debugPrint('Erreur de connexion à $baseurl : $e');
    return (false);
  }
}

Future<Map<String, dynamic>> fetchAuthenticatedUser() async {
  final token = await geToken();
  if (token.isEmpty) {
    throw StateError('Aucun jeton de connexion disponible.');
  }

  final response = await http
      .get(
        Uri.parse('$baseurl/api/me'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
      .timeout(const Duration(seconds: 15));

  dynamic decoded;
  try {
    decoded = jsonDecode(response.body);
  } catch (_) {
    decoded = null;
  }

  if (response.statusCode != 200 || decoded is! Map) {
    final message = decoded is Map
        ? decoded['message']?.toString()
        : null;
    throw StateError(
      message?.isNotEmpty == true
          ? message!
          : 'Le profil connecté n’a pas pu être chargé.',
    );
  }

  final rawUser = decoded['user'] is Map ? decoded['user'] : decoded;
  final user = Map<String, dynamic>.from(rawUser as Map);
  await SecureStorageService.saveUser(accessUser: jsonEncode(user));
  return user;
}

Future<String> register(Map<String, dynamic> donnes) async {
  try {
    final response = await http.post(
      Uri.parse('$baseurl/api/register'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },

      body: jsonEncode(donnes),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      final token = data['token'];
      //print('Inscription  réussie');
      //print(data['user']);
      await SecureStorageService.saveTokens(accessToken: token);
      await SecureStorageService.saveUser(accessUser: jsonEncode(data['user']));
      //final gg = response.statusCode;
      //print('🔗🔗🔗🔗🔗🔗🔗🔗🔗🔗🔗🔗🔗 $gg');
      return data['message'];
    } else {
      // print('♦️♦️♦️♦️♦️♦️♦️♦️♦️♦️♦️♦️');

      //print(data['message'] ?? "erreur l'ors de l'incscription ");
      return data['message'];
    }
  } catch (e) {
    print('Erreur : $e');
    return 'erreur du serveur';
  }
}

Future<void> register_Menber(Map<String, dynamic> donnes) async {
  // Map nn = donnes;
  //print('$nn 🧶🧶🧶🧶🧶');
  try {
    final response = await http.post(
      Uri.parse('$baseurl/api/members'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },

      body: jsonEncode(donnes),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      //  print('Inscription de menbre réussie');
      //return true;
    } else {
      //print(data['message'] ?? "erreur l'ors de l'incscription ");
      //return false;
    }
  } catch (e) {
    print('Erreur : $e');
    //return false;
  }
}

Future<void> role_fonction() async {
  try {
    final response = await http.get(
      Uri.parse('$baseurl/api/super-admin/roles-and-fonctions'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },

      //body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // print('🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖');
      print(data);
    } else {
      print('Erreur : ${response.statusCode}');
      print(response.body);
    }
  } catch (e) {
    print('Erreur réseau : $e');
  }
}

Future<int> Qr_presence(String qr, double latitude, double longitude) async {
  final user = await SecureStorageService.getAccessUser();

  final jsUser = jsonDecode(user ?? '{}');

  // print("👩‍💻👩‍💻👩‍💻👩‍💻👩‍💻👩‍💻👩‍💻👩‍💻👩‍💻👩‍💻👩‍💻👩‍💻👩‍💻👩‍💻👩‍💻👩‍💻👩‍💻 $jsUser",);
  try {
    final response = await http.post(
      Uri.parse('$baseurl/api/attendance/scan-public'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'qr_token': qr,
        'member_code': jsUser['member']['member_code'],
        'lat': latitude,
        'lng': longitude,
      }),
    );
    // print('🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖  ${response.statusCode}');
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);

      //print('🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖');
      print(data);
      return response.statusCode;
    } else {
      print('Erreur : ${response.statusCode}');
      print(response.body);
      return response.statusCode;
    }
  } catch (e) {
    print('Erreur réseau : $e');
    return 0;
  }
}

Future<void> logout() async {
  final token = await geToken();
  try {
    if (token.isNotEmpty) {
      await http
          .post(
            Uri.parse('$baseurl/api/logout'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 8));
    }
  } catch (_) {
    // La session locale doit quand même être supprimée si le réseau est coupé.
  } finally {
    await SecureStorageService.clearAll();
  }
}

Future<void> updateProfile(Map<String, dynamic> updatedData) async {
  final user = await SecureStorageService.getAccessUser();
  final jsUser = jsonDecode(user ?? '{}');
  final userId = jsUser['id'];

  try {
    final response = await http.put(
      Uri.parse('$baseurl/api/members/$userId'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updatedData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      //print('Profil mis à jour avec succès');
      ///print(data);
      // Mettre à jour les informations de l'utilisateur dans le stockage sécurisé
      await SecureStorageService.saveUser(accessUser: jsonEncode(data['user']));
    } else {
      print('Erreur lors de la mise à jour du profil : ${response.statusCode}');
      print(response.body);
    }
  } catch (e) {
    print('Erreur réseau : $e');
  }
}

Future<Map<String, dynamic>> getFormation() async {
  try {
    final response = await http.get(
      Uri.parse('$baseurl/api/formations'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer  ${await geToken()}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Formations récupérées avec succès');
      //print(data);
      return data;
    } else {
      print(
        'Erreur lors de la récupération des formations : ${response.statusCode}',
      );
      //print(response.body);
      return {'error': 'Erreur lors de la récupération des formations'};
    }
  } catch (e) {
    print('Erreur réseau : $e');
    return {'error': 'Erreur réseau'};
  }
}

Future<Map<String, dynamic>> getRessources() async {
  try {
    final response = await http.get(
      Uri.parse('$baseurl/api/resources'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer  ${await geToken()}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      //print('Ressources récupérées avec succès');
      //print(data);
      return data;
    } else {
      //print( 'Erreur lors de la récupération des ressources : ${response.statusCode}', );
      print(response.body);
      return {'error': 'Erreur lors de la récupération des ressources'};
    }
  } catch (e) {
    print('Erreur réseau : $e');
    return {'error': 'Erreur réseau'};
  }
}

Future<void> resourceCategorie() async {
  try {
    final response = await http.get(
      Uri.parse('$baseurl/api/resource-categories'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer  ${await geToken()}',
      },

      //body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      //print('🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖');
      print(data);
    } else {
      print('Erreur : ${response.statusCode}');
      print(response.body);
    }
  } catch (e) {
    print('Erreur réseau : $e');
  }
}

Future<void> sendMsg(int id, String msg) async {
  try {
    final response = await http.post(
      Uri.parse('$baseurl/api/chat/messages'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await geToken()}',
      },

      body: jsonEncode({"recipient_id": id, "contenu": msg}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      //print('🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️');
      //print(data);
    } else {
      //print('🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️');
      print('Erreur : ${response.statusCode}');
      // print(response.body);
    }
  } catch (e) {
    //print('🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️');
    print('Erreur réseau : $e');
  }
}

Future<Map<String, dynamic>> newIADisc(String msg) async {
  //print( '🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️',);
  try {
    final response = await http.post(
      Uri.parse('$baseurl/api/assistant/conversations'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await geToken()}',
      },

      body: jsonEncode({"titre": msg}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      //print('🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️');
      // print(data);
      return data;
    } else {
      //print('🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️');
      print('Erreur : ${response.statusCode}');
      //print(response.body);
      return {'error': 'Erreur lors de la création de la conversation'};
    }
  } catch (e) {
    //print('🗞️🗞️🗞️🗞️🗞️🗞️🗞️🗞️');
    print('Erreur réseau : $e');
    return {'error': 'Erreur réseau'};
  }
}

Future<void> sendIAMsg(int id, String msg) async {
  try {
    final response = await http.post(
      Uri.parse('$baseurl/api/assistant/conversations/$id/messages'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await geToken()}',
      },

      body: jsonEncode({"contenu": msg}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      //print('🛞🛞🛞🛞🛞🛞🛞🛞🛞');
      //print(data);
    } else {
      //print('🛞🛞🛞🛞🛞🛞🛞🛞🛞🛞🛞🛞');
      print('Erreur : ${response.statusCode}');
      //print(response.body);
    }
  } catch (e) {
    //print('🛞🛞🛞🛞🛞🛞🛞🛞🛞🛞🛞🛞');
    print('Erreur réseau : $e');
  }
}
