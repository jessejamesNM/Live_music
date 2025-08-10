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

/// Widget que muestra una cuadrícula de artistas
class ArtistGrid<T extends ProfileBase> extends StatelessWidget {
  final GoRouter goRouter;
  final FavoritesProvider favoritesProvider;
  final List<T> profiles;
  final String currentUserId;
  final VoidCallback toggleFavoritesDialog;
  final bool isEditMode;
  final Function({
    required String currentUserId,
    required String userIdToRemove,
  }) removeUserFromFavoritesList;

  const ArtistGrid({
    required this.goRouter,
    required this.favoritesProvider,
    required this.profiles,
    required this.currentUserId,
    required this.toggleFavoritesDialog,
    required this.isEditMode,
    required this.removeUserFromFavoritesList,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('[ArtistGrid] Building grid with ${profiles.length} profiles');
    debugPrint('[ArtistGrid] Current user ID: $currentUserId');
    debugPrint('[ArtistGrid] Edit mode: $isEditMode');

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        
        // Log detallado de cada perfil
        debugPrint('[ArtistGrid] Profile at index $index:');
        debugPrint('  - User ID: ${profile.userId}');
        debugPrint('  - Name: ${profile.name}');
        debugPrint('  - Price: ${profile.price}');
        debugPrint('  - Image URL: ${profile.profileImageUrl}');
        debugPrint('  - Liked: ${profile.userLiked}');
        debugPrint('  - Timestamp: ${profile.timestamp}');

        return ArtistProfileCard(
          profileImageUrl: profile.profileImageUrl,
          name: profile.name,
          price: profile.price,
          userId: profile.userId,
          userLiked: profile.userLiked,
          onLikeClick: () {
            debugPrint('[ArtistGrid] Like clicked for user ${profile.userId}');
            favoritesProvider.onLikeClick(profile.userId, currentUserId);
          },
          onUnlikeClick: () {
            debugPrint('[ArtistGrid] Unlike clicked for user ${profile.userId}');
            favoritesProvider.onUnlikeClick(profile.userId);
          },
          toggleFavoritesDialog: () {
            debugPrint('[ArtistGrid] Favorites dialog toggled');
            toggleFavoritesDialog();
          },
          isEditMode: isEditMode,
          currentUserId: currentUserId,
          goRouter: goRouter,
          favoritesProvider: favoritesProvider,
        );
      },
    );
  }
}