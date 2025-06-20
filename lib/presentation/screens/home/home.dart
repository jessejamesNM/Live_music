/// -----------------------------------------------------------------------------
/// Fecha de creación: 2025-04-26
/// Autor: KingdomOfJames
///
/// Descripción:
/// Pantalla principal (Home) de la aplicación "Live Music" donde los usuarios
/// pueden explorar artistas destacados, filtrar por géneros musicales, buscar
/// directamente por nombre y añadir artistas a su lista de favoritos. Se adapta
/// dinámicamente al tipo de usuario (artista o fan) y a la ubicación del mismo.
///
/// Recomendaciones:
/// - Considerar usar paginación o lazy loading para la carga de artistas si se
///   espera un crecimiento considerable en la base de usuarios.
/// - Implementar manejo de errores visuales si la red falla al obtener artistas.
/// - Añadir animaciones suaves entre categorías y resultados para mejorar UX.
/// - Evaluar separar la lógica de obtención de datos en un controlador o servicio
///   dedicado para mantener limpio el State.
///
/// Características:
/// - Obtención automática del ID del usuario y su ubicación (país/estado).
/// - Búsqueda por texto con navegación a pantalla de resultados (/searchfunscreen).
/// - Filtro por género musical mediante CategoriesSection.
/// - Renderizado dinámico de artistas destacados basado en ubicación y género.
/// - Manejo de favoritos con interacción directa (like/unlike) desde la tarjeta.
/// - Integración con múltiples providers para mantener la lógica modular y escalable.
/// - Diseño responsivo con scroll horizontal para explorar artistas.
/// - Usa BottomNavigationBarWidget para facilitar navegación general en la app.
/// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:live_music/data/provider_logics/beginning/beginning_provider.dart';
import 'package:live_music/presentation/resources/strings.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/home/home_provider.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/home/search_fun_provider.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/search/search_provider.dart';
import '../../../data/provider_logics/user/user_provider.dart';
import '../../../data/provider_logics/user/review_provider.dart';
import '../../widgets/artist_item.dart';
import '../../widgets/category_selection.dart';
import '../buttom_navigation_bar.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:go_router/go_router.dart';

// Widget principal de tipo Stateful que representa la pantalla de inicio de la app
class Home extends StatefulWidget {
  // Inyección de dependencias necesarias
  final FirebaseAuth auth;
  final UserProvider userProvider;
  final HomeProvider homeProvider;
  final SearchProvider searchProvider;
  final SearchFunProvider searchFunProvider;
  final ReviewProvider reviewProvider;
  final FavoritesProvider favoritesProvider;
  final GoRouter goRouter;
  final BeginningProvider beginningProvider;

