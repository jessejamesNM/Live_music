/// Fecha de creación: 2025-04-26
/// Autor: KingdomOfJames
/// Descripción:
/// Widget que representa un elemento de artista en una lista.
/// Muestra la imagen, nombre y precio del artista, y maneja interacciones como dar y quitar "likes",
/// agregar a favoritos, y navegar hacia un perfil extendido del artista.
///
/// Recomendaciones:
/// - Asegúrate de que los datos del artista (como imagen y nombre) estén correctamente formateados
///   y disponibles antes de pasarlos a este widget.
/// - El uso de `GestureDetector` permite una experiencia interactiva para el usuario, por lo que es
///   importante que las acciones asociadas a cada artista estén bien implementadas y sean eficientes.
///
/// Características:
/// - Muestra una imagen de perfil del artista con un tamaño ajustable.
/// - Presenta el nombre y el precio por hora de un artista.
/// - Permite agregar o quitar artistas de favoritos.
/// - Despliega un diálogo con más detalles al tocar un artista.
/// - Proporciona botones para interactuar con el artista, como contacto o ver el perfil completo.
///
import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/widgets/bottom_list_creator_dialog.dart';
import 'package:live_music/presentation/widgets/bottom_save_to_favorites_dialog.dart';
import 'package:live_music/presentation/widgets/save_message.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import '../../data/provider_logics/user/user_provider.dart';
import '../../data/provider_logics/user/review_provider.dart';
import '../../data/sources/local/internal_data_base.dart';
import 'package:live_music/presentation/resources/colors.dart';

class ArtistItem extends StatelessWidget {
  final Map<String, dynamic> artist;
  final ReviewProvider reviewProvider;
  final VoidCallback onLikeClick;
  final VoidCallback onUnlikeClick;
  final FavoritesProvider favoritesProvider;
  final String currentUserId;
  final VoidCallback toggleFavoritesDialog;
  final UserProvider userProvider;
  final GoRouter goRouter;

  const ArtistItem({
    required this.artist,
    required this.reviewProvider,
    required this.onLikeClick,
    required this.onUnlikeClick,
    required this.favoritesProvider,
    required this.currentUserId,
    required this.toggleFavoritesDialog,
    required this.userProvider,
    required this.goRouter,
  });

