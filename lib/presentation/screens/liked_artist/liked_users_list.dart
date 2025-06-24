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

// Widget que muestra una lista de usuarios favoritos con capacidad de edición
class LikedUsersListScreen extends StatefulWidget {
  final GoRouter goRouter; // Router para navegación
  
  // Constructor que recibe el router como parámetro requerido
  const LikedUsersListScreen({Key? key, required this.goRouter})
    : super(key: key);

  @override
  _LikedUsersListScreenState createState() => _LikedUsersListScreenState();
}

class _LikedUsersListScreenState extends State<LikedUsersListScreen> {
  // Provider para manejar la lista de favoritos
  late FavoritesProvider _favoritesProvider;
  // ID del usuario actual
  late String? _currentUserId;
  // Flag para controlar el estado de carga
  bool _loading = true;
  // Lista de perfiles a mostrar
  List<ProfileBase> _profiles = [];
  // Flag para activar/desactivar modo edición
  bool isEditMode = false;
  // ID del usuario seleccionado para eliminar
  String? userToDelete;

  @override
  void initState() {
    super.initState();
    // Obtener providers necesarios
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    // Guardar ID del usuario actual
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    // Cargar los perfiles favoritos
    _loadProfiles();
  }

  // Método para cargar los perfiles favoritos
  Future<void> _loadProfiles() async {
    try {
      // Escuchar el stream de perfiles favoritos
      await for (final liked in _favoritesProvider.likedProfiles) {
        final selectedList = _favoritesProvider.selectedListValue;
        // Verificar si hay datos y lista seleccionada
        if (liked.isNotEmpty && selectedList != null) {
          // Filtrar perfiles según la lista seleccionada
          final idsPermitidos = selectedList.likedUsersList;
          final perfilesFiltrados = liked
              .where((p) => idsPermitidos.contains(p.userId))
              .map((p) => p.toProfileBase())
              .toList();

          // Actualizar estado con los perfiles filtrados
          setState(() {
            _profiles = perfilesFiltrados;
            _loading = false;
          });
          break;
        }
      }
    } catch (_) {
      // En caso de error, desactivar loading
      setState(() => _loading = false);
    }
  }

  // Mostrar diálogo de confirmación para eliminar usuario
  Future<void> _confirmDelete(String userId) async {
    // Guardar usuario a eliminar
    setState(() => userToDelete = userId);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        // Obtener esquema de colores
        final colorScheme = ColorPalette.getPalette(context);
        return AlertDialog(
          backgroundColor: colorScheme[AppStrings.primaryColor],
          title: Text(
            AppStrings.confirmDeleteUserTitle,
            style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
          ),
          content: Text(
            AppStrings.confirmDeleteUserMessage,
            style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
          ),
          actions: [
            // Botón Cancelar
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() => userToDelete = null);
              },
              child: Text(
                AppStrings.cancel,
                style: TextStyle(color: colorScheme[AppStrings.essentialColor]),
              ),
            ),
            // Botón Eliminar
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _removeUser();
              },
              child: Text(
                AppStrings.delete,
                style: TextStyle(color: colorScheme[AppStrings.essentialColor]),
              ),
            ),
          ],
        );
      },
    );
  }

  // Método para eliminar usuario de la lista
  Future<void> _removeUser() async {
    // Validaciones de seguridad
    if (userToDelete == null) return;
    final sel = _favoritesProvider.selectedListValue;
    if (sel == null) return;

    // Eliminar usuario a través del provider
    _favoritesProvider.removeFromLikedUsersList(
      currentUserId: _currentUserId!,
      listId: sel.listId,
      userId: userToDelete!,
    );

    // Actualizar lista local
    setState(() {
      _profiles.removeWhere((p) => p.userId == userToDelete);
      userToDelete = null;
    });

    // Si la lista queda vacía, regresar
    if (_profiles.isEmpty && mounted) {
      widget.goRouter.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener esquema de colores y tipo de usuario
    final colorScheme = ColorPalette.getPalette(context);
    final isArtist = Provider.of<UserProvider>(context).userType == AppStrings.artist;

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
                    onTap: () => widget.goRouter.canPop() 
                        ? widget.goRouter.pop() 
                        : widget.goRouter.go(AppStrings.likedUsersListScreen),
                    child: Icon(
                      Icons.arrow_back,
                      color: colorScheme[AppStrings.secondaryColor],
                      size: 28,
                    ),
                  ),
                  // Título centrado (nombre de la lista)
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
                          return Text(
                            s.data ?? AppStrings.favorites,
                            style: TextStyle(
                              fontSize: 26,
                              color: colorScheme[AppStrings.secondaryColor],
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
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
            const SizedBox(height: 12),
            
            // Lista de perfiles/artistas
            Expanded(
              child: _loading
                  ? // Mostrar indicador de carga si está cargando
                  Center(
                      child: CircularProgressIndicator(
                        color: colorScheme[AppStrings.essentialColor],
                      ),
                    )
                  : // Mostrar grid de artistas cuando los datos están listos
                  ArtistGrid<ProfileBase>(
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
