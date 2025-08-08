// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
//
// Descripción:
// Pantalla de búsqueda donde los usuarios pueden buscar artistas en la plataforma.
// Incluye un campo de búsqueda para encontrar usuarios y filtros para refinar los resultados.
// También permite ver una lista de artistas con información básica y la opción de agregar o quitar artistas de favoritos.
// La interfaz es dinámica, mostrando un dropdown con filtros y un sistema de visualización por tarjetas para los resultados de búsqueda.
//
// Recomendaciones:
// - Considera agregar más validaciones para las entradas de usuario (por ejemplo, validación de búsqueda vacía).
// - Si los artistas tienen información adicional (por ejemplo, géneros o disponibilidad), sería bueno agregarlo en la interfaz.
// - Asegúrate de manejar los casos donde los datos de los artistas no estén completos para evitar errores.
//
// Características:
// - Búsqueda por nombre de artista.
// - Filtros por rango de precios y tipo de disponibilidad.
// - Visualización en formato de grid de los resultados con información del artista.
// - Capacidad de agregar y quitar artistas de favoritos.
// - Desplegar filtros de búsqueda usando un Dropdown.
// - Interacción de la interfaz con Firebase Firestore y Firebase Auth.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/home/search_fun_provider.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/search/search_provider.dart';
import '../../../data/provider_logics/user/user_provider.dart';

import '../../../data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import '../../widgets/search/artist_card.dart';
import '../../widgets/search/top_drop_dowm.dart';
import '../buttom_navigation_bar.dart';

class SearchScreen extends StatefulWidget {
  final GoRouter goRouter;
  final UserProvider userProvider;

  const SearchScreen({
    required this.goRouter,
    required this.userProvider,
    Key? key,
  }) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  bool showTopDropdown = false; // Para mostrar u ocultar el dropdown de filtros
  bool showProfilePreview =
      false; // Para mostrar u ocultar la vista previa del perfil
  bool showFavoritesDialog =
      false; // Para mostrar u ocultar el diálogo de favoritos

  RangeValues priceRange = const RangeValues(
    200.0,
    10000.0,
  ); // Rango de precios para los filtros
  String availability = ""; // Disponibilidad seleccionada en los filtros
  List<String> selectedGenres =
      []; // Géneros musicales seleccionados en los filtros
  String searchQuery = ""; // Término de búsqueda
  String? selectedEvent; // Evento seleccionado en los filtros
  List<String> artistsIds = []; // Lista de IDs de artistas

