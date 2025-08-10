/*
 * Fecha de creación: 26/04/2025
 * Autor: KingdomOfJames
 *
 * Descripción:
 * Este código representa la pantalla de cabecera de perfil de un artista en una aplicación de música.
 * Muestra información básica del usuario, como su nombre, apodo y foto de perfil.
 * Además, incluye botones de acción para guardar al usuario en favoritos y contactar con él mediante un chat.
 * También proporciona opciones para reportar o bloquear al usuario, así como para compartir o copiar el enlace de su perfil.
 *
 * Recomendaciones:
 * - Asegúrate de que los datos del perfil estén correctamente cargados desde la base de datos (Firestore).
 * - Si el perfil no tiene foto, asegúrate de mostrar una imagen predeterminada de usuario.
 * - Las funciones de reportar y bloquear deben estar adecuadamente gestionadas en la base de datos para que los usuarios puedan interactuar de manera segura.
 *
 * Características:
 * - Botón de "Atrás" para navegar a la pantalla anterior.
 * - Visualización de foto de perfil con opción de cambiarla o verla en grande.
 * - Menú desplegable para opciones adicionales: reportar, bloquear, compartir, copiar URL.
 * - Funciones de interacción con el perfil: guardar en favoritos y contactar por mensaje.
 * - Soporte para personalizar el tema visual según el esquema de colores de la aplicación.
 */
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import 'package:live_music/data/sources/local/internal_data_base.dart';
import 'package:live_music/presentation/screens/search_fun/profile_artist_ws/menuComponents/aviability_content.ws.dart';
import 'package:live_music/presentation/screens/search_fun/profile_artist_ws/menuComponents/dates_ws.dart';
import 'package:live_music/presentation/screens/search_fun/profile_artist_ws/menuComponents/review_content_ws.dart';
import 'package:live_music/presentation/screens/search_fun/profile_artist_ws/menuComponents/service_profile_view_screen.dart';
import 'package:live_music/presentation/screens/search_fun/profile_artist_ws/menuComponents/work_content_ws.dart';

import 'package:live_music/presentation/widgets/bottom_list_creator_dialog.dart';
import 'package:live_music/presentation/widgets/bottom_save_to_favorites_dialog.dart';
import 'package:live_music/presentation/widgets/save_message.dart';
import 'package:provider/provider.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../../../../data/provider_logics/user/user_provider.dart';
import '../../../../data/model/profile/image_data.dart';
import '../../../../data/repositories/render_http_client/images/upload_work_image.dart';
import '../../../widgets/search/profile_artist_ws/button_row_ws.dart';
import '../../buttom_navigation_bar.dart';

import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/resources/colors.dart';

class ProfileHeaderWS extends StatefulWidget {
  final ArtistProfileScreenWSState state;
  final GoRouter goRouter;
  final UserProvider userProvider;

  const ProfileHeaderWS({
    Key? key,
    required this.state,
    required this.goRouter,
    required this.userProvider,
  }) : super(key: key);

  @override
  _ProfileHeaderState createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeaderWS> {
  String reportContent = "";
  bool showReportForm = false;
  bool showBlockDialog = false;
  String? _currentProfileId; // Almacena localmente el ID del perfil actual
  Map<String, dynamic> _profileData = {}; // Cache local de datos del perfil

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    // Obtener el ID actual del provider
    final currentProfileId = widget.userProvider.otherUserId;
    if (currentProfileId == null) return;

    // Guardar localmente el ID del perfil
    _currentProfileId = currentProfileId;

    // Cargar datos del perfil específico
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentProfileId)
            .get();

