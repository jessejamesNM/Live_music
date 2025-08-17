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
import '../buttom_navigation_bar.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:go_router/go_router.dart';

class Home extends StatefulWidget {
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

class _HomeScreenState extends State<Home> {
  late List<String> artistsIds;
  late String searchQuery;
  late List<Map<String, dynamic>> artistsDetails;
  bool showFavoritesDialog = false;
  late List<String> selectedEventTypes;
  late String selectedService;

  @override
  void initState() {
    super.initState();
    artistsIds = [];
    searchQuery = '';
    artistsDetails = [];
    selectedEventTypes = [];
    selectedService = 'Música';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
      widget.beginningProvider.checkAndSaveUserLocation(
        context,
        widget.goRouter,
      );
    });
  }

  void _fetchInitialData() {
    final currentUserId = widget.auth.currentUser?.uid;
    if (currentUserId != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get()
          .then((document) {
            final country = document.data()?['country']?.toString() ?? '';
            final state = document.data()?['state']?.toString() ?? '';

            if (country.isEmpty || state.isEmpty) {
              widget.userProvider.getCountryAndState();
            } else {
              widget.homeProvider.getUsersByCountry(
                currentUserId,
                country,
                state,
                selectedEventTypes,
                selectedService,
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

  void _onServiceSelected(String service) {
    setState(() {
      selectedService = service;
      artistsIds = [];
      artistsDetails = [];
    });
    _fetchInitialData();
  }

  void _onEventTypeSelected(String eventType) {
    setState(() {
      if (selectedEventTypes.contains(eventType)) {
        selectedEventTypes.remove(eventType);
      } else {
        selectedEventTypes.add(eventType);
      }
      artistsIds = [];
      artistsDetails = [];
    });
    _fetchInitialData();
  }

  @override
  Widget build(BuildContext context) {
    widget.userProvider.fetchUserType();
    final userType = widget.userProvider.userType;
    final artists = widget.homeProvider.artistsForHome;
    final currentUserId = widget.auth.currentUser?.uid;
    final colorScheme = ColorPalette.getPalette(context);
    final goRouter = widget.goRouter;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      bottomNavigationBar: BottomNavigationBarWidget(
        userType: userType,
        goRouter: goRouter,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 16.0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Título Explore centrado
                  Center(
                    child: Text(
                      AppStrings.explore,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Barra de búsqueda
                  TextField(
                    onChanged: (query) => setState(() => searchQuery = query),
                    style: TextStyle(
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchGroupsOrCategories,
                      hintStyle: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor]
                            ?.withOpacity(0.6),
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

                  // Sección de Servicios
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Servicios",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  ServicesSection(
                    onServiceSelected: _onServiceSelected,
                    selectedService: selectedService,
                  ),

                  const SizedBox(height: 20),

                  // Sección de Categorías
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Categorías",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  EventTypesSection(
                    onEventTypeSelected: _onEventTypeSelected,
                    selectedEventTypes: selectedEventTypes,
                  ),

                  const SizedBox(height: 20),
                ]),
              ),
            ),

            // Título Artistas Destacados
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.featuredArtists,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // Lista de artistas destacados (horizontal)
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(
                  left: 12.0,
                  right: 12.0,
                  bottom: 20.0,
                ),
                child: Row(
                  children:
                      artists.map((artist) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width * 0.8,
                            ),
                            child: ArtistItem(
                              artist: artist,
                              reviewProvider: widget.reviewProvider,
                              onLikeClick: () {
                                widget.favoritesProvider.onLikeClick(
                                  artist['id'],
                                  currentUserId,
                                );
                              },
                              onUnlikeClick: () {
                                widget.favoritesProvider.onUnlikeClick(
                                  artist['id'],
                                );
                              },
                              toggleFavoritesDialog: () {
                                setState(
                                  () =>
                                      showFavoritesDialog =
                                          !showFavoritesDialog,
                                );
                              },
                              favoritesProvider: widget.favoritesProvider,
                              currentUserId: currentUserId!,
                              userProvider: widget.userProvider,
                              goRouter: widget.goRouter,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 80.0)),
          ],
        ),
      ),
    );
  }
}

class ServicesSection extends StatelessWidget {
  final Function(String) onServiceSelected;
  final String selectedService;

  ServicesSection({
    required this.onServiceSelected,
    required this.selectedService,
  });

  final List<Map<String, String>> services = [
    {"title": "Música", "subtitle": ""},
    {"title": "Repostería", "subtitle": "Alimentos"},
    {"title": "Local", "subtitle": ""},
    {"title": "Decoración", "subtitle": ""},
    {"title": "Mueblería", "subtitle": "Mobiliario"}, // Nuevo servicio
    {"title": "Entretenimiento", "subtitle": "Eventos"}, // Nuevo servicio
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return Container(
      height: 55,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final service = services[index];
          final isSelected = service['title'] == selectedService;
          return ServiceCard(
            title: service['title']!,
            subtitle: service['subtitle']!,
            isSelected: isSelected,
            onTap: () => onServiceSelected(service['title']!),
          );
        },
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const ServiceCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final textColor = colorScheme[AppStrings.secondaryColor]!;
    final cardColor =
        isSelected
            ? colorScheme[AppStrings.primaryColor]
            : colorScheme[AppStrings.primaryColorLight] ?? Colors.grey;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isSelected
                  ? colorScheme[AppStrings.essentialColor]!
                  : Colors.transparent,
          width: 2,
        ),
      ),
      color: cardColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 120,
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: textColor,
                    fontFamily: AppStrings.customFont,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                title,
                style: TextStyle(
                  fontSize: _calculateFontSize(title),
                  color: textColor,
                  fontFamily: AppStrings.customFont,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateFontSize(String text) {
    if (text == "Repostería") return 12;
    if (text == "Entretenimiento") return 11; // Ajuste para texto largo
    if (text.length > 10) return 12;
    return 14;
  }
}

class EventTypesSection extends StatelessWidget {
  final Function(String) onEventTypeSelected;
  final List<String> selectedEventTypes;

  EventTypesSection({
    required this.onEventTypeSelected,
    required this.selectedEventTypes,
  });

  final List<String> eventTypes = [
    "Bodas",
    "15 años",
    "Fiestas casuales",
    "Eventos públicos",
    "Cumpleaños",
    "Conferencias",
    "Posadas",
    "Graduaciones",
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return Container(
      height: 55,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: eventTypes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final eventType = eventTypes[index];
          final isSelected = selectedEventTypes.contains(eventType);
          return EventTypeCard(
            eventType: eventType,
            isSelected: isSelected,
            onTap: () => onEventTypeSelected(eventType),
          );
        },
      ),
    );
  }
}

class EventTypeCard extends StatelessWidget {
  final String eventType;
  final bool isSelected;
  final VoidCallback onTap;

  const EventTypeCard({
    required this.eventType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final textColor = colorScheme[AppStrings.secondaryColor]!;
    final cardColor =
        isSelected
            ? colorScheme[AppStrings.primaryColor]
            : colorScheme[AppStrings.primaryColorLight] ?? Colors.grey;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isSelected
                  ? colorScheme[AppStrings.essentialColor]!
                  : Colors.transparent,
          width: 2,
        ),
      ),
      color: cardColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 120,
          height: 52,
          alignment: Alignment.center,
          child: Text(
            eventType,
            style: TextStyle(
              fontSize: _calculateFontSize(eventType),
              color: textColor,
              fontFamily: AppStrings.customFont,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  double _calculateFontSize(String text) {
    if (text.length > 12) return 12;
    return 14;
  }
}
