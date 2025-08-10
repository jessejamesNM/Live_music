/*
================================================================================
Fecha de creación: 26 de abril de 2025
Autor: KingdomOfJames

Descripción:
Pantalla "ArtistProfileCard" que representa la tarjeta visual de un artista,
mostrando su imagen de perfil, nombre y precio. Permite a los usuarios ver una
vista previa detallada al tocar la tarjeta, y en modo edición, eliminar artistas
de una lista de favoritos o administración.

Características:
- Muestra imagen, nombre y precio del artista.
- Permite abrir un "ProfilePreviewCard" al hacer tap.
- Integra un botón de eliminación si el modo edición está activo.
- Diseño responsivo y manejo de errores en la carga de imágenes.
- Integración con proveedor de favoritos para actualizar interacciones.

Recomendaciones:
- Añadir placeholders de carga para imágenes más suaves.
- Mejorar la experiencia offline manejando mejor los errores de red.
- Considerar un botón de "like" directamente desde la tarjeta.

================================================================================
*/

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/widgets/artist_item.dart';

/// Componente que muestra la tarjeta del perfil de un artista
class ArtistProfileCard extends StatelessWidget {
  final String profileImageUrl;
  final String name;
  final double price;
  final String userId;
  final bool userLiked;
  final VoidCallback onLikeClick;
  final VoidCallback onUnlikeClick;
  final VoidCallback toggleFavoritesDialog;
  final bool isEditMode;
  final String currentUserId;
  final GoRouter goRouter;
  final FavoritesProvider favoritesProvider;

  const ArtistProfileCard({
    required this.profileImageUrl,
    required this.name,
    required this.price,
    required this.userId,
    required this.userLiked,
    required this.onLikeClick,
    required this.onUnlikeClick,
    required this.toggleFavoritesDialog,
    required this.isEditMode,
    required this.currentUserId,
    required this.goRouter,
    required this.favoritesProvider,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            favoritesProvider.updateSelectedArtistId(userId);
            favoritesProvider.saveRecentlyViewedProfileToFirestore(
              currentUserId,
              userId,
            );
            favoritesProvider.listenAndSaveRecentlyViewedProfiles(
              currentUserId: currentUserId,
            );

            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) {
                return ProfilePreviewCard(
                  profileImageUrl: profileImageUrl,
                  name: name,
                  price: price,
                  userId: userId,
                  onDismiss: () => Navigator.of(context).pop(),
                  onLikeClick: onLikeClick,
                  onUnlikeClick: onUnlikeClick,
                  toggleFavoritesDialog: toggleFavoritesDialog,
                  goRouter: goRouter,
                  currentUserId: currentUserId,
                  favoritesProvider: favoritesProvider,
                );
              },
            );
          },
          child: Container(
            width: 165,
            height: 165,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme[AppStrings.primaryColorLight],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 76,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 24,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 14.2,
                            color: colorScheme[AppStrings.secondaryColor],
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '"\$$price"',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme[AppStrings.grayColor],
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isEditMode)
          Positioned(
            top: 4,
            left: 4,
            child: GestureDetector(
              onTap: onUnlikeClick,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme[AppStrings.primaryColor],
                  border: Border.all(
                    color: colorScheme[AppStrings.essentialColor] ?? Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: colorScheme[AppStrings.essentialColor],
                ),
              ),
            ),
          ),
      ],
    );
  }
}