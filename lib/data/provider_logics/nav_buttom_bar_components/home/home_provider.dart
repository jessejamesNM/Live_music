/*
  Fecha de creación: 2025-04-26
  Autor: KingdomOfJames

  Descripción:
  Esta clase `MessagesProvider` gestiona la lógica de mensajes y la interacción con Firebase en una aplicación de mensajería. 
  Proporciona funcionalidades como la actualización de días ocupados de un usuario, la carga de imágenes de perfil, la gestión de mensajes y la verificación de bloqueo entre usuarios. 
  También incluye métodos para gestionar la ubicación del usuario y la visualización de la misma en la interfaz. 
  Se utiliza `ValueNotifier` para gestionar el estado reactivo en la interfaz de usuario, como la visibilidad de un perfil o la existencia de mensajes.

  Recomendaciones:
  - Optimizar las consultas a Firebase para mejorar el rendimiento, especialmente cuando se manejan grandes cantidades de datos (por ejemplo, mensajes).
  - Considerar implementar más validaciones y manejo de errores para garantizar una experiencia de usuario robusta.
  - Si el uso de imágenes en los mensajes es frecuente, se podría mejorar la gestión de la carga y descarga de archivos para reducir tiempos de espera.

  Características:
  - Gestión de mensajes y usuarios en tiempo real con Firebase.
  - Soporte para carga y visualización de imágenes de perfil.
  - Funcionalidades avanzadas como bloqueo y desbloqueo de usuarios.
  - Implementación de ubicación en tiempo real y su visualización en un mapa.
  - Soporte para mantener el estado reactivo de los mensajes y otros datos relacionados.
*/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Provider que maneja la carga y actualización de artistas en la pantalla principal
class HomeProvider extends ChangeNotifier {
  /// Lista de artistas cargados para mostrar en el Home
  final List<Map<String, dynamic>> artistsForHome = [];

  /// Instancia de Firestore para consultas
  final FirebaseFirestore firestore = FirebaseFirestore.instance;


  /// Obtiene usuarios que sean artistas según país, estado y géneros seleccionados
  void getUsersByCountry(
    String currentUserId,
    String currentCountry,
    String currentState,
    List<String> selectedGenres,
    Function(List<String>) onComplete,
  ) {
    firestore
        .collection('users')
        .get()
        .then((querySnapshot) async {
          List<Map<String, dynamic>> userList = [];

          for (var document in querySnapshot.docs) {
            final data = document.data();

            // Validaciones iniciales: solo continuar si el usuario es artista
            if (data['userType'] != 'artist') continue;

            // Validar campos necesarios para mostrar artista
            if (!(data.containsKey('name') &&
                data['name']?.toString().trim().isNotEmpty == true))
              continue;
            if (!(data.containsKey('profileImageUrl') &&
                data['profileImageUrl']?.toString().trim().isNotEmpty == true))
              continue;
            if (!(data.containsKey('nickname') &&
                data['nickname']?.toString().trim().isNotEmpty == true))
              continue;

            // Extraer datos relevantes
            final List<String> genres = List<String>.from(data['genres'] ?? []);
            final String country = data['country'] ?? '';
            final String state = data['state'] ?? '';
            final List<String> countries = List<String>.from(
              data['countries'] ?? [],
            );
            final List<String> states = List<String>.from(data['states'] ?? []);
            final double userValue =
                (data['userValue'] is num)
                    ? (data['userValue'] as num).toDouble()
                    : 0.0;

            // Validar si el artista coincide por país y géneros
            final bool countryMatches =
                country == currentCountry || countries.contains(currentCountry);
            final bool genreMatches = genres.any(
              (genre) => selectedGenres.contains(genre),
            );

            if (countryMatches && genreMatches) {
              userList.add({
                'id': document.id,
                'genres': genres,
                'country': country,
                'state': state,
                'userValue': userValue,
                'countries': countries,
                'states': states,
              });
            }
          }

          // Ordenar artistas por prioridad: mismo estado > estado listado > valor de usuario
          userList.sort((a, b) {
            final String stateA = a['state'];
            final List<String> statesA = List<String>.from(a['states'] ?? []);
            final String stateB = b['state'];
            final List<String> statesB = List<String>.from(b['states'] ?? []);

            int priorityA =
                (stateA == currentState || statesA.contains(currentState))
                    ? (stateA == currentState ? 2 : 1)
                    : 0;
            int priorityB =
                (stateB == currentState || statesB.contains(currentState))
                    ? (stateB == currentState ? 2 : 1)
                    : 0;

            if (priorityA != priorityB) {
              return priorityB - priorityA; // Mayor prioridad primero
            }
            return (b['userValue'] as double).compareTo(
              a['userValue'] as double,
            );
          });

          // Tomar los primeros 10 artistas
          final List<String> userIds =
              userList.map((user) => user['id'] as String).take(10).toList();

          // Cargar información detallada de los artistas seleccionados
          await loadArtists(currentUserId, userIds);

          // Devolver IDs de artistas al completar
          onComplete(userIds);
        })
        .catchError((error) {
          // Si falla la carga, completar con lista vacía
          onComplete([]);
        });
  }

  /// Carga la información de los artistas dado un listado de IDs
  Future<void> loadArtists(String currentUserId, List<String> ids) async {
    final List<Map<String, dynamic>> updatedArtists = [];
print("se ejecuto esta cosa aaaaaaa /// inicio");
    for (final artistId in ids) {
      try {
        final artistDocument =
            await firestore.collection('users').doc(artistId).get();
        final data = artistDocument.data();

        if (data == null) continue;

        // Validar que tenga los campos necesarios
        if (!(data.containsKey('name') &&
            data['name']?.toString().trim().isNotEmpty == true))
          continue;
        if (!(data.containsKey('profileImageUrl') &&
            data['profileImageUrl']?.toString().trim().isNotEmpty == true))
          continue;
        if (!(data.containsKey('nickname') &&
            data['nickname']?.toString().trim().isNotEmpty == true))
          continue;

        // Agregar ID y si el usuario ya le dio "like" al artista
        data['userId'] = artistId;
        data['userLiked'] = await checkIfUserLiked(currentUserId, artistId);

        updatedArtists.add(data);
       
      } catch (_) {
        // Ignorar errores individuales al cargar artista
      }
    }

    // Actualizar la lista y notificar cambios
    artistsForHome
      ..clear()
      ..addAll(updatedArtists);
    notifyListeners();
    }

  /// Verifica si el usuario actual ya ha dado "like" al artista
  Future<bool> checkIfUserLiked(String currentUserId, String artistId) async {
    try {
      final userDoc =
          await firestore.collection('users').doc(currentUserId).get();
      final likedUsers = List<String>.from(userDoc.data()?['likedUsers'] ?? []);
      return likedUsers.contains(artistId);
    } catch (_) {
      // Si hay error, asumir que no ha dado like
      return false;
    }
  }
}
