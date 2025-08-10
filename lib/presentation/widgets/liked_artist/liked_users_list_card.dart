/*
 * Fecha de creación: 2025-04-26
 * Autor: KingdomOfJames
 * Descripción: 
 *  La pantalla representa una tarjeta de usuarios "gustados" por el usuario, mostrando su imagen y nombre. 
 *  Se permite interactuar con los elementos de la tarjeta, mostrando información detallada del usuario cuando se hace clic. 
 *  En el caso de estar en modo edición, se permite eliminar un usuario de la lista de "gustados".
 * 
 * Recomendaciones: 
 *  - Asegúrate de manejar adecuadamente las imágenes de usuarios, como las URLs de las imágenes que podrían estar rotas o no disponibles.
 *  - Si estás trabajando con una lista muy larga de usuarios, considera optimizar el rendimiento al cargar las imágenes de manera eficiente.
 * 
 * Características:
 *  - Soporte para visualización de la lista de usuarios "gustados".
 *  - Modo edición para eliminar usuarios.
 *  - Manejo de imágenes con fallback en caso de error al cargarlas.
 *  - Integración con el estado global a través de `FavoritesProvider`.
 */

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import '../../../data/sources/local/internal_data_base.dart';

class LikedUsersListCard extends StatelessWidget {
  final LikedUsersList likedUsersList; // Lista de usuarios "gustados".
  final bool isEditMode; // Modo de edición activado o desactivado.
  final Function(LikedUsersList)
  onDeleteClick; // Función para eliminar un usuario.
  final Function() onClick; // Función para manejar el clic en la tarjeta.
  final double imageSize; // Tamaño de la imagen de usuario.

  const LikedUsersListCard({
    Key? key,
    required this.likedUsersList,
    required this.isEditMode,
    required this.onDeleteClick,
    required this.onClick,
    required this.imageSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtiene el esquema de colores utilizado en la aplicación.
    final colorScheme = ColorPalette.getPalette(context);

    // Obtiene el provider de favoritos para gestionar la lista.
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );

    // Altura del nombre, proporcional al tamaño de la imagen.
    final double nameHeight = imageSize * 0.2;

    // Llama a `getProfilesByIds` para obtener los perfiles de los usuarios "gustados" por ID.
    if (likedUsersList.likedUsersList.isNotEmpty) {
      favoritesProvider.getProfilesByIds(likedUsersList.likedUsersList);
    }

    return GestureDetector(
      onTap: () {
        // Guarda la lista seleccionada en el provider.
        favoritesProvider.setSelectedList(likedUsersList);
        // Ejecuta la función proporcionada al hacer clic.
        onClick();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contenedor para la imagen del usuario.
          Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              color: colorScheme[AppStrings.primaryColor],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Imagen del usuario, con manejo de errores si no se puede cargar.
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    likedUsersList.imageUrl,
                    fit: BoxFit.cover,
                    width: imageSize,
                    height: imageSize,
                    errorBuilder:
                        (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.error_outline,
                            color: colorScheme[AppStrings.secondaryColor],
                          ),
                        ),
                  ),
                ),
                // Botón de eliminar si está en modo edición.
                if (isEditMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onDeleteClick(likedUsersList),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close,
                          color: colorScheme[AppStrings.essentialColor],
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Contenedor para el nombre del usuario.
          Container(
            width: imageSize,
            height: nameHeight,
            decoration: BoxDecoration(
              color: colorScheme[AppStrings.primaryColor],
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              likedUsersList.name,
              style: TextStyle(
                fontSize: 15,
                color: colorScheme[AppStrings.secondaryColor],
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
