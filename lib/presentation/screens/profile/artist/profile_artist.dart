// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción: Pantalla para mostrar el perfil de un artista. Permite cargar y recortar imágenes de perfil y trabajo,
// además de mostrar información relevante como trabajos, disponibilidad, fechas y reseñas del artista.
// Recomendaciones: Verificar los permisos para acceder a la galería de imágenes en dispositivos Android/iOS.
// Características: Carga y visualización de imágenes de perfil y trabajos, interacción con los botones para cambiar el contenido,
// vista dinámica con un SliverAppBar que permite ver el encabezado del perfil al hacer scroll.

// Importaciones necesarias
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:live_music/data/provider_logics/nav_buttom_bar_components/messages/messages_provider.dart';
import 'package:live_music/data/provider_logics/nav_buttom_bar_components/profile/profile_provider.dart';
import 'package:live_music/data/provider_logics/user/review_provider.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/screens/profile/artist/artist_elements_bar/service.dart';
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

class ProfileArtistScreen extends StatefulWidget {
  final UploadProfileImagesToServer uploadProfileImagesToServer;
  final UploadWorkMediaToServer uploadWorkImagesToServer;
  final GoRouter goRouter;
  final ProfileProvider profileProvider;
  final UserProvider userProvider;
  final ReviewProvider reviewProvider;
  final MessagesProvider messagesProvider;

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

class _ProfileArtistScreenState extends State<ProfileArtistScreen> {
  final ValueNotifier<int> selectedButtonIndex = ValueNotifier<int>(0);
  final ValueNotifier<ImageData?> showImageDetail = ValueNotifier<ImageData?>(null);
  File? _selectedProfileImage;
  bool _isUploadingProfileImage = false;
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;
  bool _initialDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadInitialUserData();
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialUserData() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null && !_initialDataLoaded) {
      await widget.userProvider.getUserData(currentUserId);

      _userDataSubscription = FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserId)
          .snapshots()
          .listen((document) {
        if (document.exists) {
          widget.userProvider.updateUserDataFromDocument(document);
        }
      });

      _initialDataLoaded = true;
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      _cropImage(imageFile);
    }
  }

  Future<void> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: AppStrings.cropImageTitle,
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
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
      await _uploadProfileImage(_selectedProfileImage!);
      setState(() {
        _isUploadingProfileImage = false;
      });
    }
  }

  Future<void> _uploadProfileImage(File file) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        await widget.uploadProfileImagesToServer.uploadProfileImage(
          currentUserId,
          file,
        );
      }
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

  Widget _buildSelectedContent(String userId) {
    switch (selectedButtonIndex.value) {
      case 0:
        return ServicesProfileScreen(
          userId: userId,
          userProvider: widget.userProvider,
          goRouter: widget.goRouter,
        );
      case 1:
        return WorksContent();
      case 2:
        return AvailabilityContent(userId: userId);
      case 3:
        return DatesContent(profileProvider: widget.profileProvider, currentUserId: userId);
      case 4:
        return ReviewsContent(
          messagesProvider: widget.messagesProvider,
          userProvider: widget.userProvider,
          reviewProvider: widget.reviewProvider,
        );
      default:
        return WorksContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final userType = userProvider.userType;
    final isArtist = userProvider.userType == AppStrings.artist;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final colorScheme = ColorPalette.getPalette(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColorLight],
      bottomNavigationBar: BottomNavigationBarWidget(
        userType: userType,
        goRouter: widget.goRouter,
      ),
      body: currentUserId == null
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<int>(
              valueListenable: selectedButtonIndex,
              builder: (context, index, _) {
                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: screenHeight * 0.28,
                      pinned: true,
                      backgroundColor: colorScheme[AppStrings.primaryColorLight],
                      flexibleSpace: SafeArea(
                        bottom: false,
                        child: FlexibleSpaceBar(
                          background: ProfileHeader(
                            profileImageUrl: userProvider.profileImageUrl,
                            userName: userProvider.userName,
                            nickname: userProvider.nickname,
                            isUploading: _isUploadingProfileImage,
                            currentUserId: currentUserId,
                            goRouter: widget.goRouter,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ButtonRow(
                        selectedButtonIndex: selectedButtonIndex,
                        onButtonSelect: (int index) {
                          selectedButtonIndex.value = index;
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSelectedContent(currentUserId),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _pickWorkImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final imageFile = File(pickedFile.path);

      if (currentUserId != null) {
        await widget.uploadWorkImagesToServer.uploadWorkImage(
          currentUserId,
          imageFile,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User ID is null. Cannot upload work image.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
