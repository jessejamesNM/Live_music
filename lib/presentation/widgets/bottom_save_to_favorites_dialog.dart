// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción:
// Este widget representa un cuadro de diálogo que aparece desde la parte inferior de la pantalla,
// permitiendo al usuario agregar un artista a una lista de favoritos existente o crear una nueva lista.
// Muestra una lista horizontal de listas de usuarios favoritos, y proporciona opciones para seleccionar
// una lista y agregar al usuario a esa lista. El cuadro de diálogo se anima para deslizarse desde abajo.
// Recomendaciones:
// - Este componente es ideal para manejar interacciones rápidas con la UI, como agregar elementos a favoritos.
// - Asegúrate de que el `FavoritesProvider` esté correctamente configurado para manejar los flujos de datos.
// Características:
// - Dialog con animación de deslizamiento desde abajo.
// - Lista horizontal de listas de usuarios favoritos con la opción de seleccionar y agregar un usuario.
// - Opción para crear una nueva lista de favoritos.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import '../../data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import '../../data/sources/local/internal_data_base.dart';
import 'liked_artist/liked_users_list_card.dart';
import 'package:live_music/presentation/resources/colors.dart';

class BottomSaveToFavoritesDialog extends StatefulWidget {
  final VoidCallback onDismiss;
  final VoidCallback onCreateNewList;
  final FavoritesProvider favoritesProvider;
  final String userIdToSave;
  final Function(LikedUsersList) onUserAddedToList;
  final VoidCallback onLikeClick;

  const BottomSaveToFavoritesDialog({
    Key? key,
    required this.onDismiss,
    required this.onCreateNewList,
    required this.favoritesProvider,
    required this.userIdToSave,
    required this.onUserAddedToList,
    required this.onLikeClick,
  }) : super(key: key);

  @override
  State<BottomSaveToFavoritesDialog> createState() =>
      _BottomSaveToFavoritesDialogState();
}

class _BottomSaveToFavoritesDialogState
    extends State<BottomSaveToFavoritesDialog> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(
        () => _visible = true,
      ); // Anima la visibilidad del diálogo después de que la vista esté construida
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // Tamaño de la pantalla
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtiene los colores definidos para la app

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      alignment:
          Alignment
              .bottomCenter, // El diálogo se alinea en la parte inferior de la pantalla
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            GestureDetector(
              onTap:
                  widget.onDismiss, // Detecta un toque para cerrar el diálogo
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ), // Fondo oscuro con opacidad
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSlide(
                offset:
                    _visible
                        ? Offset.zero
                        : const Offset(
                          0,
                          1,
                        ), // Controla la animación de deslizamiento
                curve: Curves.easeOutCubic,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: size.width,
                  height:
                      size.height *
                      0.42, // Define la altura del diálogo (42% de la pantalla)
                  decoration: BoxDecoration(
                    color:
                        colorScheme[AppStrings
                            .primaryColor], // Fondo del diálogo
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(
                        28,
                      ), // Bordes redondeados en la parte superior
                      topRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                AppStrings.saveToFavorites,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme[AppStrings.secondaryColor],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: 28,
                                  color: colorScheme[AppStrings.secondaryColor],
                                ),
                                onPressed:
                                    widget
                                        .onDismiss, // Cierra el diálogo cuando se hace clic en el ícono de cerrar
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Consumer<FavoritesProvider>(
                          // Escucha el estado del proveedor de favoritos
                          builder: (context, provider, _) {
                            return StreamBuilder<List<LikedUsersList>>(
                              stream:
                                  provider
                                      .likedUsersLists, // Escucha la lista de usuarios favoritos
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child:
                                        CircularProgressIndicator(), // Muestra un indicador de carga mientras espera los datos
                                  );
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      AppStrings
                                          .errorLoadingLists, // Muestra un error si no se pueden cargar las listas
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.red,
                                      ),
                                    ),
                                  );
                                }

                                final lists = snapshot.data ?? [];
                                if (lists.isEmpty) {
                                  return Center(
                                    child: Text(
                                      AppStrings
                                          .noFavoriteLists, // Mensaje cuando no hay listas de favoritos
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            colorScheme[AppStrings
                                                .secondaryColor],
                                      ),
                                    ),
                                  );
                                }

                                return SizedBox(
                                  height: 170,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    scrollDirection:
                                        Axis.horizontal, // Lista horizontal
                                    itemCount: lists.length,
                                    separatorBuilder:
                                        (_, __) => const SizedBox(width: 12),
                                    itemBuilder: (context, i) {
                                      final list = lists[i];
                                      return LikedUsersListCard(
                                        likedUsersList:
                                            list, // Muestra cada lista de usuarios favoritos
                                        isEditMode: false,
                                        onDeleteClick:
                                            (
                                              _,
                                            ) {}, // No se implementa la eliminación
                                        onClick: () {
                                          widget
                                              .onLikeClick(); // Llama a la función de "like"
                                          provider.addUserToLikedList(
                                            list.listId,
                                            widget
                                                .userIdToSave, // Agrega el usuario a la lista seleccionada
                                            () {
                                              widget
                                                  .onDismiss(); // Cierra el diálogo al agregar el usuario
                                              widget.onUserAddedToList(list);
                                            },
                                            (e) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '${AppStrings.error}: ${e.toString()}',
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        imageSize: 150,
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              widget
                                  .onDismiss(); // Cierra el diálogo cuando se crea una nueva lista
                              widget
                                  .onCreateNewList(); // Llama a la función para crear una nueva lista
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  colorScheme[AppStrings.essentialColor],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              AppStrings.createNewList,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme[AppStrings.secondaryColor],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
