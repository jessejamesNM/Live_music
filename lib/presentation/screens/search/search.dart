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
import 'package:live_music/data/sources/local/internal_data_base.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/widgets/bottom_list_creator_dialog.dart';
import 'package:live_music/presentation/widgets/bottom_save_to_favorites_dialog.dart';
import 'package:live_music/presentation/widgets/save_message.dart';
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
  bool showTopDropdown = false;
  bool showProfilePreview = false;
  bool showFavoritesDialog = false;
  int currentView = 1; // 1 = Single column view, 2 = Grid view (default)

  RangeValues priceRange = const RangeValues(0.0, 500000.0);
  String availability = "";
  List<String> selectedGenres = [];
  String searchQuery = "";
  String? selectedEvent;
  List<String> artistsIds = [];

  // Like logic state
  bool _showSaveMessage = false;
  bool _showBottomSaveDialog = false;
  bool _showBottomFavoritesListCreatorDialog = false;
  bool _showConfirmRemoveDialog = false;
  LikedUsersList? _selectedList;
  String?
  _likeTargetUserId; // userId del artista actualmente seleccionado para like

  @override
  void initState() {
    super.initState();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      Provider.of<SearchProvider>(
        context,
        listen: false,
      ).loadCountryAndState(currentUserId);
      Provider.of<SearchProvider>(context, listen: false).getUsersByCountry(
        currentUserId,
        selectedGenres,
        priceRange,
        availability,
        "artist",
      );
    }

    // Escuchar cambios en los favoritos
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );
    favoritesProvider.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );
    favoritesProvider.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {
        // Forzar la reconstrucción de los widgets que muestran los likes
      });
    }
  }

  // --- LIKE/UNLIKE LOGIC ---

  void _handleLike(String artistUserId) {
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isLiked = favoritesProvider.isUserLiked(artistUserId);
    final likedLists = favoritesProvider.likedUsersListsValue;

    setState(() => _likeTargetUserId = artistUserId);

    if (isLiked) {
      setState(() => _showConfirmRemoveDialog = true);
    } else {
      if (likedLists.isEmpty) {
        setState(() => _showBottomFavoritesListCreatorDialog = true);
      } else if (likedLists.length == 1) {
        final list = likedLists.first;
        favoritesProvider.addUserToList(list.listId, artistUserId);
        setState(() {
          _selectedList = list;
          _showSaveMessage = true;
        });
        // Lógica de onLikeClick y addLikes
        favoritesProvider.onLikeClick(
          artistUserId,
          FirebaseAuth.instance.currentUser?.uid ?? '',
        );
        userProvider.addLikes(artistUserId);

        // Actualizar el estado del artista en la lista
        _updateArtistLikedStatus(artistUserId, true);
      } else {
        setState(() => _showBottomSaveDialog = true);
      }
    }
  }

  void _updateArtistLikedStatus(String artistUserId, bool isLiked) {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    final updatedArtists =
        searchProvider.artists.map((artist) {
          if (artist["userId"] == artistUserId) {
            return {...artist, "userLiked": isLiked};
          }
          return artist;
        }).toList();

    searchProvider.updateArtists(updatedArtists);
  }

  void _onUserAddedToList(LikedUsersList list) {
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final artistUserId = _likeTargetUserId ?? '';
    if (artistUserId.isEmpty) return;

    favoritesProvider.addUserToList(list.listId, artistUserId);
    favoritesProvider.onLikeClick(
      artistUserId,
      FirebaseAuth.instance.currentUser?.uid ?? '',
    );
    userProvider.addLikes(artistUserId);

    _updateArtistLikedStatus(artistUserId, true);

    setState(() {
      _selectedList = list;
      _showSaveMessage = true;
    });
  }

  void _removeFromFavorites() {
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final artistUserId = _likeTargetUserId ?? '';
    if (artistUserId.isNotEmpty) {
      favoritesProvider.onUnlikeClick(artistUserId);

      _updateArtistLikedStatus(artistUserId, false);
    }
    setState(() => _showConfirmRemoveDialog = false);
  }

  // --- END LIKE LOGIC ---

  Widget _buildServiceCardListView(
    SearchProvider provider,
    FavoritesProvider favoritesProvider,
  ) {
    return ListView.builder(
      itemCount: provider.artists.length,
      itemBuilder: (context, index) {
        final artist = provider.artists[index];
        final images = (artist["imageList"] as List?)?.cast<String>() ?? [];
        final artistUserId = artist["userId"] ?? "";

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 18.0),
          child: ServiceCard(
            images:
                images.isEmpty
                    ? ["https://via.placeholder.com/400x300?text=Sin+Imagen"]
                    : images,
            name: artist["name"] ?? AppStrings.noName,
            price: artist["price"]?.toDouble() ?? 0.0,
            userLiked: artist["userLiked"] ?? false,
            otherUserId: artistUserId,
            onLikeClick: () {
              _handleLike(artistUserId);
            },
            onUnlikeClick: () {
              _likeTargetUserId = artistUserId;
              _handleLike(artistUserId);
            },
          ),
        );
      },
    );
  }

  Widget _buildArtistCardGridView(
    SearchProvider provider,
    String? currentUserId,
    FavoritesProvider favoritesProvider,
    double cellWidth,
    double cellHeight,
  ) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 4,
        childAspectRatio: cellWidth / cellHeight,
      ),
      itemCount: provider.artists.length,
      itemBuilder: (context, index) {
        final artist = provider.artists[index];
        final images = (artist["imageList"] as List?)?.cast<String>() ?? [];
        final firstImage = images.isNotEmpty ? images[0] : "";
        final artistUserId = artist["userId"] ?? "";

        return SizedBox(
          width: cellWidth,
          height: cellHeight,
          child: ArtistCard(
            profileImageUrl: firstImage,
            name: artist["name"] ?? AppStrings.noName,
            price: artist["price"]?.toDouble() ?? 0.0,
            userId: artistUserId,
            currentUserId: currentUserId ?? "",
            userLiked: artist["userLiked"] ?? false,
            onLikeClick: () {
              _handleLike(artistUserId);
            },
            onUnlikeClick: () {
              _likeTargetUserId = artistUserId;
              _handleLike(artistUserId);
            },
            toggleFavoritesDialog: () {
              setState(() => showFavoritesDialog = !showFavoritesDialog);
            },
            goRouter: widget.goRouter,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchFunProvider = Provider.of<SearchFunProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final searchProvider = Provider.of<SearchProvider>(context);
    final colorScheme = ColorPalette.getPalette(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final userType = widget.userProvider.userType;
    final scaleFactor = MediaQuery.of(context).size.width / 390.0;
    final cellWidth = 190.0 * scaleFactor;
    final reduceHeight = 10.0 * scaleFactor;
    final cellHeight = cellWidth - reduceHeight;

    // Mensaje de guardado temporal
    if (_showSaveMessage) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showSaveMessage = false);
      });
    }

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      bottomNavigationBar: BottomNavigationBarWidget(
        goRouter: widget.goRouter,
        userType: userType,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              color: colorScheme[AppStrings.primaryColor],
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 8.0,
              ),
              child: Column(
                children: [
                  Text(
                    AppStrings.search,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    onChanged: (q) => setState(() => searchQuery = q),
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
                            searchFunProvider.searchUsers(searchQuery);
                            widget.goRouter.push(
                              AppStrings.searchFunScreenRoute,
                            );
                          }
                        },
                      ),
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
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => showTopDropdown = !showTopDropdown);
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list,
                              color: colorScheme[AppStrings.essentialColor],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.filterResults,
                              style: TextStyle(
                                fontSize: 15,
                                color: colorScheme[AppStrings.secondaryColor],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Vista:',
                            style: TextStyle(
                              color: colorScheme[AppStrings.secondaryColor],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ToggleButtons(
                            isSelected: [currentView == 1, currentView == 2],
                            onPressed: (int index) {
                              setState(() {
                                currentView = index + 1;
                              });
                            },
                            children: const [Text('1'), Text('2')],
                            borderRadius: BorderRadius.circular(8),
                            selectedColor: Colors.white,
                            fillColor: colorScheme[AppStrings.essentialColor],
                            color: colorScheme[AppStrings.secondaryColor],
                            constraints: const BoxConstraints(
                              minHeight: 36,
                              minWidth: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: Consumer<SearchProvider>(
                      builder: (context, provider, child) {
                        return Consumer<FavoritesProvider>(
                          builder: (context, favorites, child) {
                            return currentView == 1
                                ? _buildServiceCardListView(provider, favorites)
                                : _buildArtistCardGridView(
                                  provider,
                                  currentUserId,
                                  favorites,
                                  cellWidth,
                                  cellHeight,
                                );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (showTopDropdown)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() => showTopDropdown = false);
                  },
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),
            if (showTopDropdown)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                bottom: 0,
                child: Material(
                  color: Colors.transparent,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0.0),
                      child: TopDropdown(
                        searchProvider: searchProvider,
                        isVisible: showTopDropdown,
                        onClose: () {
                          setState(() => showTopDropdown = false);
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
                                    searchProvider.addArtist(data);
                                  }
                                });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            // --- UI dialogs for LIKE logic ---
            if (_showSaveMessage &&
                _selectedList != null &&
                _likeTargetUserId != null)
              SaveMessage(
                list: _selectedList!,
                onModifyClick: () {
                  setState(() {
                    _showSaveMessage = false;
                    _showBottomSaveDialog = true;
                  });
                  Provider.of<UserProvider>(
                    context,
                    listen: false,
                  ).addLikes(_likeTargetUserId!);
                },
                isVisible: _showSaveMessage,
                onDismiss: () => setState(() => _showSaveMessage = false),
                favoritesProvider: favoritesProvider,
                userIdToRemove: _likeTargetUserId!,
                onLikeClick: () => _onUserAddedToList(_selectedList!),
                onUnlikeClick:
                    () => favoritesProvider.onUnlikeClick(_likeTargetUserId!),
                currentUserId: currentUserId ?? "",
              ),
            if (_showBottomSaveDialog && _likeTargetUserId != null)
              BottomSaveToFavoritesDialog(
                onDismiss: () => setState(() => _showBottomSaveDialog = false),
                onCreateNewList: () {
                  setState(() {
                    _showBottomSaveDialog = false;
                    _showBottomFavoritesListCreatorDialog = true;
                  });
                  Provider.of<UserProvider>(
                    context,
                    listen: false,
                  ).addLikes(_likeTargetUserId!);
                },
                favoritesProvider: favoritesProvider,
                userIdToSave: _likeTargetUserId!,
                onUserAddedToList: _onUserAddedToList,
                onLikeClick: () {
                  if (_selectedList != null) _onUserAddedToList(_selectedList!);
                },
              ),
            if (_showBottomFavoritesListCreatorDialog &&
                _likeTargetUserId != null)
              BottomFavoritesListCreatorDialog(
                userId: _likeTargetUserId!,
                onDismiss:
                    () => setState(
                      () => _showBottomFavoritesListCreatorDialog = false,
                    ),
                favoritesProvider: favoritesProvider,
                onLikeClick: () async {
                  await Future.delayed(const Duration(milliseconds: 250));
                  final lists = favoritesProvider.likedUsersListsValue;
                  if (lists.isNotEmpty) {
                    final newList = lists.last;
                    _onUserAddedToList(newList);
                    setState(
                      () => _showBottomFavoritesListCreatorDialog = false,
                    );
                  } else {
                    await Future.delayed(const Duration(milliseconds: 300));
                    final retryLists = favoritesProvider.likedUsersListsValue;
                    if (retryLists.isNotEmpty) {
                      final newList = retryLists.last;
                      _onUserAddedToList(newList);
                      setState(
                        () => _showBottomFavoritesListCreatorDialog = false,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Debes crear al menos una lista de favoritos para guardar este servicio.',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              ),
            if (_showConfirmRemoveDialog && _likeTargetUserId != null)
              AlertDialog(
                backgroundColor: colorScheme[AppStrings.primaryColor],
                title: Text(
                  'Confirmar eliminación',
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
                content: Text(
                  '¿Estás seguro de que quieres eliminar este servicio de tus favoritos?',
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        () => setState(() => _showConfirmRemoveDialog = false),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          colorScheme[AppStrings.primaryColorLight],
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _removeFromFavorites,
                    style: TextButton.styleFrom(
                      backgroundColor:
                          colorScheme[AppStrings.primaryColorLight],
                    ),
                    child: Text(
                      'Eliminar',
                      style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class ServiceCard extends StatefulWidget {
  final List<String> images;
  final String name;
  final double price;
  final bool userLiked;
  final VoidCallback onLikeClick;
  final VoidCallback onUnlikeClick;
  final String otherUserId;

  const ServiceCard({
    Key? key,
    required this.images,
    required this.name,
    required this.price,
    required this.userLiked,
    required this.onLikeClick,
    required this.onUnlikeClick,
    required this.otherUserId,
  }) : super(key: key);

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  int _currentIndex = 0;

  List<int> _getDotIndexes() {
    int len = widget.images.length;
    if (len <= 5) return List.generate(len, (i) => i);
    if (_currentIndex < 2) return [0, 1, 2, 3, 4];
    if (_currentIndex > len - 3)
      return [len - 5, len - 4, len - 3, len - 2, len - 1];
    return [
      _currentIndex - 2,
      _currentIndex - 1,
      _currentIndex,
      _currentIndex + 1,
      _currentIndex + 2,
    ];
  }

  void _handleTap() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );
    final goRouter = GoRouter.of(context);

    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final String otherUserId = widget.otherUserId;

    if (currentUserId.isEmpty || otherUserId.isEmpty) return;

    userProvider.setOtherUserId(otherUserId);
    favoritesProvider.updateSelectedArtistId(otherUserId);
    favoritesProvider.saveRecentlyViewedProfileToFirestore(
      currentUserId,
      otherUserId,
    );
    favoritesProvider.listenAndSaveRecentlyViewedProfiles(
      currentUserId: currentUserId,
    );
    goRouter.push(AppStrings.servicePreviewScreen);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final dotIndexes = _getDotIndexes();
    final colorScheme = ColorPalette.getPalette(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _handleTap,
              child: Stack(
                children: [
                  SizedBox(
                    height: size,
                    width: size,
                    child: PageView.builder(
                      itemCount: images.length,
                      controller: PageController(initialPage: _currentIndex),
                      onPageChanged: (i) => setState(() => _currentIndex = i),
                      itemBuilder:
                          (context, idx) => ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              images[idx],
                              fit: BoxFit.cover,
                              width: size,
                              height: size,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 14,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap:
                            widget.userLiked
                                ? widget.onUnlikeClick
                                : widget.onLikeClick,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.16),
                          ),
                          padding: const EdgeInsets.all(7),
                          child: Icon(
                            widget.userLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: widget.userLiked ? Colors.red : Colors.white,
                            size: 27,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              dotIndexes.map((i) {
                                final isActive = i == _currentIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: isActive ? 10 : 7,
                                  height: isActive ? 10 : 7,
                                  decoration: BoxDecoration(
                                    color:
                                        isActive
                                            ? Colors.white
                                            : Colors.white54,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _handleTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Text(
                  widget.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme[AppStrings.secondaryColor],
                    fontSize: 25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            GestureDetector(
              onTap: _handleTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 2.0,
                  vertical: 2,
                ),
                child: Text(
                  '\$${widget.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ArtistCard extends StatelessWidget {
  final String profileImageUrl;
  final String name;
  final double price;
  final String userId;
  final String currentUserId;
  final bool userLiked;
  final VoidCallback onLikeClick;
  final VoidCallback onUnlikeClick;
  final VoidCallback toggleFavoritesDialog;
  final GoRouter goRouter;

  const ArtistCard({
    required this.profileImageUrl,
    required this.name,
    required this.price,
    required this.userId,
    required this.currentUserId,
    required this.userLiked,
    required this.onLikeClick,
    required this.onUnlikeClick,
    required this.toggleFavoritesDialog,
    required this.goRouter,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme[AppStrings.primaryColorLight],
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Provider.of<UserProvider>(
            context,
            listen: false,
          ).setOtherUserId(userId);
          goRouter.push(AppStrings.profileArtistScreenWSRoute);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      profileImageUrl,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            width: double.infinity,
                            height: 120,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              color: Colors.grey[600],
                              size: 40,
                            ),
                          ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: userLiked ? onUnlikeClick : onLikeClick,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          userLiked ? Icons.favorite : Icons.favorite_border,
                          color: userLiked ? Colors.red : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme[AppStrings.secondaryColor],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme[AppStrings.essentialColor],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
