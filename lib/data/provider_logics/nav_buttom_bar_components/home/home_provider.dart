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

class HomeProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> artistsForHome = [];
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  void getUsersByCountry(
    String currentUserId,
    String currentCountry,
    String currentState,
    List<String> typeEvents,
    String? selectedService,
    Function(List<String>) onComplete,
  ) {
    firestore
        .collection('users')
        .get()
        .then((querySnapshot) async {
          List<Map<String, dynamic>> userList = [];

          for (var document in querySnapshot.docs) {
            final data = document.data();
            final userId = document.id;

            final String country = data['country'] ?? '';
            final String state = data['state'] ?? '';
            final List<String> countries = List<String>.from(
              data['countries'] ?? [],
            );
            final List<String> states = List<String>.from(data['states'] ?? []);
            final List<String> events = List<String>.from(
              data['typeEvents'] ?? [],
            );
            final double userValue =
                (data['userValue'] as num?)?.toDouble() ?? 0.0;

            final bool countryMatches =
                country == currentCountry || countries.contains(currentCountry);
            final userType = data['userType'] ?? '';
            final expectedUserType = _getUserTypeForService(selectedService);
            final bool serviceMatches =
                selectedService == null || userType == expectedUserType;

            final int eventPriority =
                typeEvents.isEmpty
                    ? 0
                    : events
                        .where((event) => typeEvents.contains(event))
                        .length;

            if (countryMatches && serviceMatches) {
              userList.add({
                'id': userId,
                'state': state,
                'states': states,
                'eventPriority': eventPriority,
                'userValue': userValue,
              });
            }
          }

          userList.sort((a, b) {
            final stateAMatch =
                a['state'] == currentState ||
                (a['states'] as List).contains(currentState);
            final stateBMatch =
                b['state'] == currentState ||
                (b['states'] as List).contains(currentState);

            if (stateAMatch != stateBMatch) {
              return stateBMatch ? 1 : -1;
            }

            if (a['eventPriority'] != b['eventPriority']) {
              return (b['eventPriority'] as int).compareTo(
                a['eventPriority'] as int,
              );
            }

            return (b['userValue'] as double).compareTo(
              a['userValue'] as double,
            );
          });

          final List<String> userIds =
              userList.map((user) => user['id'] as String).take(10).toList();
          await loadArtists(currentUserId, userIds);
          onComplete(userIds);
        })
        .catchError((error) {
          onComplete([]);
        });
  }

  Future<void> loadArtists(String currentUserId, List<String> ids) async {
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
          if (price < lowestPrice) lowestPrice = price;

          if (subServiceData['imageList'] is List) {
            final images = List<String>.from(subServiceData['imageList'] ?? []);
            allImages.addAll(images);
          }
        }

        if (lowestPrice == double.infinity) continue;

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
        // Manejar error silenciosamente
      }
    }

    artistsForHome
      ..clear()
      ..addAll(updatedServices);

    notifyListeners();
  }

  Future<bool> checkIfUserLiked(String currentUserId, String artistId) async {
    try {
      final userDoc =
          await firestore.collection('users').doc(currentUserId).get();
      final likedUsers = List<String>.from(userDoc.data()?['likedUsers'] ?? []);
      return likedUsers.contains(artistId);
    } catch (e) {
      return false;
    }
  }

  String? _getUserTypeForService(String? service) {
    switch (service) {
      case 'Música':
        return 'artist';
      case 'Repostería':
        return 'bakery';
      case 'Local':
        return 'place';
      case 'Decoración':
        return 'decoration';
      case 'Mueblería':
        return 'furniture';
      case 'Entretenimiento':
        return 'entertainment';
      default:
        return null;
    }
  }
}
