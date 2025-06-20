/// -----------------------------------------------------------------------------
/// Fecha de creación: 2025-04-22
/// Autor: KingdomOfJames
///
/// Descripción:
/// Pantalla que muestra las listas de artistas favoritos del usuario. Permite ver
/// las listas guardadas, editarlas y eliminar los elementos de esas listas. También
/// ofrece la funcionalidad de visualizar una lista de "artistas recientemente vistos".
/// Dependiendo de si el usuario está en modo edición, puede eliminar o modificar las listas.
///
/// Recomendaciones:
/// - Es recomendable realizar validaciones de permisos antes de permitir eliminar elementos,
///   para evitar borrados accidentales o no autorizados.
/// - Implementar animaciones de transición al cambiar entre el modo edición y normal.
/// - Agregar validación al eliminar listas para evitar errores si el usuario no tiene acceso.
///
/// Características:
/// - Soporta el modo edición para eliminar listas de favoritos.
/// - Muestra una lista de "artistas recientemente vistos".
/// - Maneja las interacciones de eliminar con confirmación en un `AlertDialog`.
/// - Utiliza un `StreamBuilder` para escuchar cambios en las listas de favoritos y actualizarlas
///   en tiempo real.
/// - Implementación de `GridView` para mostrar las listas de una manera visualmente organizada.
/// - Navegación fácil entre pantallas mediante `GoRouter`.
/// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import '../../../data/provider_logics/user/user_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/sources/local/internal_data_base.dart';
import '../../widgets/liked_artist/liked_users_list_card.dart';
import '../../widgets/liked_artist/recently_viewed_card.dart';
import '../buttom_navigation_bar.dart';
import 'package:live_music/presentation/resources/colors.dart';

// Pantalla principal que muestra las listas de artistas/perfiles favoritos
class LikedArtistsScreen extends StatefulWidget {
  final GoRouter goRouter; // Router para navegación

  const LikedArtistsScreen({required this.goRouter, Key? key})
    : super(key: key);

  @override
  _LikedArtistsScreenState createState() => _LikedArtistsScreenState();
}

class _LikedArtistsScreenState extends State<LikedArtistsScreen> {
  bool isEditMode = false; // Controla el modo de edición de listas
  bool showDeleteDialog = false; // Controla visibilidad del diálogo de borrado
  LikedUsersList? listToDelete; // Almacena temporalmente la lista a eliminar

  @override
  Widget build(BuildContext context) {
    // Obtener providers y datos del usuario
    final userProvider = Provider.of<UserProvider>(context);
    final userType = userProvider.userType;
    final isArtist = userType == 'artist'; // Determinar si es artista
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final currentUserId = userProvider.currentUserId;
    final colorScheme = ColorPalette.getPalette(context); // Esquema de colores

    // Configurar listener para cambios en listas de favoritos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      favoritesProvider.removeLikedUsersListener();
      favoritesProvider.listenForLikedUsersChanges(context, currentUserId);
    });

    // Mostrar diálogo de confirmación para borrar lista
    if (showDeleteDialog && listToDelete != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: colorScheme[AppStrings.primaryColorLight],
              title: Text(
                AppStrings.deleteFavoriteListTitle,
                style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
              ),
              content: Text(
                AppStrings.deleteFavoriteListMessage,
                style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
              ),
              actions: [
                // Botón Cancelar
                TextButton(
                  onPressed: () {
                    setState(() {
                      showDeleteDialog = false;
                      listToDelete = null;
                    });
                    widget.goRouter.pop();
                  },
                  child: Text(
                    AppStrings.cancel,
                    style: TextStyle(
                      color: colorScheme[AppStrings.essentialColor],
                    ),
                  ),
                ),
                // Botón Eliminar
                TextButton(
                  onPressed: () async {
                    if (listToDelete == null) return;

                    final listId = listToDelete!.listId;
                    final likedUserIds = listToDelete!.likedUsersList;

                    // Eliminar de Firestore (operación en la nube)
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(currentUserId)
                        .update({
                          "likedUsers": FieldValue.arrayRemove([listId]),
                        });

                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(currentUserId)
                        .update({
                          "likedUsers": FieldValue.arrayRemove(likedUserIds),
                        });

                    // Eliminar localmente en el provider
                    favoritesProvider.removeLikedUserList(listId);

                    // Actualizar estado si el widget sigue montado
                    if (mounted) {
                      setState(() {
                        showDeleteDialog = false;
                        listToDelete = null;
                      });
                    }

                    widget.goRouter.pop(); // Cerrar diálogo
                  },
                  child: Text(
                    AppStrings.delete,
                    style: TextStyle(
                      color: colorScheme[AppStrings.essentialColor],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      });
    }

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      // Barra de navegación inferior
      bottomNavigationBar: BottomNavigationBarWidget(
        isArtist: isArtist,
        goRouter: widget.goRouter,
      ),
      body: SafeArea(
        bottom: false, // Solo protege la parte superior
        child: Column(
          children: [
            // Header con botones
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  // Botón de retroceso
                  GestureDetector(
                    onTap: () => widget.goRouter.pop(),
                    child: Icon(
                      Icons.arrow_back,
                      color: colorScheme[AppStrings.secondaryColor],
                      size: 28,
                    ),
                  ),
                  // Título centrado
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        AppStrings.favorites,
                        style: TextStyle(
                          fontSize: 26,
                          color: colorScheme[AppStrings.secondaryColor],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Botón de edición (toggle)
                  GestureDetector(
                    onTap: () => setState(() => isEditMode = !isEditMode),
                    child: Text(
                      isEditMode ? AppStrings.done : AppStrings.edit,
                      style: TextStyle(
                        color: colorScheme[AppStrings.essentialColor],
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista principal de favoritos
            Expanded(
              child: StreamBuilder<List<LikedUsersList>>(
                stream: favoritesProvider.likedUsersLists,
                builder: (context, snapshot) {
                  // Mostrar indicador de carga mientras se obtienen datos
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: colorScheme[AppStrings.essentialColor],
                      ),
                    );
                  }

                  final likedUsersLists = snapshot.data ?? [];

                  // GridView para mostrar las listas
                  return GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 columnas
                      mainAxisSpacing: 8, // Espaciado vertical
                      crossAxisSpacing: 8, // Espaciado horizontal
                      childAspectRatio: 0.8, // Relación de aspecto
                    ),
                    itemCount: likedUsersLists.length + 1, // +1 para el primer item especial
                    itemBuilder: (context, index) {
                      // Primer item es especial (RecentlyViewedCard)
                      if (index == 0) {
                        return RecentlyViewedCard();
                      } else {
                        // Items normales (tarjetas de lista de favoritos)
                        final likedList = likedUsersLists[index - 1];
                        return LikedUsersListCard(
                          likedUsersList: likedList,
                          isEditMode: isEditMode,
                          onDeleteClick: (list) {
                            // Manejar clic para eliminar
                            setState(() {
                              listToDelete = list;
                              showDeleteDialog = true;
                            });
                          },
                          onClick: () {
                            // Manejar clic para ver detalles
                            favoritesProvider.setSelectedListName(likedList.name);
                            favoritesProvider.loadProfilesByIds(
                              likedList.likedUsersList,
                            );
                            widget.goRouter.push(AppStrings.likedUsersListScreen);
                          },
                          imageSize: 170, // Tamaño de imagen
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
