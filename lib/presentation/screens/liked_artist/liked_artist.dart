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
import 'package:firebase_auth/firebase_auth.dart';
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

class LikedArtistsScreen extends StatefulWidget {
  final GoRouter goRouter;

  const LikedArtistsScreen({required this.goRouter, Key? key})
      : super(key: key);

  @override
  _LikedArtistsScreenState createState() => _LikedArtistsScreenState();
}

class _LikedArtistsScreenState extends State<LikedArtistsScreen> {
  bool isEditMode = false;
  bool showDeleteDialog = false;
  LikedUsersList? listToDelete;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final colorScheme = ColorPalette.getPalette(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Medidas adaptativas
    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenHeight * 0.02;
    final iconSize = screenWidth * 0.07;
    final titleFontSize = screenWidth * 0.065;
    final editFontSize = screenWidth * 0.045;
    final gridSpacing = screenWidth * 0.03;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      favoritesProvider.removeLikedUsersListener();
      if (currentUserId != null) {
        favoritesProvider.listenForLikedUsersChanges(context, currentUserId);
      }
    });

    if (showDeleteDialog && listToDelete != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: colorScheme[AppStrings.primaryColorLight],
              title: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppStrings.deleteFavoriteListTitle,
                  style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
                ),
              ),
              content: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppStrings.deleteFavoriteListMessage,
                  style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      showDeleteDialog = false;
                      listToDelete = null;
                    });
                    widget.goRouter.pop();
                  },
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      AppStrings.cancel,
                      style: TextStyle(
                        color: colorScheme[AppStrings.essentialColor],
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (listToDelete == null) return;
                    final listId = listToDelete!.listId;
                    final likedUserIds = listToDelete!.likedUsersList;

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

                    favoritesProvider.removeLikedUserList(listId);

                    if (mounted) {
                      setState(() {
                        showDeleteDialog = false;
                        listToDelete = null;
                      });
                    }
                    widget.goRouter.pop();
                  },
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      AppStrings.delete,
                      style: TextStyle(
                        color: colorScheme[AppStrings.essentialColor],
                      ),
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
      bottomNavigationBar: BottomNavigationBarWidget(
        userType: userProvider.userType,
        goRouter: widget.goRouter,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                verticalPadding,
                horizontalPadding,
                0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.goRouter.pop(),
                    child: Icon(
                      Icons.arrow_back,
                      color: colorScheme[AppStrings.secondaryColor],
                      size: iconSize,
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppStrings.favorites,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            color: colorScheme[AppStrings.secondaryColor],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => isEditMode = !isEditMode),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isEditMode ? AppStrings.done : AppStrings.edit,
                        style: TextStyle(
                          color: colorScheme[AppStrings.essentialColor],
                          fontSize: editFontSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<LikedUsersList>>(
                stream: favoritesProvider.likedUsersLists,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: colorScheme[AppStrings.essentialColor],
                      ),
                    );
                  }

                  final likedUsersLists = snapshot.data ?? [];

                  return GridView.builder(
                    padding: EdgeInsets.all(gridSpacing),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: gridSpacing,
                      crossAxisSpacing: gridSpacing,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: likedUsersLists.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return RecentlyViewedCard();
                      final likedList = likedUsersLists[index - 1];

                      // Imagen adaptativa basada en ancho de pantalla
                      final imageSize = screenWidth * 0.4;

                      return LikedUsersListCard(
                        likedUsersList: likedList,
                        isEditMode: isEditMode,
                        onDeleteClick: (list) {
                          setState(() {
                            listToDelete = list;
                            showDeleteDialog = true;
                          });
                        },
                        onClick: () {
                          favoritesProvider.setSelectedListName(likedList.name);
                          favoritesProvider.loadProfilesByIds(
                            likedList.likedUsersList,
                          );
                          widget.goRouter.push(AppStrings.likedUsersListScreen);
                        },
                        imageSize: imageSize,
                      );
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