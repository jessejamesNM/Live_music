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
  final GoRouter goRouter; // Navegación de la aplicación
  final UploadProfileImagesToServer
  uploadProfileImagesToServer; // Función para subir imágenes de perfil
  final UserProvider
  userProvider; // Proveedor de usuario para obtener el tipo de usuario

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
  bool _isUploadingProfileImage = false; // Indicador de carga de imagen
  String? _profileImageUrl; // URL de la imagen de perfil

  // Función para manejar el evento cuando se toca la imagen de perfil
  Future<void> _onProfileImageTapped() async {
    // Si ya se está subiendo una imagen, no hacer nada
    if (_isUploadingProfileImage) return;

    // Cambiar estado para indicar que se está subiendo una imagen
    setState(() => _isUploadingProfileImage = true);

    // Manejar la carga de la imagen de perfil
    await ProfileImageHandler.handle(
      context: context,
      imageType: AppStrings.profilePhoto, // Usando el tipo de imagen de perfil
      userProvider: widget.userProvider,
      onImageUploaded: (url) {
        setState(() {
          _profileImageUrl = url; // Actualizar la URL de la imagen
          _isUploadingProfileImage = false; // Cambiar el estado de carga
        });
      },
    );

    // Si el widget aún está montado, asegurar que el estado se actualice correctamente
    if (mounted) {
      setState(() => _isUploadingProfileImage = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Obtener el ID del usuario actual desde Firebase
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      FirebaseFirestore.instance.collection('users').doc(userId).get().then((
        doc,
      ) {
        if (doc.exists) {
          // Si la imagen de perfil está disponible en la base de datos, actualizarla
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
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtener esquema de colores
    final userType = widget.userProvider.userType; // Obtener tipo de usuario
    final isArtist =
        userType == AppStrings.artist; // Verificar si el usuario es artista

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColorLight],
      bottomNavigationBar: BottomNavigationBarWidget(
        isArtist:
            isArtist, // Pasar el estado de artista al widget de navegación
        goRouter: widget.goRouter, // Pasar el router para la navegación
      ),
      body: SafeArea(
        child: Container(
          color: Colors.black, // Fondo negro para la pantalla
          child: Column(
            children: [
              // Encabezado del perfil con la imagen de perfil
              Container(
                width: double.infinity,
                color: colorScheme[AppStrings.primaryColorLight],
                height: 180,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Gestor para tocar y cambiar la imagen de perfil
                    GestureDetector(
                      onTap: _onProfileImageTapped,
                      child: CircleAvatar(
                        radius: 52.5,
                        backgroundColor:
                            colorScheme[AppStrings.primaryColorLight],
                        child:
                            _isUploadingProfileImage
                                ? const CircularProgressIndicator() // Indicador de carga
                                : _profileImageUrl != null
                                ? ClipOval(
                                  child: Image.network(
                                    _profileImageUrl!, // Mostrar imagen de perfil
                                    width: 105,
                                    height: 105,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : SvgPicture.asset(
                                  'assets/svg/ic_user_default.svg', // Imagen por defecto si no hay imagen
                                  width: 105,
                                  height: 105,
                                  color:
                                      colorScheme[AppStrings
                                          .secondaryColorLittleDark],
                                ),
                      ),
                    ),
                    UserName(fontSize: 23.5), // Mostrar el nombre de usuario
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Título de configuración
                    Text(
                      AppStrings.settings,
                      style: TextStyle(
                        color: colorScheme[AppStrings.grayColor],
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 8),
                    // Componente de configuración que maneja la navegación a otras pantallas
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