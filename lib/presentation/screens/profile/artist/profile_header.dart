/// Fecha de creación: 26 de abril de 2025
/// Autor: KingdomOfJames
/// Descripción: Esta pantalla se encarga de mostrar el encabezado del perfil de un usuario, que incluye su imagen de perfil, nombre de usuario, nickname y botones para interactuar con su contenido. Además, permite subir imágenes relacionadas con el trabajo y acceder a la configuración.
/// Recomendaciones: Asegúrate de gestionar adecuadamente el estado de carga de imágenes y verificar que las rutas de navegación estén bien configuradas.
/// Características:
/// - Muestra la imagen de perfil del usuario.
/// - Permite cambiar la imagen de perfil y la imagen de trabajo.
/// - Muestra el nombre de usuario y el nickname.
/// - Muestra botones interactivos para navegar por las secciones de "trabajos", "disponibilidad", "fechas" y "reseñas".

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:live_music/data/provider_logics/beginning/beginning_provider.dart';
import 'package:live_music/data/repositories/render_http_client/images/upload_profile_image.dart';
import 'package:live_music/data/widgets/cut_and_upload_images.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/screens/search_fun/profile_artist_ws/menuComponents/work_content_ws.dart';
import '../../../../data/repositories/render_http_client/images/upload_work_image.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../../../../../data/provider_logics/user/user_provider.dart';
import 'package:dio/dio.dart';
class ProfileHeader extends StatefulWidget {
  final String? profileImageUrl;
  final String userName;
  final String nickname;
  final bool isUploading;
  final String currentUserId;
  final GoRouter goRouter;
  const ProfileHeader({
    Key? key,
    required this.profileImageUrl,
    required this.userName,
    required this.nickname,
    required this.isUploading,
    required this.currentUserId,
    required this.goRouter,
  }) : super(key: key);

  @override
  _ProfileHeaderState createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  late bool _isUploading;
  final ImagePicker _picker = ImagePicker();
  final ApiServiceForWorks _api = RetrofitInstanceForWorks().apiServiceForWorks;

  @override
  void initState() {
    super.initState();
    _isUploading = widget.isUploading;
  }

  Future<void> _handleProfileImageUpdate() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    _showSnackBar('Procesando imagen...');

    setState(() => _isUploading = true);

    try {
      final croppedFile = await _cropImage(File(pickedFile.path));
      if (croppedFile == null) {
        setState(() => _isUploading = false);
        return;
      }

      final url = await _uploadProfileImage(croppedFile);
      if (url != null) {
        await _saveProfileImageUrl(url);
        _showSnackBar('Imagen de perfil actualizada con éxito');
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('inapropiado') ||
          e.toString().toLowerCase().contains('pornográfico') ||
          e.toString().toLowerCase().contains('violento')) {
        _showErrorDialog(
          'Contenido inapropiado',
          'La imagen ha sido rechazada por nuestro sistema de moderación. Por favor, sube una imagen apropiada para tu perfil.',
        );
      } else {
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar imagen',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Recortar imagen',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );
    return croppedFile != null ? File(croppedFile.path) : null;
  }

  Future<String?> _uploadProfileImage(File imageFile) async {
    try {
      final response = await RetrofitClient().apiService.uploadProfileImage(
        imageFile,
        widget.currentUserId,
      );

      if (response.error != null) {
        if (response.error!.toLowerCase().contains('inapropiado') ||
            response.error!.toLowerCase().contains('pornográfico') ||
            response.error!.toLowerCase().contains('violento')) {
          throw Exception('Contenido inapropiado: ${response.error}');
        }
        throw Exception(response.error);
      }

      return response.url;
    } on DioError catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Contenido inapropiado: ${e.response?.data['error']}');
      }
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveProfileImageUrl(String url) async {
    await context.read<BeginningProvider>().saveProfileImageUrl(
      widget.currentUserId,
      url,
    );
  }

