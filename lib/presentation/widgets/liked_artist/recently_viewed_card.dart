/*
Fecha de creación: 26 de abril de 2025
Autor: KingdomOfJames

Descripción general:
El widget `RecentlyViewedCard` muestra una tarjeta interactiva que contiene la imagen del perfil del usuario recientemente visto. Si no hay un perfil reciente, se muestra un ícono de "repetir" indicando que no hay contenido disponible. La tarjeta se utiliza dentro de la interfaz para mostrar al usuario su perfil más reciente y permite navegar a una lista de perfiles recientemente vistos.

Características:
- Muestra la imagen del perfil del usuario más reciente, utilizando la librería `CachedNetworkImage` para manejar imágenes en caché.
- Si no hay perfiles recientes, muestra un ícono de "repetir".
- Utiliza un `StreamBuilder` para escuchar actualizaciones de los perfiles recientemente vistos.
- Navegación al hacer clic en la tarjeta, utilizando `GoRouter` para redirigir al usuario a la pantalla de "recently viewed".

Recomendaciones:
- Asegúrate de que los perfiles recientemente vistos estén correctamente actualizados en el proveedor de favoritos (`FavoritesProvider`).
- Si se agregan más funcionalidades en el futuro, como la opción de eliminar perfiles de la lista de recientemente vistos, sería conveniente añadir un botón para ello.
- Considera mejorar la accesibilidad de la interfaz al añadir descripciones de imágenes para usuarios con discapacidades visuales.

Notas adicionales:
- El color de fondo y los estilos de la tarjeta están configurados a partir del esquema de colores proporcionado por la aplicación.
- Asegúrate de tener en cuenta el rendimiento en caso de que la lista de perfiles recientemente vistos crezca significativamente.

*/

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import 'package:live_music/presentation/resources/colors.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import '../../../data/sources/local/internal_data_base.dart';

class RecentlyViewedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final colorScheme = ColorPalette.getPalette(context);

    return StreamBuilder<List<RecentlyViewedProfile>>(
      stream: favoritesProvider.recentlyViewedProfiles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final recentProfiles = snapshot.data ?? [];
        final mostRecent =
            recentProfiles.isNotEmpty ? recentProfiles.first : null;

        return GestureDetector(
          onTap: () {
            context.push(AppStrings.recentlyViewedScreenRoutes);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      color: colorScheme[AppStrings.primaryColorLight],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: colorScheme[AppStrings.primaryColorLight]!
                                .withOpacity(0.4),
                            child:
                                mostRecent == null
                                    ? Center(
                                      child: Icon(
                                        Icons.replay_outlined,
                                        size: 60,
                                        color:
                                            colorScheme[AppStrings
                                                .essentialColor],
                                      ),
                                    )
                                    : CachedNetworkImage(
                                      imageUrl: mostRecent.profileImageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.recentlyViewedTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme[AppStrings.secondaryColor],
                    fontFamily: null, // Usa fuente por defecto del sistema
                    decoration:
                        TextDecoration.none, // Asegura que no tenga subrayado
                    shadows: [], // Elimina sombras heredadas
                    backgroundColor: Colors.transparent, // Sin fondo raro
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