    if (doc.exists) {
      setState(() {
        _profileData = {
          'userName': doc.get('name'),
          'nickname': doc.get('nickname'),
          'profileImageUrl': doc.get('profileImageUrl'),
        };
      });
    }
  }

  @override
  void didUpdateWidget(ProfileHeaderWS oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userProvider.otherUserId != _currentProfileId) {
      _loadProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final colorScheme = ColorPalette.getPalette(context);

    // Usar datos locales en lugar de los del provider directamente
    final userName = _profileData['userName'] ?? 'Cargando...';
    final nickname = _profileData['nickname'] ?? '';
    final profileImageUrl = _profileData['profileImageUrl'] ?? '';
    final isUserLiked =
        _currentProfileId != null
            ? favoritesProvider.isUserLiked(_currentProfileId!)
            : false;

    return Container(
      color: colorScheme[AppStrings.primaryColorLight],
      child: Padding(
        padding: const EdgeInsets.only(top: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    child: ClipOval(
                      child:
                          (profileImageUrl.isNotEmpty)
                              ? CachedNetworkImage(
                                imageUrl: profileImageUrl,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              )
                              : SvgPicture.asset(
                                AppStrings.defaultUserImagePath,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                    onPressed: () => _showOptionsDialog(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),
            Text(
              userName,
              style: TextStyle(
                fontSize: 24,
                color: colorScheme[AppStrings.secondaryColor],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              "@$nickname",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),
            if (_currentProfileId != null && currentUserId != null)
              _buildActionButtons(
                context,
                widget.state,
                favoritesProvider,
                currentUserId,
                _currentProfileId!,
                colorScheme,
                isUserLiked,
              ),
          ],
        ),
      ),
    );
  }

  // Resto de los métodos permanecen iguales, pero usando _currentProfileId en lugar de userProvider.otherUserId
  void _showOptionsDialog(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    showDialog(
      context: context,
      builder:
          (_) => SimpleDialog(
            backgroundColor: colorScheme[AppStrings.primaryColor],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            children: [
              SimpleDialogOption(
                child: Text(
                  AppStrings.reportOption,
                  style: TextStyle(
                    fontSize: 18,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showReportDialog(context);
                },
              ),
              SimpleDialogOption(
                child: Text(
                  AppStrings.blockOption,
                  style: TextStyle(
                    fontSize: 18,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showBlockDialog(context);
                },
              ),
              SimpleDialogOption(
                child: Text(
                  AppStrings.shareProfileOption,
                  style: TextStyle(
                    fontSize: 18,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: acción de compartir
                },
              ),
              SimpleDialogOption(
                child: Text(
                  AppStrings.copyProfileUrlOption,
                  style: TextStyle(
                    fontSize: 18,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: acción de copiar URL
                },
              ),
              SimpleDialogOption(
                child: Text(
                  AppStrings.cancelOption,
                  style: TextStyle(
                    fontSize: 18,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null || _currentProfileId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: colorScheme[AppStrings.primaryColor],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.blockUserTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.confirmBlockUser,
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          AppStrings.cancel,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme[AppStrings.essentialColor],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () {
                          widget.userProvider.blockUser(
                            currentUserId,
                            _currentProfileId!,
                          );
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor:
                              colorScheme[AppStrings.essentialColor],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          AppStrings.accept,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme[AppStrings.primaryColor],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null || _currentProfileId == null) return;

    final TextEditingController reportController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: colorScheme[AppStrings.primaryColor],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.reportDescription,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reportController,
                    decoration: InputDecoration(
                      labelText: AppStrings.description,
                      labelStyle: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorScheme[AppStrings.secondaryColor]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorScheme[AppStrings.essentialColor]!,
                        ),
                      ),
                    ),
                    maxLines: 5,
                    style: TextStyle(
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          AppStrings.cancel,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme[AppStrings.essentialColor],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () {
                          if (reportController.text.isNotEmpty) {
                            _sendReport(
                              currentUserId,
                              _currentProfileId!,
                              reportController.text,
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor:
                              colorScheme[AppStrings.essentialColor],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          AppStrings.send,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme[AppStrings.primaryColor],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _sendReport(
    String currentUserId,
    String otherUserId,
    String content,
  ) async {
    if (content.isEmpty) return;

    try {
      DocumentSnapshot currentUserSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();

      String currentUserName =
          currentUserSnapshot.exists
              ? currentUserSnapshot.get('name')
              : 'Unknown User';

      await FirebaseFirestore.instance
          .collection('reports')
          .doc(currentUserId)
          .set({
            'reporter_name': currentUserName,
            'reported_user_id': otherUserId,
            'report_content': content,
            'timestamp': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reporte enviado exitosamente')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al enviar el reporte: $e')));
    }
  }

  Widget _buildActionButtons(
    BuildContext context,
    ArtistProfileScreenWSState state,
    FavoritesProvider favoritesProvider,
    String currentUserId,
    String otherUserId,
    Map<String, Color> colorScheme,
    bool isUserLiked,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme[AppStrings.primaryColor],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            minimumSize: const Size(125, 35),
          ),
          onPressed: () => state.handleSave(),
          child: Row(
            children: [
              Icon(
                Icons.favorite,
                color:
                    isUserLiked
                        ? colorScheme[AppStrings.essentialColor]
                        : colorScheme[AppStrings.secondaryColor],
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.save,
                style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme[AppStrings.essentialColor],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            minimumSize: const Size(125, 35),
          ),
          onPressed: () => widget.goRouter.push(AppStrings.chatScreenRoute),
          child: Row(
            children: [
              Icon(Icons.message, color: Colors.white, size: 15),
              const SizedBox(width: 6),
              Text(
                AppStrings.contactUser,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ArtistProfileScreenWS extends StatefulWidget {
  final GoRouter goRouter;
  final UserProvider userProvider;
  final FavoritesProvider favoritesProvider;

  const ArtistProfileScreenWS({
    required this.goRouter,
    required this.userProvider,
    required this.favoritesProvider,
    Key? key,
  }) : super(key: key);

  @override
  ArtistProfileScreenWSState createState() => ArtistProfileScreenWSState();
}

class ArtistProfileScreenWSState extends State<ArtistProfileScreenWS> {
  late final String otherUserId;
  late final UploadWorkMediaToServer uploadWorkImagesToServer;
  final showImageDetail = ValueNotifier<ImageData?>(null);
  final selectedButtonIndex = ValueNotifier<String>(
    AppStrings.servicesSelectionWS,
  ); // Cambiado a servicios por defecto
  late final ValueNotifier<String?> menuSelectionNotifier;

  bool showConfirmRemoveDialog = false;
  bool showSaveMessage = false;
  LikedUsersList? selectedList;
  bool showBottomSaveDialog = false;
  bool showBottomFavoritesListCreatorDialog = false;

  @override
  void initState() {
    super.initState();
    otherUserId = widget.userProvider.otherUserId;
    menuSelectionNotifier = ValueNotifier(
      widget.userProvider.menuSelection ?? AppStrings.servicesSelectionWS,
    ); // Valor por defecto servicios
    uploadWorkImagesToServer = UploadWorkMediaToServer();

    // Registrar estadísticas de visualización
    final startDateMillis = DateTime.now().millisecondsSinceEpoch;
    widget.userProvider.uploadStatistics(otherUserId, startDateMillis);
  }

  void handleSave() {
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );
    final likedLists = favoritesProvider.likedUsersListsValue;
    final isLiked = favoritesProvider.isUserLiked(otherUserId);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (isLiked) {
      setState(() => showConfirmRemoveDialog = true);
    } else {
      if (likedLists.isEmpty) {
        setState(() => showBottomFavoritesListCreatorDialog = true);
      } else if (likedLists.length == 1) {
        final list = likedLists.first;
        favoritesProvider.addUserToList(list.listId, otherUserId);
        setState(() {
          selectedList = list;
          showSaveMessage = true;
          if (currentUserId != null) {
            favoritesProvider.onLikeClick(otherUserId, currentUserId);
          }
        });
      } else {
        setState(() => showBottomSaveDialog = true);
      }
    }
  }

  void _onUserAddedToList(LikedUsersList list) {
    setState(() {
      selectedList = list;
      showSaveMessage = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userType = widget.userProvider.userType;
    final isArtist = widget.userProvider.userType == AppStrings.artist;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final colorScheme = ColorPalette.getPalette(context);

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColorLight],
      bottomNavigationBar: BottomNavigationBarWidget(
        userType: userType,
        goRouter: widget.goRouter,
      ),
      body: SafeArea(
        bottom: false, // Solo protege la parte superior
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Cabecera del perfil con SafeArea integrado
                SliverAppBar(
                  expandedHeight: 280.0,
                  pinned: true,
                  backgroundColor: colorScheme[AppStrings.primaryColorLight],
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                    onPressed: () => widget.goRouter.pop(),
                  ),
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      return FlexibleSpaceBar(
                        background: ProfileHeaderWS(
                          state: this,
                          goRouter: widget.goRouter,
                          userProvider: widget.userProvider,
                        ),
                      );
                    },
                  ),
                ),

                // Fila de botones de navegación
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<String>(
                    valueListenable: selectedButtonIndex,
                    builder: (context, _, __) {
                      return ButtonRowWS(
                        selectedButtonIndex: selectedButtonIndex,
                        onButtonSelect: (selection) {
                          selectedButtonIndex.value = selection;
                          widget.userProvider.setMenuSelection(selection);
                          menuSelectionNotifier.value = selection;
                        },
                        userProvider: widget.userProvider,
                      );
                    },
                  ),
                ),

                // Contenido principal dinámico
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<String?>(
                    valueListenable: menuSelectionNotifier,
                    builder: (context, value, _) {
                      switch (value) {
                        case AppStrings
                            .servicesSelectionWS: // Nuevo caso para servicios
                          return ServicesProfileViewScreen(
                            userId: otherUserId,
                            goRouter: widget.goRouter,
                          );
                        case AppStrings.worksSelectionWS:
                          return WorksContentWS();
                        case AppStrings.availabilitySelectionWS:
                          return AvailabilityContentWS(userId: otherUserId);
                        case AppStrings.informationSelectionWS:
                          return DatesContentWS();
                        case AppStrings.reviewsSelectionWS:
                          return ReviewsContentWS(otherUserId: otherUserId);
                        default:
                          return ServicesProfileViewScreen(
                            userId: otherUserId,
                            goRouter: widget.goRouter,
                          ); // Valor por defecto ahora es servicios
                      }
                    },
                  ),
                ),
              ],
            ),

            // Diálogos y overlays (se muestran sobre el contenido)
            if (showConfirmRemoveDialog) _buildConfirmRemoveDialog(context),
            if (showBottomSaveDialog)
              BottomSaveToFavoritesDialog(
                onDismiss: () => setState(() => showBottomSaveDialog = false),
                onCreateNewList: () {
                  setState(() {
                    showBottomSaveDialog = false;
                    showBottomFavoritesListCreatorDialog = true;
                  });
                  if (otherUserId != null && currentUserId != null) {
                    widget.favoritesProvider.onLikeClick(
                      otherUserId,
                      currentUserId,
                    );
                  }
                },
                favoritesProvider: widget.favoritesProvider,
                userIdToSave: otherUserId,
                onUserAddedToList: _onUserAddedToList,
                onLikeClick: () {
                  if (otherUserId != null && currentUserId != null) {
                    widget.favoritesProvider.onLikeClick(
                      otherUserId,
                      currentUserId,
                    );
                  }
                },
              ),
            if (showBottomFavoritesListCreatorDialog)
              BottomFavoritesListCreatorDialog(
                userId: otherUserId,
                onDismiss:
                    () => setState(
                      () => showBottomFavoritesListCreatorDialog = false,
                    ),
                favoritesProvider: widget.favoritesProvider,
                onLikeClick: () {
                  if (otherUserId != null && currentUserId != null) {
                    widget.favoritesProvider.onLikeClick(
                      otherUserId,
                      currentUserId,
                    );
                  }
                },
              ),
            if (showSaveMessage && selectedList != null)
              SaveMessage(
                list: selectedList!,
                onModifyClick: () {
                  setState(() {
                    showSaveMessage = false;
                    showBottomSaveDialog = true;
                  });
                  if (otherUserId != null && currentUserId != null) {
                    widget.favoritesProvider.onLikeClick(
                      otherUserId,
                      currentUserId,
                    );
                  }
                },
                isVisible: showSaveMessage,
                onDismiss: () {
                  setState(() => showSaveMessage = false);
                  if (otherUserId != null && currentUserId != null) {
                    widget.favoritesProvider.onLikeClick(
                      otherUserId,
                      currentUserId,
                    );
                  }
                },
                favoritesProvider: widget.favoritesProvider,
                userIdToRemove: otherUserId,
                onLikeClick: () {
                  if (otherUserId != null && currentUserId != null) {
                    widget.favoritesProvider.onLikeClick(
                      otherUserId,
                      currentUserId,
                    );
                  }
                },
                onUnlikeClick: () {
                  if (otherUserId != null) {
                    widget.favoritesProvider.onUnlikeClick(otherUserId);
                  }
                },
                currentUserId:
                    currentUserId ?? '', // Provide default value if null
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmRemoveDialog(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final userName = widget.userProvider.userName;

    return AlertDialog(
      title: Text(
        AppStrings.confirmationTitle,
        style: TextStyle(color: colorScheme[AppStrings.primaryColorLight]),
      ),
      content: Text(
        AppStrings.removeFavoriteConfirm.replaceFirst('%s', userName),
        style: TextStyle(color: colorScheme[AppStrings.primaryColorLight]),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => showConfirmRemoveDialog = false),
          style: TextButton.styleFrom(
            backgroundColor: colorScheme[AppStrings.grayColor],
          ),
          child: Text(
            AppStrings.cancel,
            style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
          ),
        ),
        TextButton(
          onPressed: () {
            widget.favoritesProvider.onUnlikeClick(otherUserId);
            setState(() => showConfirmRemoveDialog = false);
          },
          style: TextButton.styleFrom(
            backgroundColor: colorScheme[AppStrings.primaryColorLight],
          ),
          child: Text(
            AppStrings.remove,
            style: TextStyle(color: colorScheme[AppStrings.primaryColorLight]),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Limpiar controladores
    showImageDetail.dispose();
    selectedButtonIndex.dispose();
    menuSelectionNotifier.dispose();
    super.dispose();
  }
}
