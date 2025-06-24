// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción: Pantalla para mostrar el perfil de un artista. Permite cargar y recortar imágenes de perfil y trabajo,
// además de mostrar información relevante como trabajos, disponibilidad, fechas y reseñas del artista.
// Recomendaciones: Verificar los permisos para acceder a la galería de imágenes en dispositivos Android/iOS.
// Características: Carga y visualización de imágenes de perfil y trabajos, interacción con los botones para cambiar el contenido,
// vista dinámica con un SliverAppBar que permite ver el encabezado del perfil al hacer scroll.

// Importaciones necesarias
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:live_music/data/provider_logics/nav_buttom_bar_components/messages/messages_provider.dart';
import 'package:live_music/data/provider_logics/nav_buttom_bar_components/profile/profile_provider.dart';
import 'package:live_music/data/provider_logics/user/review_provider.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/screens/profile/artist/profile_header.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/model/profile/image_data.dart';
import '../../../../data/provider_logics/user/user_provider.dart';
import '../../../../data/repositories/render_http_client/images/upload_profile_image.dart';
import '../../../../data/repositories/render_http_client/images/upload_work_image.dart';
import '../../buttom_navigation_bar.dart';
import 'artist_elements_bar/aviability_content.dart';
import 'artist_elements_bar/dates_content.dart';
import 'artist_elements_bar/review_content.dart';
import 'artist_elements_bar/works_content.dart';
import 'package:live_music/presentation/resources/colors.dart';

// Widget de pantalla Stateful que muestra el perfil del artista
class ProfileArtistScreen extends StatefulWidget {
  // Dependencias requeridas para el funcionamiento de la pantalla
  final UploadProfileImagesToServer uploadProfileImagesToServer;
  final UploadWorkMediaToServer uploadWorkImagesToServer;
  final GoRouter goRouter;
  final ProfileProvider profileProvider;
  final UserProvider userProvider;
  final ReviewProvider reviewProvider;
  final MessagesProvider messagesProvider;

  // Constructor que recibe todas las dependencias necesarias
  const ProfileArtistScreen({
    super.key,
    required this.uploadProfileImagesToServer,
    required this.uploadWorkImagesToServer,
    required this.goRouter,
    required this.profileProvider,
    required this.userProvider,
    required this.reviewProvider,
    required this.messagesProvider,
  });

  @override
  _ProfileArtistScreenState createState() => _ProfileArtistScreenState();
}

// Estado de la pantalla de perfil del artista
class _ProfileArtistScreenState extends State<ProfileArtistScreen> {
  // Controladores de estado para la interfaz
  final selectedButtonIndex = ValueNotifier<int>(-1); // Índice del botón seleccionado
  final showImageDetail = ValueNotifier<ImageData?>(null); // Detalle de imagen a mostrar
  File? _selectedProfileImage; // Archivo de imagen de perfil seleccionado
  bool _isUploadingProfileImage = false; // Estado de carga de imagen

  // Método para seleccionar imagen de perfil desde la galería
  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      _cropImage(imageFile); // Procesar la imagen seleccionada
    }
  }

  // Método para recortar la imagen seleccionada
  Future<void> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Relación 1:1
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: AppStrings.cropImageTitle,
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true, // Bloquea relación de aspecto
        ),
        IOSUiSettings(
          title: AppStrings.cropImageTitle,
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _selectedProfileImage = File(croppedFile.path);
        _isUploadingProfileImage = true;
      });
      await _uploadProfileImage(_selectedProfileImage!); // Subir imagen recortada
      setState(() {
        _isUploadingProfileImage = false;
      });
    }
  }

  // Método para subir la imagen de perfil al servidor
  Future<void> _uploadProfileImage(File file) async {
    try {
      final currentUserId =  FirebaseAuth.instance.currentUser?.uid;
      await widget.uploadProfileImagesToServer.uploadProfileImage(
        currentUserId!,
        file,
      );
      widget.userProvider.loadUserData(currentUserId!); // Actualizar datos de usuario
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.uploadProfileImageError}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método build principal que construye la interfaz
  @override
  Widget build(BuildContext context) {
    // Obtener providers y datos necesarios
    final messagesProvieder = widget.messagesProvider;
    final userProvider = context.watch<UserProvider>();
    final isArtist = userProvider.userType == AppStrings.artist;
    final currentUserId =  FirebaseAuth.instance.currentUser?.uid;
    final profileProvider = widget.profileProvider;
    final reviewProvider = widget.reviewProvider;
    final colorScheme = ColorPalette.getPalette(context); // Esquema de colores

    // Cargar datos del usuario
    if (currentUserId != null) {
      userProvider.loadUserData(currentUserId);
      userProvider.getUserData(currentUserId);
    }

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColorLight],
      // Barra de navegación inferior
      bottomNavigationBar: BottomNavigationBarWidget(
        isArtist: isArtist,
        goRouter: widget.goRouter,
      ),
      // Cuerpo principal con CustomScrollView para efectos de scroll personalizados
      body: CustomScrollView(
        slivers: [
          // SliverAppBar: Cabecera expandible con imagen de perfil
          SliverAppBar(
            expandedHeight: 220.0, // Altura cuando está expandido
            pinned: true, // Permanece visible al hacer scroll
            backgroundColor: colorScheme[AppStrings.primaryColorLight],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                // SafeArea solo aplicado al header para evitar notches
                return SafeArea(
                  bottom: false, // Solo protege la parte superior
                  child: FlexibleSpaceBar(
                    background: ProfileHeader(
                      profileImageUrl: userProvider.profileImageUrl,
                      userName: userProvider.userName,
                      nickname: userProvider.nickname,
                      isUploading: _isUploadingProfileImage,
                      currentUserId: currentUserId ?? '',
                      goRouter: widget.goRouter,
                    ),
                  ),
                );
              },
            ),
          ),
          // Fila de botones de navegación
          SliverToBoxAdapter(
            child: ButtonRow(
              selectedButtonIndex: selectedButtonIndex,
              onButtonSelect: (int index) {
                selectedButtonIndex.value = index; // Actualizar selección
              },
            ),
          ),
          // Contenido dinámico según botón seleccionado
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                Widget content;
                switch (selectedButtonIndex.value) {
                  case 0:
                    content = WorksContent(); // Contenido de trabajos
                    break;
                  case 1:
                    content = AvailabilityContent(userId: currentUserId ?? ''); // Disponibilidad
                    break;
                  case 2:
                    content = currentUserId != null
                        ? DatesContent( // Fechas
                            profileProvider: profileProvider,
                            currentUserId: currentUserId,
                          )
                        : const SizedBox.shrink();
                    break;
                  case 3:
                    content = ReviewsContent( // Reseñas
                      messagesProvider: messagesProvieder,
                      userProvider: userProvider,
                      reviewProvider: reviewProvider,
                    );
                    break;
                  default:
                    content = WorksContent(); // Default: trabajos
                }
                return content;
              },
            ),
          ),
        ],
      ),
    );
  }

  // Método para seleccionar imagen de trabajo
  Future<void> _pickWorkImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserId =  FirebaseAuth.instance.currentUser?.uid;
      final imageFile = File(pickedFile.path);

      if (currentUserId != null) {
        await widget.uploadWorkImagesToServer.uploadWorkImage(
          currentUserId,
          imageFile,
        );
      } else {
        // Handle the null case if necessary, e.g., show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ID is null. Cannot upload work image.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
