/*──────────────────────────────────────────────────────────────────────────────
  Fecha de creación: 22 de abril de 2025
  Autor: KingdomOfJames

  Descripción de la pantalla:
  RecentlyViewedScreen es una pantalla que muestra los perfiles de artistas o usuarios
  que el usuario ha visto recientemente. Permite navegar hacia atrás y muestra una lista
  actualizada en tiempo real utilizando un stream que obtiene los perfiles desde el proveedor 
  de favoritos. También incluye un diseño adaptado a la paleta de colores y navegación 
  mediante GoRouter.

  Características:
  - Visualiza los perfiles recientemente vistos con un estilo de rejilla.
  - Usa un stream para actualizar dinámicamente la lista de perfiles.
  - Presenta un indicador de carga mientras se obtienen los datos.
  - Ofrece un botón de retroceso que permite volver a la pantalla anterior.
  - Soporte para eliminar usuarios de la lista de favoritos (lógica a implementar).
  - Diseño adaptable a dispositivos móviles y escritorio.
  - BottomNavigationBarWidget para navegación adicional.

  Recomendaciones:
  - Considerar agregar una funcionalidad para volver a agregar perfiles eliminados.
  - Implementar un feedback visual cuando no hay perfiles recientemente vistos (p.ej., mensaje o imagen).
  - Soporte para paginación o lazy loading si la lista crece considerablemente.
  - Mejorar la interacción con el estado de los perfiles (favoritos, visualización, etc.).
  - Añadir una animación de transición cuando los perfiles cambian o se actualizan.
  ──────────────────────────────────────────────────────────────────────────────
*/

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:live_music/data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
import 'package:live_music/data/provider_logics/user/review_provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import '../../../data/sources/local/internal_data_base.dart';
import '../../widgets/liked_artist/artist_grid.dart';
import '../../widgets/liked_artist/empty_state.dart';
import '../buttom_navigation_bar.dart';
import 'package:go_router/go_router.dart';
class RecentlyViewedScreens extends StatefulWidget {
  final UserProvider userProvider;
  final ReviewProvider reviewProvider;
  final FavoritesProvider favoritesProvider;
  final GoRouter goRouter;

  const RecentlyViewedScreens({
    Key? key,
    required this.userProvider,
    required this.reviewProvider,
    required this.favoritesProvider,
    required this.goRouter,
  }) : super(key: key);

  @override
  _RecentlyViewedScreenState createState() => _RecentlyViewedScreenState();
}

class _RecentlyViewedScreenState extends State<RecentlyViewedScreens> {
  bool showFavoritesDialog = false;
  String? selectedArtistId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await widget.favoritesProvider.fetchRecentlyViewedProfilesFromRoom();
  }

  Future<void> removeUserFromFavoritesList({
    required String currentUserId,
    required String userIdToRemove,
  }) async {
    // Implementa la lógica para eliminar favoritos aquí
  }

  @override
  Widget build(BuildContext context) {
    final userType = widget.userProvider.userType;
    final isArtist = userType == 'artist';
    final colorScheme = ColorPalette.getPalette(context);
    final recentProfiles = widget.favoritesProvider.recentlyViewedProfiles;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor] ?? Colors.white, // 🔹 Fondo primario
      body: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: null,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          decoration: TextDecoration.none,
          shadows: [],
          backgroundColor: Colors.transparent,
          color: Colors.black, // color por defecto
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 40,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                    onPressed: () {
                      widget.goRouter.pop();
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.recentlyViewedTitle,
                    style: TextStyle(
                      fontFamily: null,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme[AppStrings.secondaryColor],
                      decoration: TextDecoration.none,
                      shadows: const [],
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<RecentlyViewedProfile>>(
                stream: recentProfiles as Stream<List<RecentlyViewedProfile>>?,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "${AppStrings.error}: ${snapshot.error}",
                        style: TextStyle(
                          fontFamily: null,
                          color: colorScheme[AppStrings.secondaryColor],
                          decoration: TextDecoration.none,
                          shadows: const [],
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return EmptyState();
                  } else {
                    final profiles = snapshot.data!;
                    return ArtistGrid<RecentlyViewedProfile>(
                      goRouter: widget.goRouter,
                      favoritesProvider: widget.favoritesProvider,
                      profiles: profiles,
                      currentUserId: currentUserId ?? '',
                      toggleFavoritesDialog: () {
                        setState(() {
                          showFavoritesDialog = !showFavoritesDialog;
                        });
                      },
                      isEditMode: false,
                      removeUserFromFavoritesList: removeUserFromFavoritesList,
                    );
                  }
                },
              ),
            ),
            BottomNavigationBarWidget(
              userType: userType,
              goRouter: widget.goRouter,
            ),
          ],
        ),
      ),
    );
  }
}