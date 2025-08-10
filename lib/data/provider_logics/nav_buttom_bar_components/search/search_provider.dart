/*
 * Fecha de creación: 26/04/2025
 * Autor: KingdomOfJames
 *
 * Descripción:
 * Este código define un proveedor de búsqueda para manejar y cargar información sobre artistas
 * a partir de una base de datos de Firebase. Proporciona funcionalidades para actualizar la lista
 * de artistas, agregar un artista, y escuchar cambios en los usuarios que han sido "gustados" por
 * el usuario actual. También incluye métodos para obtener artistas filtrados por género, país, estado,
 * precio y disponibilidad, y ordenarlos según la relevancia para un evento específico.
 * 
 * Características:
 * - Gestión de la lista de artistas.
 * - Escucha de cambios en los usuarios "gustados" y actualización de su estado.
 * - Carga de información de los artistas según diferentes criterios de filtrado.
 * - Formateo de fechas y manejo de las zonas geográficas.
 * - Clasificación de artistas por prioridad según ubicación y especialidad.
 * 
 * Recomendaciones:
 * - Asegúrate de manejar correctamente las excepciones y casos en los que los documentos no existen.
 * - Considera optimizar las consultas a la base de datos para manejar grandes cantidades de usuarios/artistas.
 * - Si utilizas este código en una app en producción, revisa el rendimiento de las consultas en tiempo real.
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class SearchProvider extends ChangeNotifier {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> artists = [];
  String _currentCountry = '';
  String get currentCountry => _currentCountry;
  String _currentState = '';
  String get currentState => _currentState;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  likedUsersListener;

  void clearArtists() {
    artists.clear();
    notifyListeners();
  }

  void updateArtists(List<Map<String, dynamic>> newArtists) {
    artists.clear();
    artists.addAll(newArtists);
    notifyListeners();
  }

  void addArtist(Map<String, dynamic> artistData) {
    artists.add(artistData);
    notifyListeners();
  }

  SearchProvider() {
    destroyLikedUsersListener();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      listenForLikedUsersChanges(currentUserId);
    }
  }

  void destroyLikedUsersListener() {
    likedUsersListener?.cancel();
    likedUsersListener = null;
  }

  String formatFirebaseTimestamp(Timestamp firebaseTimestamp) {
    final date = firebaseTimestamp.toDate();
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  Future<void> loadCountryAndState(String currentUserId) async {
    final document =
        await firestore.collection('users').doc(currentUserId).get();
    if (document.exists) {
      final data = document.data();
      _currentCountry = data?['country'] ?? '';
      _currentState = data?['state'] ?? '';
      notifyListeners();
    }
  }

  Future<double> getMinServicePrice(String userId) async {
    try {
      final querySnapshot =
          await firestore
              .collection('services')
              .doc(userId)
              .collection('service')
              .get();

      if (querySnapshot.docs.isEmpty) return 0.0;

      double minPrice = double.infinity;
      for (final doc in querySnapshot.docs) {
        final price = (doc.data()['price'] as num?)?.toDouble() ?? 0.0;
        if (price < minPrice) {
          minPrice = price;
        }
      }
      return minPrice == double.infinity ? 0.0 : minPrice;
    } catch (e) {
      print('Error getting min service price: $e');
      return 0.0;
    }
  }

  Future<void> loadServices(String currentUserId, List<String> ids) async {
    final List<Map<String, dynamic>> updatedServices = [];

    for (final userId in ids) {
      try {
        final serviceDoc =
            await firestore.collection('services').doc(userId).get();
        final serviceData = serviceDoc.data() ?? {};
        final serviceInfo = serviceData['service'] ?? {};
        final name = serviceInfo['name'];
        final imageUrl = serviceInfo['imageUrl'];

        if (name == null ||
            name.toString().isEmpty ||
            imageUrl == null ||
            imageUrl.toString().isEmpty) {
          continue;
        }

        double lowestPrice = double.infinity;
        final List<String> allImages = [imageUrl];

        final servicesCollection =
            await firestore.collection('services/$userId/service').get();

        for (final doc in servicesCollection.docs) {
          final subServiceData = doc.data();
          final price = subServiceData['price']?.toDouble() ?? double.infinity;
          if (price < lowestPrice) {
            lowestPrice = price;
          }

          if (subServiceData['imageList'] is List) {
            final images = List<String>.from(subServiceData['imageList'] ?? []);
            allImages.addAll(images);
          }
        }

        if (lowestPrice == double.infinity) {
          continue;
        }

        final serviceInfoMap = {
          'userId': userId,
          'name': name,
          'profileImageUrl': imageUrl,
          'price': lowestPrice,
          'imageList': allImages,
          'userLiked': await checkIfUserLiked(currentUserId, userId),
        };

        updatedServices.add(serviceInfoMap);
      } catch (e) {
        print('Error cargando servicio para $userId: $e');
      }
    }

    artists.clear();
    artists.addAll(updatedServices);
    notifyListeners();
  }

  void listenForLikedUsersChanges(String currentUserId) {
    destroyLikedUsersListener();
    final userRef = firestore.collection('users').doc(currentUserId);

    likedUsersListener = userRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final likedUsers = List<String>.from(
          snapshot.data()?['likedUsers'] ?? [],
        );
        for (final artistId in likedUsers) {
          updateUserLikedInRoom(artistId, true);
        }
      }
    });
  }

  Future<void> updateUserLikedInRoom(String artistId, bool userLiked) async {
    final index = artists.indexWhere(
      (element) => element['userId'] == artistId,
    );
    if (index != -1) {
      artists[index]['userLiked'] = userLiked;
      notifyListeners();
    }
  }

  Future<bool> checkIfUserLiked(String currentUserId, String artistId) async {
    try {
      final userDocument =
          await firestore.collection('users').doc(currentUserId).get();
      final likedUsers = List<String>.from(
        userDocument.data()?['likedUsers'] ?? [],
      );
      return likedUsers.contains(artistId);
    } catch (e) {
      print('$e');
      return false;
    }
  }

  Future<void> getUsersByCountry(
    String currentUserId,
    List<String> selectedGenres,
    RangeValues priceRange,
    String availability,
    String serviceType,
  ) async {
    final formattedAvailability =
        availability.isEmpty
            ? formatFirebaseTimestamp(Timestamp.now())
            : availability;

    final reallySelectedGenres =
        (serviceType == 'artist')
            ? (selectedGenres.isEmpty
                ? [
                  'Banda',
                  'Norteño',
                  'Corridos',
                  'Mariachi',
                  'Sierreño',
                  'Cumbia',
                  'Reggaetón y/o música urbana',
                ]
                : selectedGenres)
            : [];

    final querySnapshot = await firestore.collection('users').get();
    final List<Map<String, dynamic>> userList = [];

    for (final document in querySnapshot.docs) {
      final userData = document.data();
      final userType = userData['userType'] ?? '';

      // Verificar tipo de usuario (incluyendo los nuevos tipos)
      if (![
        'artist',
        'bakery',
        'place',
        'decoration',
        'furniture',
        'entertainment',
      ].contains(userType)) {
        continue;
      }

      if (userType != serviceType) {
        continue;
      }

      final genres = List<String>.from(userData['genres'] ?? []);
      final country = userData['country'] ?? '';
      final state = userData['state'] ?? '';
      final userValue = userData['userValue'] ?? 0.0;
      final countries = List<String>.from(userData['countries'] ?? []);
      final states = List<String>.from(userData['states'] ?? []);
      final busyDays = List<String>.from(userData['busyDays'] ?? []);
      final specialties = List<String>.from(userData['specialties'] ?? []);

      final minPrice = await getMinServicePrice(document.id);

      bool matchesPrice =
          priceRange.start <= minPrice && minPrice <= priceRange.end;
      bool matchesAvailability = !busyDays.contains(formattedAvailability);
      bool matchesLocation =
          (country == _currentCountry ||
              states.contains(_currentState) ||
              states.contains('Todos los estados'));
      bool matchesGenres =
          (serviceType != 'artist') ||
          genres.any((genre) => reallySelectedGenres.contains(genre));

      if (matchesPrice &&
          matchesAvailability &&
          matchesLocation &&
          matchesGenres) {
        userList.add({
          'id': document.id,
          'genres': genres,
          'country': country,
          'state': state,
          'userValue': userValue,
          'countries': countries,
          'states': states,
          'price': minPrice,
          'specialties': specialties,
        });
      }
    }

    userList.sort((a, b) {
      final aPriority = _calculatePriority(a, serviceType);
      final bPriority = _calculatePriority(b, serviceType);
      if (aPriority != bPriority) return bPriority - aPriority;
      return (b['userValue'] as double).compareTo(a['userValue'] as double);
    });

    final userIds = userList.map((user) => user['id'] as String).toList();
    await loadServices(currentUserId, userIds);
  }

  int _calculatePriority(Map<String, dynamic> user, String serviceType) {
    final country = user['country'] as String;
    final state = user['state'] as String;
    final countries = List<String>.from(user['countries'] as List<dynamic>);
    final states = List<String>.from(user['states'] as List<dynamic>);
    final specialties = List<String>.from(user['specialties'] as List<dynamic>);

    final isPrimaryLocation =
        (country == _currentCountry && state == _currentState);
    final hasExactStateMatch =
        (country == _currentCountry && states.contains(_currentState));
    final hasAllStatesMatch =
        (country == _currentCountry && states.contains('Todos los estados'));
    final hasSpecialty = specialties.contains(serviceType);

    if (isPrimaryLocation) return 4;
    if (hasExactStateMatch) return 3;
    if (hasAllStatesMatch) return 2;
    if (hasSpecialty) return 1;
    return 0;
  }
}

class SearchProviderWidget extends StatelessWidget {
  final Widget child;

  const SearchProviderWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchProvider(),
      child: child,
    );
  }
}
