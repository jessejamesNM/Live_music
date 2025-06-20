/// -----------------------------------------------------------------------------
/// Fecha de creación: 2025-04-22
/// Autor: KingdomOfJames
///
/// Descripción:
/// Pantalla para que el usuario agregue o actualice su foto de perfil.
/// Permite seleccionar una imagen desde la galería, subirla a un servidor (usando
/// `BeginningProvider`) y guardarla asociada al ID del usuario. La imagen se muestra
/// en pantalla en forma circular, con opciones visuales para cargar y errores.
///
/// Recomendaciones:
/// - Mostrar feedback al usuario cuando el guardado se completa exitosamente.
/// - Agregar opción para eliminar o reemplazar la imagen actual.
/// - Desacoplar la lógica de carga y subida de imagen a un ViewModel o Provider dedicado.
///
/// Características:
/// - Usa `ImagePicker` para seleccionar imágenes desde la galería.
/// - Muestra un `CircularProgressIndicator` durante la subida.
/// - Utiliza `BeginningProvider` para subir y obtener la URL de la imagen.
/// - Muestra la imagen seleccionada o actual desde la red en un contenedor circular.
/// - Ofrece navegación al presionar "Continuar" si ya se subió una imagen.
/// - Integra feedback visual con `SnackBar` en caso de errores.
/// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../data/provider_logics/beginning/beginning_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

// Pantalla para que el usuario suba o cambie su foto de perfil
class ProfileImageScreen extends StatefulWidget {
  final String
  userId; // ID del usuario para obtener/guardar su imagen de perfil
  final GoRouter goRouter; // Router para navegar a otras pantallas

  const ProfileImageScreen({required this.userId, required this.goRouter});

  @override
  _ProfileImageScreenState createState() => _ProfileImageScreenState();
}

class _ProfileImageScreenState extends State<ProfileImageScreen> {
  File? _selectedImage; // Imagen seleccionada desde galería
  String? _profileImageUrl; // URL de la imagen de perfil subida
  final ImagePicker _picker =
      ImagePicker(); // Utilidad para seleccionar imágenes
  bool _isUploading = false; // Indicador de carga durante el proceso de subida

  @override
  void initState() {
    super.initState();
    _loadProfileImageUrl(); // Carga inicial de la imagen de perfil (si existe)
  }

  // Carga la URL de la imagen de perfil desde Firebase usando el provider
  Future<void> _loadProfileImageUrl() async {
    String? url = await context.read<BeginningProvider>().loadProfileImageUrl(
      widget.userId,
    );
    if (mounted) {
      setState(() {
        _profileImageUrl = url;
      });
    }
  }

  // Abre la galería y permite al usuario seleccionar una imagen
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path); // Convierte a File para subir
        _isUploading = true;
      });
      await _uploadImage(_selectedImage!); // Sube la imagen al servidor
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Lógica de subida de imagen: se sube y luego se guarda la URL
  Future<void> _uploadImage(File file) async {
    try {
      String? url = await context.read<BeginningProvider>().uploadProfileImage(
        context,
        file,
        widget.userId,
      );
      if (url != null) {
        await context.read<BeginningProvider>().saveProfileImageUrl(
          widget.userId,
          url,
        );
        if (mounted) {
          setState(() {
            _profileImageUrl = url; // Actualiza la UI con la nueva imagen
          });
        }
      }
    } catch (e) {
      // Si ocurre un error al subir, se muestra un SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.errorUploadingImage}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Tema de colores de la app

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      appBar: AppBar(
        title: Text(
          AppStrings.profilePhoto, // "Foto de perfil"
          style: TextStyle(
            color: colorScheme[AppStrings.secondaryColor],
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme[AppStrings.primaryColor],
        iconTheme: IconThemeData(color: colorScheme[AppStrings.secondaryColor]),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Título de la pantalla
              Text(
                AppStrings.addProfilePhoto,
                style: TextStyle(
                  color: colorScheme[AppStrings.secondaryColor],
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Contenedor para mostrar o seleccionar imagen
              GestureDetector(
                onTap:
                    _isUploading
                        ? null
                        : _pickImage, // Desactiva si está subiendo
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: colorScheme[AppStrings.primaryColor],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme[AppStrings.secondaryColor]!,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  // Diferentes estados visuales: cargando, imagen cargada o ícono por defecto
                  child:
                      _isUploading
                          ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme[AppStrings.secondaryColor]!,
                              ),
                            ),
                          )
                          : _profileImageUrl != null
                          ? ClipOval(
                            child: Image.network(
                              _profileImageUrl!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                BuildContext context,
                                Widget child,
                                ImageChunkEvent? loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme[AppStrings.secondaryColor]!,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 80,
                                  color: colorScheme[AppStrings.secondaryColor],
                                );
                              },
                            ),
                          )
                          : Icon(
                            Icons.add_a_photo,
                            size: 50,
                            color: colorScheme[AppStrings.secondaryColor],
                          ),
                ),
              ),
              const SizedBox(height: 32),
              // Botón de continuar, solo visible si hay una imagen cargada
              if (_profileImageUrl != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.goRouter.go(
                        AppStrings.musicGenresScreenRoute,
                      ); // Siguiente pantalla
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme[AppStrings.essentialColor],
                      foregroundColor: colorScheme[AppStrings.primaryColor],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                    ),
                    child: Text(
                      AppStrings.myContinue, // "Continuar"
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme[AppStrings.primaryColor],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}