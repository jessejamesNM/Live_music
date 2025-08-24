/*
  ──────────────────────────────────────────────────────────────────────────────
  Fecha de creación: 22 de abril de 2025
  Autor: KingdomOfJames

  Descripción de la pantalla:
  LikedUsersListScreen es una pantalla que muestra una lista de usuarios marcados 
  como favoritos por el usuario actual, agrupados en listas personalizadas. Permite 
  cambiar entre modo de visualización y edición para eliminar usuarios de estas listas. 
  La interfaz se actualiza en tiempo real mediante streams de Firebase y el estado 
  global es manejado por Provider.

  Características:
  - Escucha en tiempo real los cambios en la lista de favoritos.
  - Navegación integrada con GoRouter.
  - Edición dinámica de la lista mediante modo "Editar".
  - Confirmación de eliminación con diálogo personalizado.
  - Redirección automática si la lista queda vacía.
  - Diseño adaptado a la paleta de colores personalizada.

  Recomendaciones:
  - Añadir feedback visual al eliminar un usuario (snackbar o animación).
  - Posibilidad de deshacer una eliminación.
  - Paginación o lazy loading para listas grandes.
  - Soporte para reordenar elementos en modo edición.
  - Agregar opción para cambiar el nombre de la lista actual desde esta pantalla.
  ──────────────────────────────────────────────────────────────────────────────
*/

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import '../../../data/model/liked_artist/profile_base.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import '../../../data/provider_logics/user/user_provider.dart';
import '../../widgets/liked_artist/artist_grid.dart';
import '../buttom_navigation_bar.dart';
import 'package:live_music/presentation/resources/colors.dart';
/// Pantalla principal de lista de usuarios favoritos
class LikedUsersListScreen extends StatefulWidget {
  final GoRouter goRouter;

  const LikedUsersListScreen({Key? key, required this.goRouter})
      : super(key: key);

  @override
  _LikedUsersListScreenState createState() => _LikedUsersListScreenState();
}

class _LikedUsersListScreenState extends State<LikedUsersListScreen> {
  late FavoritesProvider _favoritesProvider;
  late String? _currentUserId;
  bool _loading = true;
  List<ProfileBase> _profiles = [];
  bool isEditMode = false;
  String? userToDelete;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      await for (final liked in _favoritesProvider.likedProfiles) {
        final selectedList = _favoritesProvider.selectedListValue;
        if (liked.isNotEmpty && selectedList != null) {
          final idsPermitidos = selectedList.likedUsersList;
          final perfilesFiltrados = liked
              .where((p) => idsPermitidos.contains(p.userId))
              .map((p) => p.toProfileBase())
              .toList();

          setState(() {
            _profiles = perfilesFiltrados;
            _loading = false;
          });
          break;
        }
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(String userId) async {
    setState(() => userToDelete = userId);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final colorScheme = ColorPalette.getPalette(context);
        return AlertDialog(
          backgroundColor: colorScheme[AppStrings.primaryColor],
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppStrings.confirmDeleteUserTitle,
              style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
            ),
          ),
          content: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppStrings.confirmDeleteUserMessage,
              style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() => userToDelete = null);
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppStrings.cancel,
                  style: TextStyle(color: colorScheme[AppStrings.essentialColor]),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _removeUser();
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppStrings.delete,
                  style: TextStyle(color: colorScheme[AppStrings.essentialColor]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeUser() async {
    if (userToDelete == null) return;
    final sel = _favoritesProvider.selectedListValue;
    if (sel == null) return;

    _favoritesProvider.removeFromLikedUsersList(
      currentUserId: _currentUserId!,
      listId: sel.listId,
      userId: userToDelete!,
    );

    setState(() {
      _profiles.removeWhere((p) => p.userId == userToDelete);
      userToDelete = null;
    });

    if (_profiles.isEmpty && mounted) {
      widget.goRouter.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final userType = Provider.of<UserProvider>(context).userType;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenHeight * 0.02;
    final iconSize = screenWidth * 0.07;
    final titleFontSize = screenWidth * 0.065;
    final editFontSize = screenWidth * 0.045;
    final gridSpacing = screenWidth * 0.03;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      bottomNavigationBar: BottomNavigationBarWidget(
        userType: userType,
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
                    onTap: () => widget.goRouter.canPop()
                        ? widget.goRouter.pop()
                        : widget.goRouter.go(AppStrings.likedUsersListScreen),
                    child: Icon(
                      Icons.arrow_back,
                      color: colorScheme[AppStrings.secondaryColor],
                      size: iconSize,
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: StreamBuilder<String?>(
                        stream: _favoritesProvider.selectedListName,
                        builder: (c, s) {
                          if (s.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator(
                              color: colorScheme[AppStrings.essentialColor],
                            );
                          }
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              s.data ?? AppStrings.favorites,
                              style: TextStyle(
                                fontSize: titleFontSize,
                                color: colorScheme[AppStrings.secondaryColor],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
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
            SizedBox(height: screenHeight * 0.015),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colorScheme[AppStrings.essentialColor],
                      ),
                    )
                  : ArtistGrid<ProfileBase>(
                      goRouter: widget.goRouter,
                      favoritesProvider: _favoritesProvider,
                      profiles: _profiles,
                      currentUserId: _currentUserId!,
                      toggleFavoritesDialog: () {},
                      isEditMode: isEditMode,
                      removeUserFromFavoritesList: ({
                        required String currentUserId,
                        required String userIdToRemove,
                      }) async {
                        await _confirmDelete(userIdToRemove);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
