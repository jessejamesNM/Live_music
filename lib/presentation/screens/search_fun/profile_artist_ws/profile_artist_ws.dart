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
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import 'package:live_music/data/sources/local/internal_data_base.dart';
import 'package:live_music/presentation/screens/search_fun/profile_artist_ws/menuComponents/aviability_content.ws.dart';
import 'package:live_music/presentation/screens/search_fun/profile_artist_ws/menuComponents/dates_ws.dart';
import 'package:live_music/presentation/screens/search_fun/profile_artist_ws/menuComponents/review_content_ws.dart';
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

  @override
  void initState() {
    super.initState();
    // Detener/listener según tu lógica original...
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final otherUserId = userProvider.otherUserId;
    final currentUserId = userProvider.currentUserId;
    final userName = userProvider.userName;
    final nickname = userProvider.nickname;
    final profileImageUrl = userProvider.profileImageUrl;
    final colorScheme = ColorPalette.getPalette(context);
    final isUserLiked = favoritesProvider.isUserLiked(otherUserId);

    return Container(
      color: colorScheme[AppStrings.primaryColorLight],
      child: Padding(
        padding: const EdgeInsets.only(top: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                // Flecha atrás personalizada

                // Avatar
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    child: ClipOval(
                      child:
                          (profileImageUrl != null &&
                                  profileImageUrl.isNotEmpty)
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
                // Menú de opciones como diálogo
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

            // Si decides mantener el form/report inline, aquí lo puedes dejar:
            if (showBlockDialog)
              _buildBlockDialog(context, currentUserId, otherUserId),
            if (showReportForm)
              _buildReportForm(context, currentUserId, otherUserId),

            const SizedBox(height: 8),
            _buildActionButtons(
              context,
              widget.state,
              favoritesProvider,
              currentUserId,
              otherUserId,
              colorScheme,
              isUserLiked,
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    showDialog(
      context: context,
      builder:
          (_) => SimpleDialog(
            backgroundColor: colorScheme[AppStrings.primaryColor], // Fondo
            children: [
              SimpleDialogOption(
                child: Text(
                  AppStrings.reportOption,
                  style: TextStyle(
                    fontSize: 18,
                    color:
                        colorScheme[AppStrings
                            .secondaryColor], // Color de texto
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    showReportForm = true;
                    showBlockDialog = false;
                  });
                },
              ),
              SimpleDialogOption(
                child: Text(
                  AppStrings.blockOption,
                  style: TextStyle(
                    fontSize: 18,
                    color:
                        colorScheme[AppStrings
                            .secondaryColor], // Color de texto
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    showBlockDialog = true;
                    showReportForm = false;
                  });
                },
              ),
              SimpleDialogOption(
                child: Text(
                  AppStrings.shareProfileOption,
                  style: TextStyle(
                    fontSize: 18,
                    color:
                        colorScheme[AppStrings
                            .secondaryColor], // Color de texto
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
                    color:
                        colorScheme[AppStrings
                            .secondaryColor], // Color de texto
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
                    color:
                        colorScheme[AppStrings
                            .secondaryColor], // Color de texto
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  Widget _buildBlockDialog(
    BuildContext context,
    String currentUserId,
    String otherUserId,
  ) {
    final colorScheme = ColorPalette.getPalette(context);

    return AlertDialog(
      backgroundColor: colorScheme[AppStrings.primaryColor], // Fondo
      title: Text(
        AppStrings.blockUserTitle,
        style: TextStyle(
          fontSize: 20,
          color: colorScheme[AppStrings.secondaryColor], // Color de texto
        ),
      ),
      content: Text(
        AppStrings.confirmBlockUser,
        style: TextStyle(
          fontSize: 18,
          color: colorScheme[AppStrings.secondaryColor], // Color de texto
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  fontSize: 18,
                  color:
                      colorScheme[AppStrings.essentialColor], // Color del botón
                ),
              ),
              onPressed: () => setState(() => showBlockDialog = false),
            ),
            TextButton(
              child: Text(
                AppStrings.accept,
                style: TextStyle(
                  fontSize: 18,
                  color:
                      colorScheme[AppStrings.essentialColor], // Color del botón
                ),
              ),
              onPressed: () {
                widget.userProvider.blockUser(currentUserId, otherUserId);
                setState(() => showBlockDialog = false);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportForm(
    BuildContext context,
    String currentUserId,
    String otherUserId,
  ) {
    final colorScheme = ColorPalette.getPalette(context);

    return AlertDialog(
      backgroundColor: colorScheme[AppStrings.primaryColor], // Fondo
      title: Text(
        AppStrings.reportDescription,
        style: TextStyle(
          fontSize: 20,
          color: colorScheme[AppStrings.secondaryColor], // Color de texto
        ),
      ),
      content: TextField(
        decoration: InputDecoration(
          labelText: AppStrings.description,
          labelStyle: TextStyle(
            fontSize: 18,
            color:
                colorScheme[AppStrings.secondaryColor], // Color de la etiqueta
          ),
        ),
        onChanged: (val) => reportContent = val,
        style: TextStyle(
          fontSize: 18,
          color: colorScheme[AppStrings.secondaryColor], // Color del texto
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  fontSize: 18,
                  color:
                      colorScheme[AppStrings.essentialColor], // Color del botón
                ),
              ),
              onPressed: () => setState(() => showReportForm = false),
            ),
            TextButton(
              onPressed:
                  reportContent.isNotEmpty
                      ? () => _sendReport(currentUserId, otherUserId)
                      : null,
              child: Text(
                AppStrings.send,
                style: TextStyle(
                  fontSize: 18,
                  color:
                      colorScheme[AppStrings.essentialColor], // Color del botón
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _sendReport(String currentUserId, String otherUserId) async {
    if (reportContent.isNotEmpty) {
      try {
        // Obtén el nombre del usuario que está reportando desde Firestore
        DocumentSnapshot currentUserSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .get();

        String currentUserName =
            currentUserSnapshot.exists
                ? currentUserSnapshot.get(
                  'name',
                ) // Asegúrate de que el campo 'name' exista
                : 'Unknown User';

        // Crear un nuevo reporte en Firestore en la colección 'reports'
        await FirebaseFirestore.instance
            .collection('reports')
            .doc(currentUserId)
            .set({
              'reporter_name': currentUserName,
              'reported_user_id': otherUserId,
              'report_content': reportContent,
              'timestamp': FieldValue.serverTimestamp(),
            });

        // Ocultar el formulario de reporte
        setState(() => showReportForm = false);

        // Opcional: mostrar un mensaje de éxito (puedes usar un snackbar, por ejemplo)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Reporte enviado exitosamente')));
      } catch (e) {
        // En caso de error, muestra un mensaje (puedes ajustarlo según lo que prefieras)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar el reporte: $e')),
        );
      }
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
              Icon(
                Icons.message,
                color: colorScheme[AppStrings.secondaryColor],
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.contactUser,
                style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
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
  final selectedButtonIndex = ValueNotifier<String>(AppStrings.worksContent);
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
    menuSelectionNotifier = ValueNotifier(widget.userProvider.menuSelection);
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
    final currentUserId = widget.userProvider.currentUserId;

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
          favoritesProvider.onLikeClick(otherUserId, currentUserId);
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
    final isArtist = widget.userProvider.userType == AppStrings.artist;
    final currentUserId = widget.userProvider.currentUserId;
    final colorScheme = ColorPalette.getPalette(context);

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColorLight],
      bottomNavigationBar: BottomNavigationBarWidget(
        isArtist: isArtist,
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
                        case AppStrings.worksSelectionWS:
                          return WorksContentWS();
                        case AppStrings.availabilitySelectionWS:
                          return AvailabilityContentWS(userId: otherUserId);
                        case AppStrings.informationSelectionWS:
                          return DatesContentWS();
                        case AppStrings.reviewsSelectionWS:
                          return ReviewsContentWS(otherUserId: otherUserId);
                        default:
                          return WorksContentWS();
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
                  widget.favoritesProvider.onLikeClick(
                    otherUserId,
                    currentUserId,
                  );
                },
                favoritesProvider: widget.favoritesProvider,
                userIdToSave: otherUserId,
                onUserAddedToList: _onUserAddedToList,
                onLikeClick: () {
                  widget.favoritesProvider.onLikeClick(
                    otherUserId,
                    currentUserId,
                  );
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
                  widget.favoritesProvider.onLikeClick(
                    otherUserId,
                    currentUserId,
                  );
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
                  widget.favoritesProvider.onLikeClick(
                    otherUserId,
                    currentUserId,
                  );
                },
                isVisible: showSaveMessage,
                onDismiss: () {
                  setState(() => showSaveMessage = false);
                  widget.favoritesProvider.onLikeClick(
                    otherUserId,
                    currentUserId,
                  );
                },
                favoritesProvider: widget.favoritesProvider,
                userIdToRemove: otherUserId,
                onLikeClick: () {
                  widget.favoritesProvider.onLikeClick(
                    otherUserId,
                    currentUserId,
                  );
                },
                onUnlikeClick: () {
                  widget.favoritesProvider.onUnlikeClick(otherUserId);
                },
                currentUserId: currentUserId,
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