/*
  ──────────────────────────────────────────────────────────────────────────────
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

// Definición de la clase RecentlyViewedScreen que es un StatefulWidget
class RecentlyViewedScreen extends StatefulWidget {
  final UserProvider userProvider; // Proveedor de datos del usuario
  final ReviewProvider reviewProvider; // Proveedor de datos de reseñas
  final FavoritesProvider favoritesProvider; // Proveedor de datos de favoritos

  final GoRouter goRouter; // Navegador para las rutas de la aplicación

  // Constructor que requiere estos parámetros
  const RecentlyViewedScreen({
    Key? key,
    required this.userProvider,
    required this.reviewProvider,
    required this.favoritesProvider,

    required this.goRouter,
  }) : super(key: key);

  @override
  _RecentlyViewedScreenState createState() => _RecentlyViewedScreenState();
}

// Estado de RecentlyViewedScreen, donde se maneja la lógica y UI
class _RecentlyViewedScreenState extends State<RecentlyViewedScreen> {
  bool showFavoritesDialog =
      false; // Controla si se muestra el cuadro de diálogo de favoritos
  String?
  selectedArtistId; // ID del artista seleccionado para eliminar de favoritos

  // Método para inicializar datos, se ejecuta cuando se crea el widget
  @override
  void initState() {
    super.initState();
    _initializeData(); // Inicializa los datos, en este caso obtiene los perfiles recientemente vistos
  }

  // Método para cargar los perfiles recientemente vistos desde el proveedor de favoritos
  Future<void> _initializeData() async {
    await widget.favoritesProvider.fetchRecentlyViewedProfilesFromRoom();
  }

  // Método para eliminar un usuario de la lista de favoritos
  Future<void> removeUserFromFavoritesList({
    required String currentUserId,
    required String userIdToRemove,
  }) async {
    // Aquí se implementaría la lógica para eliminar al usuario de los favoritos, ya sea con Firestore o algún otro proveedor
  }

  @override
  Widget build(BuildContext context) {
    final userType = widget.userProvider.userType;
    final isArtist = userType == 'artist';
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtiene los colores para el esquema de la aplicación
    final recentProfiles =
        widget
            .favoritesProvider
            .recentlyViewedProfiles; // Los perfiles recientemente vistos
    final currentUserId =
        FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        // Cabecera de la pantalla con un botón para regresar y el título de la sección
        Padding(
          padding: const EdgeInsets.only(
            top: 40,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          child: Row(
            children: [
              // Botón para volver atrás
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: colorScheme[AppStrings.secondaryColor],
                ),
                onPressed: () {
                  widget.goRouter.pop(); // Regresa a la pantalla anterior
                },
              ),
              const SizedBox(width: 8),
              // Título de la sección
              Text(
                AppStrings.recentlyViewedTitle,
                style: TextStyle(
                  fontSize: 24,
                  color: colorScheme[AppStrings.secondaryColor],
    fontWeight: FontWeight.normal, // Fuerza negrita normal
    decoration: TextDecoration.none, // Elimina subrayado
                ),
              ),
            ],
          ),
        ),
        // Sección para mostrar los perfiles recientemente vistos
        Expanded(
          child: StreamBuilder<List<RecentlyViewedProfile>>(
            stream:
                recentProfiles
                    as Stream<
                      List<RecentlyViewedProfile>
                    >?, // Escucha los cambios en los perfiles recientemente vistos
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                ); // Muestra un indicador de carga mientras espera los datos
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "${AppStrings.error}: ${snapshot.error}", // Muestra un mensaje de error si ocurre uno
                    style: TextStyle(
                      color: colorScheme[AppStrings.secondaryColor],
                      decoration: TextDecoration.none,
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return EmptyState(); // Si no hay datos, muestra un estado vacío
              } else {
                final profiles =
                    snapshot.data!; // Los perfiles recientemente vistos

                // Muestra los perfiles en una cuadrícula (ArtistGrid) con la capacidad de editar y eliminar
                return ArtistGrid<RecentlyViewedProfile>(
                  goRouter: widget.goRouter,
                  favoritesProvider: widget.favoritesProvider,
                  profiles: profiles,
                  currentUserId: currentUserId ?? '',
                  toggleFavoritesDialog: () {
                    setState(() {
                      showFavoritesDialog =
                          !showFavoritesDialog; // Alterna el estado del cuadro de diálogo de favoritos
                    });
                  },
                  isEditMode: false, // Indica si está en modo de edición
                  removeUserFromFavoritesList:
                      removeUserFromFavoritesList, // Método para eliminar de favoritos
                );
              }
            },
          ),
        ),
        // Barra de navegación inferior
        BottomNavigationBarWidget(
          isArtist:
              isArtist, // Si es un artista, se ajusta el comportamiento de la barra
          goRouter: widget.goRouter, // Navegación usando el goRouter
        ),
      ],
    );
  }
}
