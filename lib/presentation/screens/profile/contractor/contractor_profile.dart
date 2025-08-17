// Fecha de creación: 26/04/2025
// Author: KingdomOfJames
//
// Descripción:
// Esta pantalla muestra las reseñas de un contratista en la aplicación. La interfaz
// permite al usuario ver información básica sobre el contratista, como su nombre y
// foto de perfil, además de listar las reseñas asociadas a su perfil.
// Se hace uso de un `ValueListenableBuilder` para gestionar el estado reactivo de
// la imagen del perfil, y se incorpora un `BottomNavigationBar` para la navegación
// entre pantallas.
//
// Recomendaciones:
// - Asegurarse de que el `userProvider`, `reviewProvider` y `messagesProvider`
//   se inyecten correctamente desde el árbol de widgets superiores.
// - Mantener el uso adecuado de `ValueListenableBuilder` para evitar la reconstrucción
//   innecesaria de toda la pantalla cuando solo cambia una parte del estado.
// - Utilizar iconos de tamaño adecuado para garantizar una experiencia de usuario
//   consistente y visualmente agradable.
//
// Características:
// - Visualización de las reseñas del contratista.
// - Foto de perfil con respaldo en caso de que no esté disponible.
// - Navegación mediante `BottomNavigationBar`.
// - Título de la pantalla "Reseñas" con icono de retroceso.
// - Manejo de estado reactivo con `ValueListenableBuilder`.

import 'package:flutter/material.dart';
import 'package:live_music/data/widgets/cut_and_upload_images.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/strings.dart';
import '../../../../data/provider_logics/user/user_provider.dart';
import '../../../../data/repositories/render_http_client/images/upload_profile_image.dart';
import '../../../widgets/profile/userName.dart';
import '../../buttom_navigation_bar.dart';
import '../settings/components/settings.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ContractorProfileScreen extends StatefulWidget {
  final GoRouter goRouter;
  final UploadProfileImagesToServer uploadProfileImagesToServer;
  final UserProvider userProvider;

  const ContractorProfileScreen({
    super.key,
    required this.goRouter,
    required this.uploadProfileImagesToServer,
    required this.userProvider,
  });

  @override
  State<ContractorProfileScreen> createState() =>
      _ContractorProfileScreenState();
}

class _ContractorProfileScreenState extends State<ContractorProfileScreen> {
  bool _isUploadingProfileImage = false;
  String? _profileImageUrl;

  Future<void> _onProfileImageTapped() async {
    if (_isUploadingProfileImage) return;
    setState(() => _isUploadingProfileImage = true);

    await ProfileImageHandler.handle(
      context: context,
      imageType: AppStrings.profilePhoto,
      userProvider: widget.userProvider,
      onImageUploaded: (url) {
        setState(() {
          _profileImageUrl = url;
          _isUploadingProfileImage = false;
        });
      },
    );

    if (mounted) {
      setState(() => _isUploadingProfileImage = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      FirebaseFirestore.instance.collection('users').doc(userId).get().then((
        doc,
      ) {
        if (doc.exists) {
          setState(() {
            _profileImageUrl =
                doc.data()?.containsKey('profileImageUrl') == true
                    ? doc.get('profileImageUrl')
                    : null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final userType = widget.userProvider.userType;
    final isArtist = userType == AppStrings.artist;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor], // ✅ actualizado
      bottomNavigationBar: BottomNavigationBarWidget(
        userType: userType,
        goRouter: widget.goRouter,
      ),
      body: SafeArea(
        child: Container(
          color:
              colorScheme[AppStrings
                  .primaryColor], // ✅ fondo oscuro en light theme
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: colorScheme[AppStrings.primaryColor], // ✅ también aquí
                height: 180,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _onProfileImageTapped,
                      child: CircleAvatar(
                        radius: 52.5,
                        backgroundColor: colorScheme[AppStrings.primaryColor],
                        child:
                            _isUploadingProfileImage
                                ? const CircularProgressIndicator()
                                : _profileImageUrl != null
                                ? ClipOval(
                                  child: Image.network(
                                    _profileImageUrl!,
                                    width: 105,
                                    height: 105,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : SvgPicture.asset(
                                  'assets/svg/ic_user_default.svg',
                                  width: 105,
                                  height: 105,
                                  color:
                                      colorScheme[AppStrings
                                          .secondaryColorLittleDark],
                                ),
                      ),
                    ),
                    UserName(fontSize: 23.5),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      AppStrings.settings,
                      style: TextStyle(
                        color: colorScheme[AppStrings.grayColor],
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 8),
                    SettingsComponent(router: widget.goRouter),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
