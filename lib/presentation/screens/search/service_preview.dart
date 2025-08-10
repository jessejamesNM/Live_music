import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:live_music/data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
import 'package:live_music/data/repositories/render_http_client/images/upload_service_services.dart';
import 'package:live_music/data/sources/local/internal_data_base.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/widgets/bottom_list_creator_dialog.dart';
import 'package:live_music/presentation/widgets/bottom_save_to_favorites_dialog.dart';
import 'package:live_music/presentation/widgets/save_message.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class ServicePreview extends StatefulWidget {
  final GoRouter goRouter;

  const ServicePreview({super.key, required this.goRouter});

  @override
  State<ServicePreview> createState() => _ServicePreviewState();
}

class _ServicePreviewState extends State<ServicePreview> {
  late List<String> _localImageUrls;
  late PageController _pageController;
  int _currentPageIndex = 0;
  bool _isLoadingImages = false;
  List<Map<String, dynamic>> _packages = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedPackageIndex = 0;
  late TextEditingController _priceController;
  late TextEditingController _informationController;
  bool _isPriceExpanded = true;
  bool _isInformationExpanded = true;
  late String otherUserId;
  late String currentUserId;
  bool _isLoading = true;
  LikedUsersList? _selectedList;
  bool _showSaveMessage = false;
  bool _showBottomSaveDialog = false;
  bool _showBottomFavoritesListCreatorDialog = false;
  bool _showConfirmRemoveDialog = false;

  // Datos del usuario
  String? _profileImageUrl;
  String? _artistName;
  bool _loadingProfile = true;

  // Para el preview de imágenes
  bool _showImagePreview = false;
  int _previewInitialIndex = 0;
  List<String> _allPreviewImages = [];
  bool _loadingPreviewImages = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _localImageUrls = [];
    _priceController = TextEditingController();
    _informationController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final favoritesProvider = Provider.of<FavoritesProvider>(
        context,
        listen: false,
      );
      otherUserId = userProvider.otherUserId;

      final currentUser = FirebaseAuth.instance.currentUser;
      currentUserId = currentUser?.uid ?? '';

      if (currentUser != null) {
        favoritesProvider.startLikedUsersListener(currentUserId, otherUserId);
      }

