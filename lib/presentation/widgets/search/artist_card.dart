// Fecha de creación: 26 de abril de 2025
// Autor: KingdomOfJames
//
// Descripción: Este widget representa una tarjeta que muestra la información básica de un artista,
// como su imagen de perfil, nombre y precio. La tarjeta permite que el usuario interactúe con ella,
// mostrando un cuadro de diálogo de vista previa del perfil del artista cuando se hace clic en ella.
// Además, incluye la funcionalidad de agregar o quitar el artista de favoritos mediante los botones de "me gusta" y "no me gusta".
//
// Recomendaciones:
// - Asegúrate de que la URL de la imagen del perfil (`profileImageUrl`) sea válida y accesible.
// - La tarjeta es bastante simple, pero asegúrate de que los datos como el precio estén bien formateados.
// - En caso de errores al cargar la imagen, se muestra un ícono predeterminado de persona.
// - La lógica de favoritos depende de un `FavoritesProvider` que debe estar correctamente configurado en el árbol de widgets.
//
// Características:
// - Muestra una imagen de perfil del artista, su nombre y su precio.
// - Permite al usuario interactuar con la tarjeta para ver más detalles sobre el perfil del artista.
// - Botones para agregar o quitar de favoritos al artista.
// - Utiliza `Provider` para manejar el estado de los favoritos y las vistas recientes del perfil.

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import '../artist_item.dart';
import 'package:live_music/presentation/resources/colors.dart';

class ArtistCard extends StatelessWidget {
  final String profileImageUrl; // URL de la imagen del perfil del artista
  final String name; // Nombre del artista
  final double price; // Precio del artista
  final String userId; // ID único del artista
  final bool userLiked; // Estado de si el usuario ha dado "me gusta" al artista
  final VoidCallback onLikeClick; // Acción cuando el usuario da "me gusta"
  final VoidCallback onUnlikeClick; // Acción cuando el usuario quita "me gusta"
  final VoidCallback
  toggleFavoritesDialog; // Acción para mostrar el diálogo de favoritos
  final String currentUserId; // ID del usuario actual
  final GoRouter goRouter; // Enrutador para navegación

  const ArtistCard({
    required this.profileImageUrl,
    required this.name,
    required this.price,
    required this.userId,
    required this.userLiked,
    required this.onLikeClick,
    required this.onUnlikeClick,
    required this.toggleFavoritesDialog,
    required this.currentUserId,
    required this.goRouter,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtener el esquema de colores de la aplicación
    final colorScheme = ColorPalette.getPalette(context);
    final favoritesViewModel = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );

    return GestureDetector(
      onTap: () {
        // Actualizar el ID del artista seleccionado y guardar el perfil reciente del usuario
        favoritesViewModel.updateSelectedArtistId(userId);
        favoritesViewModel.saveRecentlyViewedProfileToFirestore(
          currentUserId,
          userId,
        );
        favoritesViewModel.listenAndSaveRecentlyViewedProfiles(
          currentUserId: currentUserId,
        );

        // Mostrar un diálogo con la vista previa del perfil del artista
        showDialog(
          context: context,
          barrierDismissible:
              true, // Permite cerrar el diálogo al hacer clic fuera
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
              favoritesProvider: favoritesViewModel,
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4), // Margen horizontal
        decoration: BoxDecoration(
          color:
              colorScheme[AppStrings
                  .primaryColorLight], // Color de fondo de la tarjeta
          borderRadius: BorderRadius.circular(8), // Bordes redondeados
        ),
        child: AspectRatio(
          aspectRatio: 1, // Mantener la relación de aspecto cuadrada
          child: Column(
            children: [
              // Imagen de perfil del artista
              Expanded(
                flex: 72,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8), // Bordes redondeados superiores
                  ),
                  child: Image.network(
                    profileImageUrl, // Cargar la imagen desde la URL
                    fit:
                        BoxFit
                            .cover, // Ajustar la imagen para cubrir todo el espacio
                    width: double.infinity, // Ancho máximo
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          color:
                              Colors
                                  .grey[300], // Color de fondo en caso de error
                          child: const Icon(
                            Icons.person,
                            size: 40,
                          ), // Ícono predeterminado
                        ),
                  ),
                ),
              ),
              // Información del artista (nombre y precio)
              Expanded(
                flex: 28,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name, // Nombre del artista
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              colorScheme[AppStrings
                                  .secondaryColor], // Color secundario
                          fontFamily:
                              AppStrings.customFont, // Fuente personalizada
                        ),
                        maxLines: 1, // Limitar a una línea
                        overflow:
                            TextOverflow
                                .ellipsis, // Añadir elipsis si el texto es largo
                      ),
                      Text(
                        '\$$price', // Mostrar el precio con el símbolo de dólar
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              colorScheme[AppStrings.grayColor], // Color gris
                          fontFamily:
                              AppStrings.customFont, // Fuente personalizada
                        ),
                        maxLines: 1, // Limitar a una línea
                        overflow:
                            TextOverflow
                                .ellipsis, // Añadir elipsis si el texto es largo
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
