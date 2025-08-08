/*
 * Fecha de creación: 2025-04-26
 * Autor: KingdomOfJames
 * Descripción:
 *  La pantalla `ImageDetailScreen` se encarga de mostrar una imagen de detalle en una interfaz de usuario. Esta pantalla se utiliza principalmente para ver imágenes de perfil o de trabajo en detalle.
 *  La pantalla recibe la información de la imagen (como la URI), un callback para navegar hacia atrás y las dependencias necesarias para cargar y subir las imágenes.
 *  La interfaz presenta un encabezado de perfil con información sobre el usuario y una vista de la imagen cargada.
 *  
 * Recomendaciones:
 *  - Verificar que las dependencias necesarias (como los proveedores) estén configuradas correctamente antes de utilizar esta pantalla.
 *  - Implementar un manejo adecuado de errores en el `FutureBuilder` en caso de que la carga de la imagen falle.
 *  - Personalizar la interacción con las imágenes, dependiendo de la lógica de negocio, como habilitar o deshabilitar la edición.
 * 
 * Características:
 *  - Visualización de una imagen (perfil o trabajo) de manera detallada.
 *  - Interactividad a través del tap en las imágenes de perfil o de trabajo (aunque en este caso se deja vacío).
 *  - Utiliza un `FutureBuilder` para cargar la imagen de manera asíncrona y mostrarla cuando esté lista.
 */

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../data/model/profile/image_data.dart';
import '../../../../data/provider_logics/nav_buttom_bar_components/profile/profile_provider.dart';
import '../../../../data/provider_logics/user/user_provider.dart';
import '../../../../data/repositories/render_http_client/images/upload_profile_image.dart';
import '../../../../data/repositories/render_http_client/images/upload_work_image.dart';
import '../../../screens/profile/artist/profile_header.dart';

class ImageDetailScreen extends StatelessWidget {
  final ImageData imageData; // Datos de la imagen a mostrar.
  final VoidCallback onBack; // Acción para regresar a la pantalla anterior.
  final BuildContext context; // El contexto de la aplicación.
  final UploadProfileImagesToServer
  uploadProfileImagesToServer; // Lógica para subir imágenes de perfil.
  final UploadWorkMediaToServer
  uploadWorkImagesToServer; // Lógica para subir imágenes de trabajo.
  final GoRouter goRouter;

  const ImageDetailScreen({
    required this.imageData,
    required this.onBack,
    required this.context,
    required this.uploadProfileImagesToServer,
    required this.uploadWorkImagesToServer,
    required this.goRouter,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Proveedores para obtener los datos del perfil y del usuario.
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor:
          Colors
              .black, // Color de fondo oscuro para mejorar la visibilidad de la imagen.
      body: GestureDetector(
        onTap:
            onBack, // Permite cerrar la pantalla tocando en cualquier parte de la pantalla.
        child: Container(
          padding: const EdgeInsets.all(
            16,
          ), // Agrega un margen alrededor del contenido.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado del perfil con los datos del usuario.
              ProfileHeader(
                profileImageUrl:
                    userProvider.profileImageUrl, // URL de la imagen de perfil.
                userName: userProvider.userName, // Nombre del usuario.
                nickname: userProvider.nickname, // Apodo del usuario.
                isUploading:
                    false, // No estamos subiendo imágenes, estamos solo en modo vista.
                currentUserId: currentUserId ?? '',
                goRouter: goRouter,
              ),
              const SizedBox(
                height: 20,
              ), // Espaciado entre el encabezado y la imagen.
              FutureBuilder<ImageProvider>(
                future: profileProvider.loadImageBitmapFromUri(
                  imageData.imageUri, // URI de la imagen a cargar.
                  context,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    // Si la imagen se ha cargado correctamente, la mostramos.
                    return Image(
                      image: snapshot.data!, // Imagen cargada.
                      width:
                          double
                              .infinity, // La imagen ocupará todo el ancho disponible.
                      fit:
                          BoxFit
                              .cover, // Asegura que la imagen cubra el espacio disponible sin distorsionarse.
                    );
                  } else {
                    // Mientras se carga la imagen, mostramos un indicador de carga.
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