  Future<void> _pickImageForWorks() async {
    _showSnackBar('Procesando imagen...');

    setState(() => _isUploading = true);
    try {
      await ProfileImageHandler.handle(
        context: context,
        imageType: 'works',
        userProvider: Provider.of<UserProvider>(context, listen: false),
        onImageUploaded: (url) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MediaPreviewer(mediaUrls: [url], initialIndex: 0),
            ),
          );
          _showSnackBar('Imagen subida exitosamente');
        },
      ).catchError((error) {
        if (error.toString().toLowerCase().contains('inapropiado') ||
            error.toString().toLowerCase().contains('pornográfico') ||
            error.toString().toLowerCase().contains('violento')) {
          _showErrorDialog(
            'Contenido inapropiado',
            'La imagen ha sido rechazada por nuestro sistema de moderación. Por favor, sube una imagen apropiada.',
          );
        } else {
          _showSnackBar('Error: $error', isError: true);
        }
      });
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickVideo() async {
    _showSnackBar('Procesando video...');

    setState(() => _isUploading = true);
    try {
      final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final resp = await _api.uploadVideo(file, widget.currentUserId);

      if (resp.url != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => MediaPreviewer(mediaUrls: [resp.url!], initialIndex: 0),
          ),
        );
        _showSnackBar('Video subido exitosamente');
      } else if (resp.error != null) {
        if (resp.error!.toLowerCase().contains('inapropiado') ||
            resp.error!.toLowerCase().contains('pornográfico') ||
            resp.error!.toLowerCase().contains('violento')) {
          _showErrorDialog(
            'Contenido inapropiado',
            'El video ha sido rechazado por nuestro sistema de moderación. Por favor, sube un video apropiado.',
          );
        } else {
          _showSnackBar('Error: ${resp.error}', isError: true);
        }
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('inapropiado') ||
          e.toString().toLowerCase().contains('pornográfico') ||
          e.toString().toLowerCase().contains('violento')) {
        _showErrorDialog(
          'Contenido inapropiado',
          'El video ha sido rechazado por nuestro sistema de moderación. Por favor, sube un video apropiado.',
        );
      } else {
        _showSnackBar('Error al subir video: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _onAddPressed() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.image, size: MediaQuery.of(context).size.width * 0.06),
                  title: Text('Subir imagen', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageForWorks();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.videocam, size: MediaQuery.of(context).size.width * 0.06),
                  title: Text('Subir video', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideo();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title, style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.045)),
            content: Text(message, style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.038)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Entendido', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.038)),
              ),
            ],
          ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.06,
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03)),
        margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      color: colorScheme[AppStrings.primaryColorLight],
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.02),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _isUploading ? null : _handleProfileImageUpdate,
                  child: CircleAvatar(
                    radius: screenWidth * 0.15,
                    backgroundColor: colorScheme[AppStrings.primaryColorLight],
                    child:
                        _isUploading
                            ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme[AppStrings.secondaryColor]!,
                              ),
                            )
                            : widget.profileImageUrl != null
                            ? ClipOval(
                              child: Image.network(
                                widget.profileImageUrl!,
                                width: screenWidth * 0.28,
                                height: screenWidth * 0.28,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          progress.expectedTotalBytes != null
                                              ? progress.cumulativeBytesLoaded /
                                                  progress.expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: screenWidth * 0.15,
                                    color:
                                        colorScheme[AppStrings.secondaryColor],
                                  );
                                },
                              ),
                            )
                            : Icon(
                              Icons.person,
                              size: screenWidth * 0.15,
                              color: colorScheme[AppStrings.secondaryColor],
                            ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  widget.userName,
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  "@${widget.nickname}",
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: colorScheme[AppStrings.grayColor],
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
          Positioned(
            top: screenHeight * 0.02,
            right: screenWidth * 0.04,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _onAddPressed,
                  child: Card(
                    color: colorScheme[AppStrings.mainColorGray],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.015),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      child: Icon(
                        Icons.add,
                        color: colorScheme[AppStrings.secondaryColor],
                        size: screenWidth * 0.06,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                GestureDetector(
                  onTap:
                      () =>
                          widget.goRouter.push(AppStrings.settingsScreenRoute),
                  child: Icon(
                    Icons.settings,
                    size: screenWidth * 0.1,
                    color: colorScheme[AppStrings.grayColor],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ButtonRow extends StatelessWidget {
  final ValueNotifier<int> selectedButtonIndex;
  final Function(int) onButtonSelect;

  ButtonRow({
    required this.selectedButtonIndex,
    required this.onButtonSelect,
    Key? key,
  }) : super(key: key);

  final List<ButtonData> buttons = [
    ButtonData(
      text: 'Servicios',
      index: 0,
    ),
    ButtonData(
      text: AppStrings.works,
      index: 1,
    ),
    ButtonData(
      text: AppStrings.availability,
      index: 2,
    ),
    ButtonData(
      text: AppStrings.dates,
      index: 3,
    ),
    ButtonData(
      text: AppStrings.review,
      index: 4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Adaptativo: calcula tamaño de fuente y paddings
    double fontSize = screenWidth * 0.04;
    double horizontalPadding = screenWidth * 0.035;
    double verticalPadding = screenHeight * 0.012;
    double buttonSpacing = screenWidth * 0.01;
    double borderRadiusValue = screenWidth * 0.04;

    return ValueListenableBuilder<int>(
      valueListenable: selectedButtonIndex,
      builder: (context, value, child) {
        return Container(
          color: colorScheme[AppStrings.primaryColorLight],
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: buttons.map((button) {
                final isSelected = value == button.index;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: buttonSpacing),
                  child: Material(
                    borderRadius: BorderRadius.circular(borderRadiusValue),
                    color: colorScheme[AppStrings.primaryColorLight],
                    child: InkWell(
                      borderRadius: BorderRadius.circular(borderRadiusValue),
                      onTap: () => onButtonSelect(button.index),
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: screenWidth * 0.25,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(borderRadiusValue),
                          border: isSelected
                              ? Border.all(
                                  color: colorScheme[AppStrings.secondaryColor]!,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Text(
                          button.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                            color: colorScheme[AppStrings.secondaryColor],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class ButtonData {
  final String text;
  final int index;

  ButtonData({required this.text, required this.index});
}