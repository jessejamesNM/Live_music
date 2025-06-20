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

// SearchProvider maneja la lógica de la búsqueda y el estado de los artistas.
class SearchProvider extends ChangeNotifier {
  // Instancia de Firestore para acceder a la base de datos
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  // Lista que contiene los artistas encontrados
  final List<Map<String, dynamic>> artists = [];
  // Variables para el país y estado actuales
  String _currentCountry = '';
  String get currentCountry => _currentCountry;
  String _currentState = '';
  String get currentState => _currentState;

  // Variable para escuchar los cambios de usuarios que han sido marcados como "gustados"
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  likedUsersListener;

  // Limpia la lista de artistas
  void clearArtists() {
    artists.clear();
    notifyListeners(); // Notifica que se ha actualizado el estado
  }

  // Actualiza la lista de artistas con nuevos datos
  void updateArtists(List<Map<String, dynamic>> newArtists) {
    artists.clear();
    artists.addAll(newArtists);
    notifyListeners();
  }

  // Agrega un nuevo artista a la lista
  void addArtist(Map<String, dynamic> artistData) {
    artists.add(artistData); // Añade el artista a la lista
    notifyListeners(); // Notifica que se ha actualizado el estado
  }

  // Constructor que inicializa el listener de usuarios "gustados" si hay un usuario logueado
  SearchProvider() {
    destroyLikedUsersListener();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      listenForLikedUsersChanges(
        currentUserId,
      ); // Comienza a escuchar los cambios de los usuarios "gustados"
    }
  }

  // Detiene la escucha de cambios de usuarios "gustados"
  void destroyLikedUsersListener() {
    likedUsersListener?.cancel();
    likedUsersListener = null;
  }

  // Formatea un timestamp de Firebase en un formato de fecha legible
  String formatFirebaseTimestamp(Timestamp firebaseTimestamp) {
    final date = firebaseTimestamp.toDate();
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  // Carga el país y estado del usuario desde la base de datos
  Future<void> loadCountryAndState(String currentUserId) async {
    final document =
        await firestore.collection('users').doc(currentUserId).get();
    if (document.exists) {
      final data = document.data();
      _currentCountry = data?['country'] ?? '';
      _currentState = data?['state'] ?? '';

      notifyListeners();
    } else {}
  }

  // Carga los artistas basados en una lista de IDs de artistas
  Future<void> loadArtists(String currentUserId, List<String> ids) async {
    final List<Map<String, dynamic>> updatedArtists = [];

    for (final artistId in ids) {
      try {
        final artistDocument =
            await firestore.collection('users').doc(artistId).get();
        final data = artistDocument.data() ?? {};

        // Verifica que los campos requeridos estén presentes
        final name = data['name'];
        final profileImageUrl = data['profileImageUrl'];
        final nickname = data['nickname'];

        if (name == null ||
            name.toString().isEmpty ||
            profileImageUrl == null ||
            profileImageUrl.toString().isEmpty ||
            nickname == null ||
            nickname.toString().isEmpty) {
          continue; // Si falta información importante, salta este artista
        }

        data['userId'] = artistId;
        final isUserLiked = await checkIfUserLiked(
          currentUserId,
          artistId,
        ); // Verifica si el usuario ha "gustado" este artista
        data['userLiked'] = isUserLiked;

        updatedArtists.add(data); // Añade el artista procesado
      } catch (e) {
        print('$e');
      }
    }

    artists.clear();
    artists.addAll(updatedArtists);
    notifyListeners();
  }

  // Escucha los cambios en los usuarios "gustados"
  void listenForLikedUsersChanges(String currentUserId) {
    destroyLikedUsersListener();

    final userRef = firestore.collection('users').doc(currentUserId);

    likedUsersListener = userRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final likedUsers = List<String>.from(
          snapshot.data()?['likedUsers'] ?? [],
        );

        for (final artistId in likedUsers) {
          updateUserLikedInRoom(
            artistId,
            true,
          ); // Actualiza la lista de artistas marcados como "gustados"
        }
      }
    });
  }

  // Actualiza si un artista ha sido "gustado" en la sala de artistas
  Future<void> updateUserLikedInRoom(String artistId, bool userLiked) async {
    final index = artists.indexWhere(
      (element) => element['userId'] == artistId,
    );
    if (index != -1) {
      artists[index]['userLiked'] = userLiked;
      notifyListeners();
    }
  }

  // Verifica si un usuario ha marcado a un artista como "gustado"
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

  // Filtra y obtiene usuarios por criterios como país, géneros, precio, disponibilidad y tipo de evento
  Future<void> getUsersByCountry(
    String currentUserId,
    List<String> selectedGenres,
    RangeValues priceRange,
    String availability,
    String eventType,
  ) async {
    final formattedAvailability =
        availability.isEmpty
            ? formatFirebaseTimestamp(Timestamp.now())
            : availability;

    final reallySelectedGenres =
        selectedGenres.isEmpty
            ? [
              'Banda',
              'Norteño',
              'Corridos',
              'Mariachi',
              'Sierreño',
              'Cumbia',
              'Reggaetón y/o música urbana',
            ]
            : selectedGenres;

    final querySnapshot = await firestore.collection('users').get();
    final List<Map<String, dynamic>> userList = [];

    // Filtra los usuarios según los criterios proporcionados
    for (final document in querySnapshot.docs) {
      final userType = document.data()['userType'] ?? '';
      if (userType != 'artist') continue;

      final genres = List<String>.from(document.data()['genres'] ?? []);
      final country = document.data()['country'] ?? '';
      final state = document.data()['state'] ?? '';
      final userValue = document.data()['userValue'] ?? 0.0;
      final countries = List<String>.from(document.data()['countries'] ?? []);
      final states = List<String>.from(document.data()['states'] ?? []);
      final price = document.data()['price'] ?? 0.0;
      final busyDays = List<String>.from(document.data()['busyDays'] ?? []);
      final specialties = List<String>.from(
        document.data()['specialties'] ?? [],
      );

      // Verifica que el precio, género, disponibilidad y ubicación cumplan con los filtros
      if (priceRange.start <= price &&
          price <= priceRange.end &&
          genres.any((genre) => reallySelectedGenres.contains(genre)) &&
          !busyDays.contains(formattedAvailability) &&
          (country == _currentCountry || states.contains(_currentState) || states.contains('Todos los estados'))) {
        userList.add({
          'id': document.id,
          'genres': genres,
          'country': country,
          'state': state,
          'userValue': userValue,
          'countries': countries,
          'states': states,
          'price': price,
          'specialties': specialties,
        });
      }
    }

    // Ordena los usuarios por prioridad y valor de usuario
    userList.sort((a, b) {
      final aPriority = _calculatePriority(a, eventType);
      final bPriority = _calculatePriority(b, eventType);
      if (aPriority != bPriority) return bPriority - aPriority;
      return (b['userValue'] as double).compareTo(a['userValue'] as double);
    });

    // Carga los artistas según los IDs de los usuarios encontrados
    final userIds = userList.map((user) => user['id'] as String).toList();
    await loadArtists(currentUserId, userIds);
  }

  // Calcula la prioridad de un usuario según su ubicación y especialización
  int _calculatePriority(Map<String, dynamic> user, String eventType) {
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
    final hasSpecialty = specialties.contains(eventType);

    if (isPrimaryLocation) {
      return 4; // Prioridad más alta si es la ubicación principal exacta
    } else if (hasExactStateMatch) {
      return 3; // Prioridad alta si tiene coincidencia exacta del estado
    } else if (hasAllStatesMatch) {
      return 2; // Prioridad media si tiene "Todos los estados"
    } else if (hasSpecialty) {
      return 1; // Prioridad baja si tiene especialización para el evento
    }
    return 0; // Sin prioridad si no cumple con ninguno
  }
}

// Widget para envolver el SearchProvider en un ChangeNotifierProvider
class SearchProviderWidget extends StatelessWidget {
  final Widget child;

  const SearchProviderWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchProvider(),
      child: child, // El widget hijo que se pasa como parámetro
    );
  }
}