  Home({
    required this.auth,
    required this.userProvider,
    required this.homeProvider,
    required this.searchProvider,
    required this.searchFunProvider,
    required this.reviewProvider,
    required this.favoritesProvider,
    required this.goRouter,
    required this.beginningProvider,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// Estado interno del widget Home
class _HomeScreenState extends State<Home> {
  late List<String> artistsIds; // Lista de IDs de artistas obtenidos
  late String searchQuery; // Consulta actual del buscador
  late List<Map<String, dynamic>>
  artistsDetails; // Detalles de artistas para mostrar
  bool showFavoritesDialog =
      false; // Controla si se muestra el diálogo de favoritos
  late List<String> selectedGenres; // Géneros seleccionados

  @override
  void initState() {
    super.initState();
    // Inicialización de variables
    artistsIds = [];
    searchQuery = '';
    artistsDetails = [];
    selectedGenres = [
      AppStrings.band,
      AppStrings.nortStyle,
      AppStrings.corridos,
      AppStrings.mariachi,
      AppStrings.montainStyle,
      AppStrings.cumbia,
      AppStrings.reggaeton,
    ];

    // Se ejecuta después del primer frame para evitar errores de contexto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserId();
      _fetchArtists();
      widget.userProvider.fetchCurrentUserId();
      widget.beginningProvider.checkAndSaveUserLocation(
        context,
        widget.goRouter,
      );
    });
  }

  // Obtiene el ID del usuario actual desde Firebase
  void _fetchUserId() {
    widget.userProvider.fetchUserIdFromFirebase(
      ValueNotifier<String>(widget.userProvider.currentUserId),
      widget.auth,
    );
  }

  // Obtiene los artistas según la ubicación del usuario y géneros seleccionados
  void _fetchArtists() {
    final currentUserId = widget.auth.currentUser?.uid;

    if (currentUserId != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get()
          .then((document) {
            final country =
                document.data()?.containsKey('country') == true
                    ? document['country']
                    : '';
            final state =
                document.data()?.containsKey('state') == true
                    ? document['state']
                    : '';

            // Si no hay país o estado, se obtiene desde el dispositivo
            if (country.isEmpty || state.isEmpty) {
              widget.userProvider.getCountryAndState();
            } else {
              // Si hay ubicación válida, se obtienen artistas filtrados
              widget.homeProvider.getUsersByCountry(
                currentUserId,
                country,
                state,
                selectedGenres,
                (ids) {
                  setState(() {
                    artistsIds = ids;
                   
                  });
                },
              );
            }
          });
    }
  }


  @override
  Widget build(BuildContext context) {
    // Asegura que el tipo de usuario está actualizado
    widget.userProvider.fetchUserType();

    final userType = widget.userProvider.userType;
    widget.userProvider.isUserTypeArtist(userType);
    final isArtist = userType == 'artist';
    final artists = widget.homeProvider.artistsForHome;
    final currentUserId = widget.auth.currentUser?.uid;
    final colorScheme = ColorPalette.getPalette(context);
    final goRouter = widget.goRouter;

print("se ejecuto esta cosa aaaaaaa Home $artists ");
  
    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      bottomNavigationBar: BottomNavigationBarWidget(
        isArtist: isArtist,
        goRouter: goRouter,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
          child: Column(
            children: [
              // Título principal
              Text(
                AppStrings.explore,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colorScheme[AppStrings.secondaryColor],
                ),
              ),
              const SizedBox(height: 15),

              // Campo de búsqueda
              TextField(
                onChanged: (query) {
                  setState(() {
                    searchQuery = query;
                  });
                },
                style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
                decoration: InputDecoration(
                  hintText: AppStrings.searchGroupsOrCategories,
                  hintStyle: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor]?.withOpacity(
                      0.6,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: colorScheme[AppStrings.essentialColor],
                    ),
                    onPressed: () {
                      if (searchQuery.isNotEmpty) {
                        widget.searchFunProvider.searchUsers(searchQuery);
                        widget.goRouter.go(AppStrings.searchFunScreenRoute);
                      }
                    },
                  ),
                  filled: true,
                  fillColor: colorScheme[AppStrings.primaryColor],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme[AppStrings.secondaryColor]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme[AppStrings.essentialColor]!,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sección de categorías musicales
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.categories,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Widget personalizado que muestra las categorías disponibles
              CategoriesSection(
                onCategoryClick: (selectedCategory) {
                  setState(() {
                    artistsIds = [];
                    artistsDetails = [];
                    selectedGenres = [selectedCategory];
                    _fetchArtists();
                  });
                },
              ),

              const SizedBox(height: 20),

              // Sección de artistas destacados
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.featuredArtists,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Lista horizontal de artistas destacados
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: artists.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    return ArtistItem(
                      artist: artist,
                      reviewProvider: widget.reviewProvider,
                      onLikeClick: () {
                        widget.favoritesProvider.onLikeClick(
                          artist['id'],
                          currentUserId,
                        );
                      },
                      onUnlikeClick: () {
                        widget.favoritesProvider.onUnlikeClick(artist['id']);
                      },
                      toggleFavoritesDialog: () {
                        setState(() {
                          showFavoritesDialog = !showFavoritesDialog;
                        });
                      },
                      favoritesProvider: widget.favoritesProvider,
                      currentUserId: currentUserId!,
                      userProvider: widget.userProvider,
                      goRouter: widget.goRouter,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