  T safeCast<T>(dynamic value, T defaultValue) {
    if (value == null) return defaultValue;
    try {
      return (value is T) ? value : defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    final String profileImageUrl = safeCast<String>(
      artist[AppStrings.profileImageUrlField],
      'https://via.placeholder.com/245',
    );

    final String name = safeCast<String>(
      artist[AppStrings.nameField],
      'Nombre no disponible',
    );

    final double price =
        safeCast<num>(artist[AppStrings.priceField], 0.0).toDouble();

    final String userId = safeCast<String>(
      artist[AppStrings.userIdField],
      'default_user_id',
    );

    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: GestureDetector(
        onTap: () {
          userProvider.setOtherUserId(userId);
          favoritesProvider.updateSelectedArtistId(userId);
          favoritesProvider.saveRecentlyViewedProfileToFirestore(
            currentUserId,
            userId,
          );
          favoritesProvider.listenAndSaveRecentlyViewedProfiles(
            currentUserId: currentUserId,
          );
          goRouter.push(AppStrings.servicePreviewScreen);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                profileImageUrl,
                width: 245,
                height: 245,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      width: 245,
                      height: 245,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey[600],
                      ),
                    ),
              ),
            ),
            SizedBox(
              width: 245, // Mismo ancho que la imagen
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 4.0,
                  top: 6.0,
                  bottom: 6.0,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 25, // Tamaño máximo inicial
                      fontWeight: FontWeight.bold,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// Diálogo que muestra una vista previa extendida del perfil del artista
class ProfilePreviewCard extends StatefulWidget {
  final String profileImageUrl; // URL de la imagen de perfil
  final String name; // Nombre del artista
  final double price; // Precio por hora
  final String userId; // ID del usuario/artista
  final VoidCallback onDismiss; // Callback para cerrar el diálogo
  final VoidCallback onLikeClick; // Callback para like
  final VoidCallback onUnlikeClick; // Callback para quitar like
  final VoidCallback
  toggleFavoritesDialog; // Callback para diálogo de favoritos
  final GoRouter goRouter; // Router para navegación
  final String currentUserId; // ID del usuario actual
  final FavoritesProvider favoritesProvider; // Proveedor de favoritos

  const ProfilePreviewCard({
    required this.profileImageUrl,
    required this.name,
    required this.price,
    required this.userId,
    required this.onDismiss,
    required this.onLikeClick,
    required this.onUnlikeClick,
    required this.toggleFavoritesDialog,
    required this.goRouter,
    required this.currentUserId,
    required this.favoritesProvider,
    Key? key,
  }) : super(key: key);

  @override
  _ProfilePreviewCardState createState() => _ProfilePreviewCardState();
}

class _ProfilePreviewCardState extends State<ProfilePreviewCard> {
  bool showSaveMessage = false; // Mostrar mensaje de guardado
  LikedUsersList? selectedList; // Lista de favoritos seleccionada
  bool showBottomSaveDialog = false; // Mostrar diálogo de guardado
  bool showBottomFavoritesListCreatorDialog =
      false; // Mostrar creador de listas
  bool showConfirmRemoveDialog = false; // Mostrar confirmación de eliminación

  @override
  void initState() {
    super.initState();

    // Obtener datos después de que el widget se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reviewProvider = Provider.of<ReviewProvider>(
        context,
        listen: false,
      );
      final favoritesProvider = Provider.of<FavoritesProvider>(
        context,
        listen: false,
      );
      final currentUserId = widget.currentUserId;

      // Obtener valoración promedio y estado de favoritos
      reviewProvider.getAverageStars(widget.userId);
      favoritesProvider.startLikedUsersListener(currentUserId, widget.userId);
    });
  }

  @override
  void dispose() {
    // Detener listeners al destruir el widget
    widget.favoritesProvider.stopLikedUsersListener(widget.userId);
    super.dispose();
  }

  /// Maneja la acción de guardar/eliminar de favoritos
  void handleSave() {
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );
    final likedLists = favoritesProvider.likedUsersListsValue;
    final isLiked = favoritesProvider.isUserLiked(widget.userId);

    if (isLiked) {
      // Mostrar confirmación si ya está en favoritos
      setState(() {
        showConfirmRemoveDialog = true;
      });
    } else {
      if (likedLists.isEmpty) {
        // Mostrar creador de listas si no hay listas
        setState(() {
          showBottomFavoritesListCreatorDialog = true;
        });
      } else if (likedLists.length == 1) {
        // Guardar directamente si solo hay una lista
        final list = likedLists.first;
        favoritesProvider.addUserToList(list.listId, widget.userId);
        setState(() {
          selectedList = list;
          showSaveMessage = true;
        });
      } else {
        // Mostrar diálogo de selección si hay múltiples listas
        setState(() {
          showBottomSaveDialog = true;
        });
      }
    }
  }

  /// Callback cuando se añade un usuario a una lista
  void _onUserAddedToList(LikedUsersList list) {
    setState(() {
      selectedList = list;
      showSaveMessage = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtener providers y esquema de colores
    final colorScheme = ColorPalette.getPalette(context);
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isLiked = favoritesProvider.isUserLiked(widget.userId);

    // Ocultar mensaje de guardado después de 3 segundos
    if (showSaveMessage) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            showSaveMessage = false;
          });
        }
      });
    }

    return Stack(
      children: [
        // Fondo semitransparente para cerrar al tocar fuera
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),

        // Diálogo principal con la vista previa
        Center(
          child: GestureDetector(
            onTap: () {},
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.all(16),
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme[AppStrings.primaryColorLight],
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen de perfil del artista
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.profileImageUrl,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                height: 300,
                                color:
                                    colorScheme[AppStrings.primaryColorLight],
                                child: const Icon(Icons.person, size: 60),
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Fila con nombre y valoración
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Nombre del artista
                          Text(
                            widget.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme[AppStrings.secondaryColor],
                            ),
                          ),
                          // Valoración con estrellas
                          Row(
                            children: [
                              Text(
                                reviewProvider.averageStars > 0
                                    ? reviewProvider.averageStars
                                        .toStringAsFixed(1)
                                    : AppStrings.notAvailable,
                                style: TextStyle(
                                  color: colorScheme[AppStrings.secondaryColor],
                                  fontSize: 18,
                                ),
                              ),
                              Icon(
                                Icons.star,
                                color: colorScheme[AppStrings.essentialColor],
                                size: 27,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Precio por hora
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${AppStrings.hourlyRate}: \$${widget.price}',
                          style: TextStyle(
                            color: colorScheme[AppStrings.secondaryColor],
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Botones de acción
                      Row(
                        children: [
                          // Botón de guardar en favoritos
                          Expanded(
                            child: ElevatedButton(
                              onPressed: handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    colorScheme[AppStrings.primarySecondColor],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isLiked ? Colors.red : Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppStrings.save,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),

                          // Botón de contacto
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                userProvider.setOtherUserId(widget.userId);
                                widget.goRouter.push(
                                  AppStrings.chatScreenRoute,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    colorScheme[AppStrings.essentialColor],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.message,
                                    color:
                                        colorScheme[AppStrings.secondaryColor],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppStrings.contact,
                                    style: TextStyle(
                                      color:
                                          colorScheme[AppStrings
                                              .secondaryColor],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Botón para ver perfil completo
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            userProvider.setMenuSelection(
                              AppStrings.worksContentWS,
                            );
                            userProvider.setOtherUserId(widget.userId);
                            userProvider.loadUserData(widget.userId);
                            widget.goRouter.push(
                              AppStrings.profileArtistScreenWSRoute,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                colorScheme[AppStrings.primaryColor],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            AppStrings.viewFullProfile,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Diálogo de confirmación para eliminar de favoritos
        if (showConfirmRemoveDialog)
          AlertDialog(
            backgroundColor: colorScheme[AppStrings.primaryColor],
            title: Text(
              AppStrings.confirmDeleteUserTitle,
              style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
            ),
            content: Text(
              '${AppStrings.confirmDeleteUserMessage} ${widget.name}?',
              style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
            ),
            actions: [
              // Botón de cancelar
              TextButton(
                onPressed:
                    () => setState(() => showConfirmRemoveDialog = false),
                style: TextButton.styleFrom(
                  backgroundColor: colorScheme[AppStrings.primaryColorLight],
                ),
                child: Text(
                  AppStrings.cancel,
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
              ),
              // Botón de confirmar eliminación
              TextButton(
                onPressed: () {
                  setState(() {
                    showConfirmRemoveDialog = false;
                    widget.onUnlikeClick();
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: colorScheme[AppStrings.primaryColorLight],
                ),
                child: Text(
                  AppStrings.delete,
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
              ),
            ],
          ),

        // Diálogo para seleccionar lista de favoritos
        if (showBottomSaveDialog)
          BottomSaveToFavoritesDialog(
            onDismiss: () => setState(() => showBottomSaveDialog = false),
            onCreateNewList: () {
              print("userId: ${widget.userId}");
              setState(() {
                showBottomSaveDialog = false;
                showBottomFavoritesListCreatorDialog = true;
              });
              userProvider.addLikes(widget.userId);
            },
            favoritesProvider: favoritesProvider,
            userIdToSave: widget.userId,
            onUserAddedToList: _onUserAddedToList,
            onLikeClick: () {
              print("userId: ${widget.userId}");
              widget.onLikeClick();
              userProvider.addLikes(widget.userId);
            },
          ),

        // Diálogo para crear nueva lista de favoritos
        if (showBottomFavoritesListCreatorDialog)
          BottomFavoritesListCreatorDialog(
            userId: widget.userId,
            onDismiss: () {
              print("userId: ${widget.userId}");
              setState(() => showBottomFavoritesListCreatorDialog = false);
              userProvider.addLikes(widget.userId);
            },
            favoritesProvider: favoritesProvider,
            onLikeClick: () {
              print("userId: ${widget.userId}");
              widget.onLikeClick();
              userProvider.addLikes(widget.userId);
            },
          ),

        // Mensaje de confirmación de guardado
        if (showSaveMessage && selectedList != null)
          SaveMessage(
            list: selectedList!,
            onModifyClick: () {
              print("userId: ${widget.userId}");
              setState(() {
                showSaveMessage = false;
                showBottomSaveDialog = true;
              });
              userProvider.addLikes(widget.userId);
            },
            isVisible: showSaveMessage,
            onDismiss: () {
              print("userId: ${widget.userId}");
              setState(() => showSaveMessage = false);
              userProvider.addLikes(widget.userId);
            },
            favoritesProvider: favoritesProvider,
            userIdToRemove: widget.userId,
            onLikeClick: () {
              print("userId: ${widget.userId}");
              widget.onLikeClick();
              userProvider.addLikes(widget.userId);
            },
            onUnlikeClick: () {
              print("userId: ${widget.userId}");
              widget.onUnlikeClick();
            },
            currentUserId: widget.userId,
          ),
      ],
    );
  }
}