      await _loadArtistProfile();
      await _loadAllPackages();
      setState(() => _isLoading = false);
    });

    _pageController.addListener(_updateCurrentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _priceController.dispose();
    _informationController.dispose();
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );
    favoritesProvider.stopLikedUsersListener(otherUserId);
    super.dispose();
  }

  void _updateCurrentPageIndex() {
    if (_pageController.page != null &&
        _pageController.page!.round() != _currentPageIndex) {
      setState(() {
        _currentPageIndex = _pageController.page!.round();
      });
    }
  }

  Future<void> _loadArtistProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final userDoc =
          await _firestore.collection('users').doc(otherUserId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _profileImageUrl = data?['profileImageUrl'] as String?;
          _artistName = data?['name'] as String? ?? '';
          _loadingProfile = false;
        });
      } else {
        setState(() {
          _profileImageUrl = null;
          _artistName = '';
          _loadingProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        _profileImageUrl = null;
        _artistName = '';
        _loadingProfile = false;
      });
    }
  }

  Future<void> _loadAllPackages() async {
    try {
      final List<Map<String, dynamic>> allPackages = [];

      for (int i = 0; i < 8; i++) {
        final docRef = _firestore
            .collection('services')
            .doc(otherUserId)
            .collection('service')
            .doc('service$i');

        final snapshot = await docRef.get();

        if (snapshot.exists) {
          final data = snapshot.data()!;
          allPackages.add({
            'id': snapshot.id,
            'index': i,
            'price': data['price'] ?? 0,
            'information': data['information'] ?? '',
            'imageList': List.from(data['imageList'] ?? []),
          });
        }
      }

      setState(() {
        _packages =
            allPackages..sort(
              (a, b) => (a['price'] as num).compareTo(b['price'] as num),
            );
        if (_packages.isNotEmpty) {
          _selectedPackageIndex = _packages.first['index'];
          _loadPackageData(_packages.first);
        }
      });
    } catch (e) {
      debugPrint('Error loading packages: $e');
      setState(() {
        _packages = [];
        _isLoading = false;
      });
    }
  }

  void _loadPackageData(Map<String, dynamic> package) {
    setState(() {
      _priceController.text = package['price']?.toString() ?? '0';
      _informationController.text = package['information'] ?? '';
      _localImageUrls = List.from(package['imageList'] ?? []);
      _currentPageIndex = 0;

      if (_pageController.hasClients && _localImageUrls.isNotEmpty) {
        _pageController.jumpToPage(0);
      }
    });
  }

  Future<void> _selectPackage(int index) async {
    final selectedPackage = _packages.firstWhere(
      (pkg) => pkg['index'] == index,
      orElse:
          () => {
            'price': 0,
            'information': '',
            'imageList': [],
            'index': index,
          },
    );

    setState(() => _selectedPackageIndex = index);
    _loadPackageData(selectedPackage);
  }

  void _toggleInformationVisibility() {
    setState(() => _isInformationExpanded = !_isInformationExpanded);
  }

  void _handleSave() {
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );
    final isLiked = favoritesProvider.isUserLiked(otherUserId);
    final likedLists = favoritesProvider.likedUsersListsValue;

    if (isLiked) {
      setState(() => _showConfirmRemoveDialog = true);
    } else {
      if (likedLists.isEmpty) {
        setState(() => _showBottomFavoritesListCreatorDialog = true);
      } else if (likedLists.length == 1) {
        final list = likedLists.first;
        favoritesProvider.addUserToList(list.listId, otherUserId);
        setState(() {
          _selectedList = list;
          _showSaveMessage = true;
        });
      } else {
        setState(() => _showBottomSaveDialog = true);
      }
    }
  }

  void _onUserAddedToList(LikedUsersList list) {
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    favoritesProvider.addUserToList(list.listId, otherUserId);
    favoritesProvider.onLikeClick(otherUserId, currentUserId);
    userProvider.addLikes(otherUserId);

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

    setState(() => _showConfirmRemoveDialog = false);
    favoritesProvider.onUnlikeClick(otherUserId);
  }

  Widget _buildProfileRow(
    BuildContext context,
    Map<String, Color?> colorScheme,
    UserProvider userProvider,
  ) {
    if (_loadingProfile) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Imagen y nombre
            GestureDetector(
              onTap: () {
                widget.goRouter.push(AppStrings.profileArtistScreenWSRoute);
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                    backgroundColor: colorScheme[AppStrings.primaryColorLight]!
                        .withOpacity(0.4),
                    child:
                        _profileImageUrl == null || _profileImageUrl!.isEmpty
                            ? Icon(
                              Icons.person,
                              color: colorScheme[AppStrings.secondaryColor],
                            )
                            : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _artistName ?? '',
                    style: TextStyle(
                      color: colorScheme[AppStrings.secondaryColor],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Botón de contactar
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  userProvider.setOtherUserId(otherUserId);
                  widget.goRouter.push(AppStrings.chatScreenRoute);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme[AppStrings.essentialColor],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.message, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.contact,
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAllImagesPreview(int initialIndex) async {
    setState(() => _loadingPreviewImages = true);
    final allImages = await _fetchAllImagesFromAllPackages();
    setState(() {
      _allPreviewImages = allImages;
      _loadingPreviewImages = false;
      _showImagePreview = true;
      _previewInitialIndex = initialIndex;
    });
  }

  Future<List<String>> _fetchAllImagesFromAllPackages() async {
    try {
      final List<Map<String, dynamic>> packageList = [];
      final serviceCollection = _firestore
          .collection('services')
          .doc(otherUserId)
          .collection('service');

      final snapshot = await serviceCollection.get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        packageList.add({
          'price': data['price'] ?? 0,
          'imageList': List.from(data['imageList'] ?? []),
        });
      }

      packageList.sort(
        (a, b) => (a['price'] as num).compareTo(b['price'] as num),
      );
      return packageList
          .expand((pkg) => List<String>.from(pkg['imageList']))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all images for preview: $e');
      return [];
    }
  }

  Widget _buildFullScreenImagePreview(BuildContext context) {
    return _loadingPreviewImages
        ? const Center(child: CircularProgressIndicator())
        : GestureDetector(
          onTap: () => setState(() => _showImagePreview = false),
          child: Container(
            color: Colors.black.withOpacity(0.98),
            child: Stack(
              children: [
                PageView.builder(
                  controller: PageController(initialPage: _previewInitialIndex),
                  itemCount: _allPreviewImages.length,
                  onPageChanged:
                      (i) => setState(() => _previewInitialIndex = i),
                  itemBuilder: (context, index) {
                    final url = _allPreviewImages[index];
                    return Center(
                      child: InteractiveViewer(
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (_, __, ___) => Icon(
                                Icons.broken_image_rounded,
                                color: Colors.white70,
                                size: 120,
                              ),
                          loadingBuilder:
                              (_, child, progress) =>
                                  progress == null
                                      ? child
                                      : const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 34,
                    ),
                    onPressed: () => setState(() => _showImagePreview = false),
                  ),
                ),
                Positioned(
                  bottom: 36,
                  right: 16,
                  left: 16,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_previewInitialIndex + 1}/${_allPreviewImages.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isLiked = favoritesProvider.isUserLiked(otherUserId);

    if (_showSaveMessage) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showSaveMessage = false);
      });
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme[AppStrings.primaryColor],
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              colorScheme[AppStrings.secondaryColor]!,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: SafeArea(
        top: true,
        child: Stack(
          children: [
            ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                AspectRatio(
                  aspectRatio: 1 / 1,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        color: colorScheme[AppStrings.primaryColorLight]
                            ?.withOpacity(0.1),
                        child:
                            _isLoadingImages
                                ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme[AppStrings.secondaryColor]!,
                                    ),
                                  ),
                                )
                                : (_localImageUrls.isNotEmpty
                                    ? GestureDetector(
                                      onTap: () {
                                        if (_localImageUrls.isNotEmpty) {
                                          _showAllImagesPreview(
                                            _findGlobalImageIndex(),
                                          );
                                        }
                                      },
                                      child: PageView.builder(
                                        controller: _pageController,
                                        itemCount: _localImageUrls.length,
                                        itemBuilder: (context, index) {
                                          return Image.network(
                                            _localImageUrls[index],
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, __, ___) => Center(
                                                  child: Icon(
                                                    Icons.broken_image_rounded,
                                                    size: 100,
                                                    color:
                                                        colorScheme[AppStrings
                                                            .secondaryColor],
                                                  ),
                                                ),
                                            loadingBuilder:
                                                (_, child, progress) =>
                                                    progress == null
                                                        ? child
                                                        : const Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                          );
                                        },
                                      ),
                                    )
                                    : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_not_supported,
                                            size: 80,
                                            color: colorScheme[AppStrings
                                                    .secondaryColor]
                                                ?.withOpacity(0.5),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'No hay imágenes para este paquete.',
                                            style: TextStyle(
                                              color: colorScheme[AppStrings
                                                      .secondaryColor]
                                                  ?.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: _handleSave,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      if (_localImageUrls.isNotEmpty && !_isLoadingImages)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_currentPageIndex + 1}/${_localImageUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildProfileRow(context, colorScheme, userProvider),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Divider(
                    color:
                        colorScheme[AppStrings.secondaryColor]?.withOpacity(
                          0.3,
                        ) ??
                        Colors.grey,
                    thickness: 1.1,
                    height: 0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    top: 16,
                    bottom: 8,
                  ),
                  child: Text(
                    'Paquetes de precios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 2,
                  ),
                  child: SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _packages.length,
                      itemBuilder: (context, index) {
                        final pkg = _packages[index];
                        final bool isSelected =
                            pkg['index'] == _selectedPackageIndex;
                        final price = pkg['price'] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: GestureDetector(
                            onTap: () => _selectPackage(pkg['index']),
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? colorScheme[AppStrings.essentialColor]
                                        : colorScheme[AppStrings
                                            .primaryColorLight],
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? colorScheme[AppStrings
                                              .secondaryColor]!
                                          : colorScheme[AppStrings
                                                  .secondaryColor]!
                                              .withOpacity(0.5),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '\$$price',
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : colorScheme[AppStrings
                                                .secondaryColor],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '¿Qué incluye este paquete?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme[AppStrings.secondaryColor],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isInformationExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: colorScheme[AppStrings.secondaryColor],
                            ),
                            onPressed: _toggleInformationVisibility,
                          ),
                        ],
                      ),
                      if (_isInformationExpanded)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TextField(
                            controller: _informationController,
                            enabled: false,
                            maxLines: 5,
                            minLines: 3,
                            keyboardType: TextInputType.multiline,
                            style: TextStyle(
                              color: colorScheme[AppStrings.secondaryColor],
                            ),
                            decoration: InputDecoration(
                              labelText: 'Información del Paquete',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              floatingLabelStyle: TextStyle(
                                color: colorScheme[AppStrings.secondaryColor],
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color:
                                      colorScheme[AppStrings.secondaryColor]!,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: colorScheme[AppStrings.secondaryColor]!
                                      .withOpacity(0.5),
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
            if (_showSaveMessage && _selectedList != null)
              SaveMessage(
                list: _selectedList!,
                onModifyClick: () {
                  setState(() {
                    _showSaveMessage = false;
                    _showBottomSaveDialog = true;
                  });
                  userProvider.addLikes(otherUserId);
                },
                isVisible: _showSaveMessage,
                onDismiss: () => setState(() => _showSaveMessage = false),
                favoritesProvider: favoritesProvider,
                userIdToRemove: otherUserId,
                onLikeClick: () => _onUserAddedToList(_selectedList!),
                onUnlikeClick:
                    () => favoritesProvider.onUnlikeClick(otherUserId),
                currentUserId: currentUserId,
              ),
            if (_showBottomSaveDialog)
              BottomSaveToFavoritesDialog(
                onDismiss: () => setState(() => _showBottomSaveDialog = false),
                onCreateNewList: () {
                  setState(() {
                    _showBottomSaveDialog = false;
                    _showBottomFavoritesListCreatorDialog = true;
                  });
                  userProvider.addLikes(otherUserId);
                },
                favoritesProvider: favoritesProvider,
                userIdToSave: otherUserId,
                onUserAddedToList: _onUserAddedToList,
                onLikeClick: () {
                  if (_selectedList != null) _onUserAddedToList(_selectedList!);
                },
              ),
            if (_showBottomFavoritesListCreatorDialog)
              BottomFavoritesListCreatorDialog(
                userId: otherUserId,
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
            if (_showConfirmRemoveDialog)
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
            if (_showImagePreview) _buildFullScreenImagePreview(context),
          ],
        ),
      ),
    );
  }

  int _findGlobalImageIndex() {
    if (_packages.isEmpty || _localImageUrls.isEmpty) return 0;
    final List<Map<String, dynamic>> sorted = List.from(_packages)
      ..sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
    final List<String> allImages = [];
    int globalIndex = 0;
    for (final pkg in sorted) {
      final imgs = List<String>.from(pkg['imageList'] ?? []);
      if (pkg['index'] == _selectedPackageIndex) {
        globalIndex += _currentPageIndex;
        break;
      } else {
        globalIndex += imgs.length;
      }
    }
    return globalIndex;
  }
}