  @override
  void initState() {
    super.initState();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      Provider.of<SearchProvider>(context, listen: false).loadCountryAndState(
        currentUserId,
      ); // Carga la información del país y estado del usuario actual
      Provider.of<SearchProvider>(context, listen: false).getUsersByCountry(
        currentUserId,
        selectedGenres,
        priceRange,
        availability,
        "",
      ); // Carga los usuarios según el país y los filtros
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchFunProvider = Provider.of<SearchFunProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final searchProvider = Provider.of<SearchProvider>(context);
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Paleta de colores personalizada
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final userType = widget.userProvider.userType;
    final isArtist =
        userType == AppStrings.artist; // Verifica si el usuario es un artista
    final scaleFactor =
        MediaQuery.of(context).size.width /
        390.0; // Factor de escala para la interfaz
    final cellWidth =
        190.0 *
        scaleFactor; // Ancho de las celdas de los resultados de búsqueda
    final reduceHeight =
        10.0 * scaleFactor; // Reducción de altura de las celdas
    final cellHeight = cellWidth - reduceHeight; // Altura de las celdas

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      bottomNavigationBar: BottomNavigationBarWidget(
        
        goRouter: widget.goRouter,
        isArtist: isArtist, // Barra de navegación inferior
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Contenido principal
            Container(
              color:
                  colorScheme[AppStrings
                      .primaryColor], // Fondo principal de la pantalla
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 8.0,
              ),
              child: Column(
                children: [
                  Text(
                    AppStrings.search, // Título de la pantalla
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color:
                          colorScheme[AppStrings
                              .secondaryColor], // Color del texto
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    onChanged:
                        (q) => setState(
                          () => searchQuery = q,
                        ), // Actualiza el término de búsqueda
                    style: TextStyle(
                      color:
                          colorScheme[AppStrings
                              .secondaryColor], // Color del texto en el campo de búsqueda
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchGroupsOrCategories,
                      hintStyle: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor]
                            ?.withOpacity(0.6), // Estilo del texto del hint
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color:
                            colorScheme[AppStrings
                                .secondaryColor], // Icono de búsqueda
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.send,
                          color:
                              colorScheme[AppStrings
                                  .essentialColor], // Icono de envío
                        ),
                        onPressed: () {
                          if (searchQuery.isNotEmpty) {
                            searchFunProvider.searchUsers(
                              searchQuery,
                            ); // Realiza la búsqueda
                            widget.goRouter.push(
                              AppStrings.searchFunScreenRoute,
                            ); // Navega a la pantalla de resultados
                          }
                        },
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color:
                              colorScheme[AppStrings
                                  .secondaryColor]!, // Borde del campo de búsqueda
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color:
                              colorScheme[AppStrings
                                  .essentialColor]!, // Borde cuando está enfocado
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      setState(
                        () => showTopDropdown = !showTopDropdown,
                      ); // Muestra/oculta el dropdown de filtros
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          color:
                              colorScheme[AppStrings
                                  .essentialColor], // Icono de filtro
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.filterResults, // Texto del filtro
                          style: TextStyle(
                            color:
                                colorScheme[AppStrings
                                    .secondaryColor], // Estilo del texto
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: Consumer<SearchProvider>(
                      // Listado de artistas en grid
                      builder: (context, provider, child) {
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // Número de columnas en el grid
                            mainAxisSpacing: 12, // Espacio entre filas
                            crossAxisSpacing: 4, // Espacio entre columnas
                            childAspectRatio:
                                cellWidth /
                                cellHeight, // Relación de aspecto de las celdas
                          ),
                          itemCount:
                              provider
                                  .artists
                                  .length, // Número de artistas a mostrar
                          itemBuilder: (context, index) {
                            final artist = provider.artists[index];
                            return SizedBox(
                              width: cellWidth,
                              height: cellHeight,
                              child: ArtistCard(
                                // Tarjeta de artista
                                profileImageUrl:
                                    artist[AppStrings.profileImageUrlField] ?? "",
                                name:
                                    artist[AppStrings.nameField] ??
                                    AppStrings.noName,
                                price: artist["price"]?.toDouble() ?? 0.0,
                                userId: artist["userId"] ?? "",
                                currentUserId: currentUserId ?? "",
                                userLiked: artist["userLiked"] ?? false,
                                onLikeClick: () {
                                  favoritesProvider.onLikeClick(
                                    artist["userId"] ?? "",
                                    currentUserId ?? "",
                                  );
                                },
                                onUnlikeClick: () {
                                  favoritesProvider.onUnlikeClick(
                                    artist["userId"] ?? "",
                                  );
                                },
                                toggleFavoritesDialog: () {
                                  setState(
                                    () =>
                                        showFavoritesDialog =
                                            !showFavoritesDialog,
                                  ); // Mostrar/Ocultar diálogo de favoritos
                                },
                                goRouter: widget.goRouter,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Overlay semi-transparente
            if (showTopDropdown)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(
                      () => showTopDropdown = false,
                    ); // Cerrar el dropdown al hacer clic en el overlay
                  },
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),

            // Dropdown de filtros que ocupa toda la pantalla
            if (showTopDropdown)
              Positioned(
                top: 20, // Empieza desde la parte superior
                left: 0,
                right: 0,
                bottom: 0, // Ocupa toda la altura disponible
                child: Material(
                  color: Colors.transparent,
                  child: SafeArea(
                    top: false, // Permite que llegue hasta el borde superior
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 0.0, // Espacio para el encabezado
                      ),
                      child: TopDropdown(
                        searchProvider: searchProvider,
                        isVisible: showTopDropdown,
                        onClose: () {
                          setState(
                            () => showTopDropdown = false,
                          ); // Cerrar el dropdown
                        },
                        currentUserId: currentUserId,
                        onFilterApplied: (ids) {
                          searchProvider.clearArtists();
                          for (var id in ids) {
                            db
                                .collection(AppStrings.usersCollection)
                                .doc(id)
                                .get()
                                .then((doc) {
                                  final data = doc.data();
                                  if (data != null) {
                                    data["userId"] = id;
                                    searchProvider.addArtist(
                                      data,
                                    ); // Añadir artistas filtrados
                                  }
                                });
                          }
                        },
                      ),
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
