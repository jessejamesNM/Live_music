/*
Fecha de creación: 26 de abril de 2025
Autor: KingdomOfJames

Descripción general:
El widget 'ArtistGrid' es un contenedor de tipo `GridView` que organiza y muestra una lista de perfiles de artistas (o usuarios) en forma de una cuadrícula. Este widget permite mostrar las tarjetas de perfil de los artistas, con la posibilidad de agregar o quitar artistas de la lista de favoritos mediante interacciones con los botones de "like" y "unlike".

Características:
- Se utiliza un `GridView.builder` para mostrar los perfiles en una cuadrícula.
- Los perfiles se obtienen de una lista genérica, `List<T> profiles`, lo que permite que el widget sea reutilizable para diferentes tipos de objetos que extiendan `ProfileBase`.
- Funcionalidad para editar la lista de favoritos, añadir o eliminar perfiles.
- Puede estar en modo de edición (`isEditMode`), lo que habilita o deshabilita ciertas acciones como eliminar usuarios de los favoritos.

Recomendaciones:
- Asegúrate de que `profiles` contenga datos válidos para evitar errores visuales.
- Para mejorar la interacción, se podrían añadir animaciones cuando se agregue o elimine un perfil de favoritos.
- Asegúrate de que `goRouter` esté configurado adecuadamente para permitir la navegación sin errores al seleccionar un artista.

Notas adicionales:
- Este widget hace uso del patrón `ValueKey` para asegurar que cada tarjeta de artista sea única dentro del `GridView`.
*/

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import '../../../data/model/liked_artist/profile_base.dart';
import 'artis_profile_card.dart';

/// `ArtistGrid` es un widget reutilizable para mostrar una lista de artistas en formato de cuadrícula.
class ArtistGrid<T extends ProfileBase> extends StatelessWidget {
  // Parámetros necesarios para la funcionalidad del widget
  final GoRouter goRouter; // Proveedor de la ruta para la navegación
  final FavoritesProvider
  favoritesProvider; // Proveedor de la lógica de favoritos
  final List<T> profiles; // Lista de perfiles de artistas
  final String currentUserId; // ID del usuario actual
  final VoidCallback
  toggleFavoritesDialog; // Función para mostrar el diálogo de favoritos
  final bool isEditMode; // Indica si está en modo edición
  final Future<void> Function({
    required String currentUserId, // ID del usuario actual
    required String userIdToRemove, // ID del usuario a eliminar de favoritos
  })
  removeUserFromFavoritesList; // Función para eliminar un perfil de la lista de favoritos

  // Constructor del widget
  ArtistGrid({
    required this.goRouter,
    required this.favoritesProvider,
    required this.profiles,
    required this.currentUserId,
    required this.toggleFavoritesDialog,
    required this.isEditMode,
    required this.removeUserFromFavoritesList,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8), // Espaciado interno de la cuadrícula
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Dos columnas en la cuadrícula
        crossAxisSpacing: 8, // Espaciado entre las columnas
        mainAxisSpacing: 8, // Espaciado entre las filas
      ),
      itemCount: profiles.length, // Número de perfiles a mostrar
      itemBuilder: (context, i) {
        final p =
            profiles[i]; // Obtenemos el perfil del artista en la posición i
        return ArtistProfileCard(
          key: ValueKey(
            p.userId,
          ), // Usamos el ID del usuario como clave única para cada tarjeta
          profileImageUrl:
              p.profileImageUrl, // URL de la imagen de perfil del artista
          name: p.name, // Nombre del artista
          price: p.price, // Precio del artista
          userId: p.userId, // ID del usuario
          userLiked: p.userLiked, // Estado de "me gusta" del usuario
          onLikeClick:
              () {}, // Función vacía para el clic en "like" (aún no implementado)
          onUnlikeClick:
              () => removeUserFromFavoritesList(
                currentUserId: currentUserId, // El ID del usuario actual
                userIdToRemove:
                    p.userId, // El ID del usuario a eliminar de favoritos
              ),
          toggleFavoritesDialog:
              toggleFavoritesDialog, // Función para mostrar el diálogo de favoritos
          isEditMode: isEditMode, // Determina si está en modo edición
          currentUserId: currentUserId, // El ID del usuario actual
          goRouter: goRouter, // Proveedor de navegación
          favoritesProvider: favoritesProvider, // Proveedor de favoritos
        );
      },
    );
  }
}
