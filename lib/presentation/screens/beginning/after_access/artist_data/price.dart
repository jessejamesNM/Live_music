/// -----------------------------------------------------------------------------
/// Fecha de creación: 2025-04-22
/// Autor: KingdomOfJames
///
/// Descripción:
/// Pantalla para ingresar la tarifa por hora del usuario (precio en dólares).
/// Permite al usuario introducir un valor numérico que representa su precio por hora.
/// Al confirmar, se guarda en la base de datos (Firestore) bajo el documento del usuario actual.
///
/// Recomendaciones:
/// - Mostrar retroalimentación visual inmediata cuando el valor ingresado es inválido.
/// - Agregar validación más robusta para evitar valores extremos o maliciosos.
/// - Considerar mover la lógica de validación y guardado al provider o un controlador externo.
///
/// Características:
/// - Entrada restringida a solo caracteres numéricos.
/// - Validación básica y conversión a entero del valor ingresado.
/// - Guarda la tarifa en Firestore bajo el campo `price`.
/// - Usa el esquema de colores definido en `ColorPalette`.
/// - Navega automáticamente a la siguiente pantalla si la tarifa se guarda correctamente.
/// - Muestra `SnackBar` con mensajes de error si algo falla.
/// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
import 'package:live_music/data/repositories/render_http_client/images/upload_service_services.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/resources/colors.dart';

class PriceScreen extends StatefulWidget {
  final GoRouter goRouter;
  final UserProvider userProvider;

  const PriceScreen({
    super.key,
    required this.goRouter,
    required this.userProvider,
  });

  @override
  State<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> {
  Map<String, dynamic>? servicio;
  bool _isLoading = true;
  bool _validPackages = false;
  late final Stream<QuerySnapshot<Map<String, dynamic>>>? _servicePackagesStream;
  String? _userName;
  String? _userProfileImageUrl;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _cargarServicioExistente();
    _initServicePackagesStream();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name'];
          _userProfileImageUrl = userDoc.data()?['profileImageUrl'];
          _userType = userDoc.data()?['userType'];
        });
      }
    }
  }

  String _getRecommendationMessage() {
    switch (_userType) {
      case 'artist':
        return 'Se recomienda colocar el nombre de su grupo';
      case 'bakery':
      case 'decoration':
        return 'Se recomienda colocar el nombre de su negocio';
      case 'place':
        return 'Se recomienda colocar el nombre de su local';
      default:
        return 'Se recomienda colocar un nombre descriptivo para su servicio';
    }
  }

  void _initServicePackagesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _servicePackagesStream =
          FirebaseFirestore.instance.collection('services').doc(user.uid).collection('service').snapshots();
    } else {
      _servicePackagesStream = null;
    }
  }

  Future<void> _refreshServiceData() async {
    setState(() => _isLoading = true);
    await _cargarServicioExistente();
  }

  Future<void> _cargarServicioExistente() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final docSnap = await FirebaseFirestore.instance.collection('services').doc(user.uid).get();

      if (docSnap.exists) {
        final data = docSnap.data();
        if (data != null && data.containsKey('service')) {
          final serviceData = data['service'] as Map<String, dynamic>;
          serviceData['imageUrls'] = [serviceData['imageUrl']];
          serviceData['serviceId'] = 'service';

          setState(() {
            servicio = serviceData;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar servicio: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar imagen',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Recortar imagen'),
      ],
    );
    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  Future<void> _eliminarServicio() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || servicio == null) return;

    try {
      await FirebaseFirestore.instance.collection('services').doc(user.uid).delete();

      final subcollections = await FirebaseFirestore.instance
          .collection('services')
          .doc(user.uid)
          .collection('service')
          .get();

      for (final doc in subcollections.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        setState(() {
          servicio = null;
          _validPackages = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar servicio: $e')),
        );
      }
    }
  }

  void _mostrarDialogoEliminar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar servicio'),
        content: const Text('¿Estás seguro de que quieres eliminar este servicio? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _eliminarServicio();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEditarServicio() {
    File? serviceImageFile;
    String nombreServicio = servicio?['name'] ?? '';
    String? currentImageUrl = servicio?['imageUrls']?[0];
    bool isUploading = false;
    final imagePicker = ImagePicker();
    final TextEditingController nombreServicioController = TextEditingController(text: nombreServicio);

    showDialog(
      context: context,
      barrierDismissible: !isUploading,
      builder: (BuildContext context) {
        final colorScheme = ColorPalette.getPalette(context);
        final screenWidth = MediaQuery.of(context).size.width;
        final baseFont = screenWidth / 25;
        final baseIcon = screenWidth / 12;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            nombreServicioController.value = nombreServicioController.value.copyWith(
              text: nombreServicio,
              selection: TextSelection.collapsed(offset: nombreServicio.length),
            );

            final bool hasChanges = serviceImageFile != null || (nombreServicio != servicio?['name'] && nombreServicio.length >= 8);

            Future<void> pickImage() async {
              final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
              if (pickedFile != null) {
                final croppedFile = await _cropImage(File(pickedFile.path));
                if (croppedFile != null) {
                  setDialogState(() => serviceImageFile = croppedFile);
                }
              }
            }

            Future<void> handleSave() async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              setDialogState(() => isUploading = true);

              String? imageUrl = currentImageUrl;
              if (serviceImageFile != null) {
                final uploadResponse = await RetrofitClientServices().apiServiceServices.uploadServiceImage(serviceImageFile!, user.uid);
                if (uploadResponse.url == null) {
                  final errorMessage = uploadResponse.error ?? "Error al subir la imagen.";
                  final errorDetails = uploadResponse.details != null ? '\n${uploadResponse.details}' : '';
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$errorMessage$errorDetails'), backgroundColor: Colors.red),
                    );
                  }
                  setDialogState(() => isUploading = false);
                  return;
                }
                imageUrl = uploadResponse.url!;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('services')
                    .doc(user.uid)
                    .update({'service': {'name': nombreServicio, 'imageUrl': imageUrl}});
                if (mounted) {
                  await _refreshServiceData();
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar servicio: $e')),
                  );
                }
              }

              if (mounted) setDialogState(() => isUploading = false);
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
              backgroundColor: colorScheme[AppStrings.primaryColorLight],
              child: SingleChildScrollView(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: isUploading ? null : pickImage,
                      child: Container(
                        width: double.infinity,
                        height: screenWidth * 0.38,
                        decoration: BoxDecoration(
                          color: colorScheme[AppStrings.primaryColorLight],
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          border: Border.all(color: colorScheme[AppStrings.secondaryColor]!.withOpacity(0.3)),
                        ),
                        child: serviceImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                child: Image.file(serviceImageFile!, fit: BoxFit.cover),
                              )
                            : currentImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                    child: Image.network(
                                      currentImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.broken_image_rounded,
                                        size: baseIcon,
                                        color: colorScheme[AppStrings.primaryColor],
                                      ),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        size: baseIcon,
                                        color: colorScheme[AppStrings.primaryColor],
                                      ),
                                      SizedBox(height: screenWidth * 0.02),
                                      Text(
                                        'Añadir imagen del servicio',
                                        style: TextStyle(
                                          color: colorScheme[AppStrings.primaryColor],
                                          fontSize: baseFont * 0.7,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.04),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Nombre del servicio',
                        style: TextStyle(
                          fontSize: baseFont * 1.2,
                          fontWeight: FontWeight.bold,
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    TextField(
                      controller: nombreServicioController,
                      onChanged: (value) => setDialogState(() => nombreServicio = value),
                      maxLength: 50,
                      decoration: InputDecoration(
                        hintText: 'Mínimo 8 caracteres',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(screenWidth * 0.02)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          borderSide: BorderSide(color: colorScheme[AppStrings.secondaryColor]!),
                        ),
                      ),
                      style: TextStyle(color: colorScheme[AppStrings.secondaryColor], fontSize: baseFont),
                    ),
                    SizedBox(height: screenWidth * 0.04),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: hasChanges && !isUploading ? handleSave : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme[AppStrings.essentialColor],
                          disabledBackgroundColor: colorScheme[AppStrings.essentialColor]?.withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.02)),
                          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
                        ),
                        child: isUploading
                            ? SizedBox(
                                height: baseFont * 0.8,
                                width: baseFont * 0.8,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Guardar cambios',
                                style: TextStyle(
                                  color: colorScheme[AppStrings.primaryColor],
                                  fontWeight: FontWeight.bold,
                                  fontSize: baseFont * 1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoCrearServicio() {
    File? serviceImageFile;
    String nombreServicio = _userName ?? '';
    bool isUploading = false;
    final imagePicker = ImagePicker();
    final TextEditingController nombreServicioController = TextEditingController(text: _userName);
    final screenWidth = MediaQuery.of(context).size.width;
    final baseFont = screenWidth / 25;
    final baseIcon = screenWidth / 12;

    showDialog(
      context: context,
      barrierDismissible: !isUploading,
      builder: (BuildContext context) {
        final colorScheme = ColorPalette.getPalette(context);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool canContinue = (serviceImageFile != null || _userProfileImageUrl != null) && nombreServicio.length >= 8;

            Future<void> pickImage() async {
              final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
              if (pickedFile != null) {
                final croppedFile = await _cropImage(File(pickedFile.path));
                if (croppedFile != null) {
                  setDialogState(() => serviceImageFile = croppedFile);
                }
              }
            }

            Future<void> handleContinue() async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null || !canContinue) return;

              setDialogState(() => isUploading = true);

              String? imageUrl;
              if (serviceImageFile == null && _userProfileImageUrl != null) {
                imageUrl = _userProfileImageUrl;
              } else if (serviceImageFile != null) {
                final uploadResponse = await RetrofitClientServices().apiServiceServices.uploadServiceImage(serviceImageFile!, user.uid);
                if (uploadResponse.url != null) {
                  imageUrl = uploadResponse.url!;
                } else {
                  final errorMessage = uploadResponse.error ?? "Error al subir la imagen.";
                  final errorDetails = uploadResponse.details != null ? '\n${uploadResponse.details}' : '';
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$errorMessage$errorDetails'), backgroundColor: Colors.red));
                  }
                  setDialogState(() => isUploading = false);
                  return;
                }
              }

              if (imageUrl == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes seleccionar una imagen para el servicio')));
                }
                setDialogState(() => isUploading = false);
                return;
              }

              final now = DateTime.now();
              final serviceMainData = {'name': nombreServicio, 'imageUrl': imageUrl};
              final serviceCollectionData = {
                'default': 'default',
                'imageList': [],
                'price': 0,
                'information': '',
                'createdAt': now.toIso8601String(),
              };

              try {
                await FirebaseFirestore.instance.collection('services').doc(user.uid).set({'service': serviceMainData}, SetOptions(merge: true));
                await FirebaseFirestore.instance.collection('services').doc(user.uid).collection('service').doc('service0').set(serviceCollectionData);

                if (mounted) {
                  await _refreshServiceData();
                  Navigator.of(context).pop();
                  widget.goRouter.push('/service_screen');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar servicio: $e')));
                }
              }

              if (mounted) setDialogState(() => isUploading = false);
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
              backgroundColor: colorScheme[AppStrings.primaryColorLight],
              child: SingleChildScrollView(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: isUploading ? null : pickImage,
                      child: Container(
                        width: double.infinity,
                        height: screenWidth * 0.38,
                        decoration: BoxDecoration(
                          color: colorScheme[AppStrings.primaryColorLight]?.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          border: Border.all(color: colorScheme[AppStrings.secondaryColor]!.withOpacity(0.3)),
                        ),
                        child: serviceImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                child: Image.file(serviceImageFile!, fit: BoxFit.cover),
                              )
                            : _userProfileImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                    child: Image.network(
                                      _userProfileImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.broken_image_rounded,
                                        size: baseIcon,
                                        color: colorScheme[AppStrings.primaryColor],
                                      ),
                                      loadingBuilder: (_, child, progress) => progress == null
                                          ? child
                                          : SizedBox(
                                              width: baseIcon,
                                              height: baseIcon,
                                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                            ),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        size: baseIcon,
                                        color: colorScheme[AppStrings.primaryColor],
                                      ),
                                      SizedBox(height: screenWidth * 0.02),
                                      Text(
                                        'Añadir imagen del servicio',
                                        style: TextStyle(
                                          color: colorScheme[AppStrings.primaryColor],
                                          fontSize: baseFont * 0.7,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.04),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Nombre del servicio',
                        style: TextStyle(
                          fontSize: baseFont * 1.2,
                          fontWeight: FontWeight.bold,
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    TextField(
                      controller: nombreServicioController,
                      onChanged: (value) => setDialogState(() => nombreServicio = value),
                      maxLength: 50,
                      decoration: InputDecoration(
                        hintText: 'Mínimo 8 caracteres',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(screenWidth * 0.02)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          borderSide: BorderSide(color: colorScheme[AppStrings.secondaryColor]!),
                        ),
                      ),
                      style: TextStyle(color: colorScheme[AppStrings.secondaryColor], fontSize: baseFont),
                    ),
                    if (_userName != null)
                      Padding(
                        padding: EdgeInsets.only(top: screenWidth * 0.015),
                        child: Text(
                          'Sugerencia: Usando tu nombre de perfil ($_userName)',
                          style: TextStyle(
                            color: colorScheme[AppStrings.secondaryColor]!.withOpacity(0.6),
                            fontSize: baseFont * 0.6,
                          ),
                        ),
                      ),
                    Text(
                      _getRecommendationMessage(),
                      style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor]!.withOpacity(0.6),
                        fontSize: baseFont * 0.6,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.04),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canContinue && !isUploading ? handleContinue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme[AppStrings.essentialColor],
                          disabledBackgroundColor: colorScheme[AppStrings.essentialColor]?.withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.02)),
                          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
                        ),
                        child: isUploading
                            ? SizedBox(
                                height: baseFont * 0.8,
                                width: baseFont * 0.8,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Continuar',
                                style: TextStyle(
                                  color: colorScheme[AppStrings.primaryColor],
                                  fontWeight: FontWeight.bold,
                                  fontSize: baseFont * 1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _checkValidPackages(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    bool allValid = true;
    for (final doc in docs) {
      final data = doc.data();
      if ((data['price'] ?? 0) <= 0 ||
          (data['imageList'] as List?)?.isEmpty != false ||
          (data['information'] as String?)?.isEmpty != false) {
        allValid = false;
        break;
      }
    }
    if (_validPackages != allValid) {
      setState(() {
        _validPackages = allValid;
      });
    }
  }

  Future<void> _createServiceRecord() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'createdService': FieldValue.serverTimestamp()});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear registro de servicio: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final baseFont = screenWidth / 25;
    final baseIcon = screenWidth / 12;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: Padding(
        padding: EdgeInsets.fromLTRB(screenWidth * 0.06, screenWidth * 0.15, screenWidth * 0.06, screenWidth * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              servicio == null ? 'Crea un nuevo servicio' : 'Servicios',
              style: TextStyle(
                fontSize: baseFont * 1.5,
                fontWeight: FontWeight.bold,
                color: colorScheme[AppStrings.secondaryColor],
              ),
            ),
            if (servicio == null) ...[
              SizedBox(height: screenWidth * 0.02),
              Text(
                _getRecommendationMessage(),
                style: TextStyle(
                  color: colorScheme[AppStrings.secondaryColor]!.withOpacity(0.7),
                  fontSize: baseFont * 0.8,
                ),
              ),
            ],
            SizedBox(height: screenWidth * 0.06),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : servicio == null
                      ? Center(
                          child: GestureDetector(
                            onTap: _mostrarDialogoCrearServicio,
                            child: Container(
                              width: double.infinity,
                              constraints: BoxConstraints(maxWidth: screenWidth * 0.9),
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              decoration: BoxDecoration(
                                color: colorScheme[AppStrings.primaryColorLight]?.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                border: Border.all(color: colorScheme[AppStrings.secondaryColor]!.withOpacity(0.2)),
                              ),
                              height: screenWidth * 0.18,
                              child: Center(
                                child: Icon(
                                  Icons.add,
                                  color: colorScheme[AppStrings.secondaryColor],
                                  size: baseIcon * 1.2,
                                ),
                              ),
                            ),
                          ),
                        )
                      : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _servicePackagesStream,
                          builder: (context, snapshot) {
                            final docs = snapshot.data?.docs ?? [];
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _checkValidPackages(docs);
                            });
                            return ListView(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(bottom: screenWidth * 0.04),
                                  padding: EdgeInsets.all(screenWidth * 0.03),
                                  decoration: BoxDecoration(
                                    color: colorScheme[AppStrings.primaryColorLight]?.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                    border: Border.all(color: colorScheme[AppStrings.secondaryColor]!.withOpacity(0.2)),
                                  ),
                                  child: Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          final user = FirebaseAuth.instance.currentUser;
                                          if (user != null) {
                                            widget.userProvider.loadServiceData(user.uid, 'service');
                                            widget.goRouter.push('/service_screen');
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            if (servicio!['imageUrls'].isNotEmpty)
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                                child: Image.network(
                                                  servicio!['imageUrls'][0],
                                                  width: baseIcon * 1.1,
                                                  height: baseIcon * 1.1,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Icon(
                                                    Icons.broken_image_rounded,
                                                    size: baseIcon * 0.9,
                                                  ),
                                                  loadingBuilder: (_, child, progress) => progress == null
                                                      ? child
                                                      : SizedBox(
                                                          width: baseIcon * 1.1,
                                                          height: baseIcon * 1.1,
                                                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                        ),
                                                ),
                                              ),
                                            SizedBox(width: screenWidth * 0.03),
                                            Expanded(
                                              child: Text(
                                                servicio!['name'] ?? 'Servicio',
                                                style: TextStyle(
                                                  color: colorScheme[AppStrings.secondaryColor],
                                                  fontSize: baseFont * 1.1,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit, size: baseIcon * 0.6),
                                              onPressed: _mostrarDialogoEditarServicio,
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete, size: baseIcon * 0.6, color: Colors.red),
                                              onPressed: _mostrarDialogoEliminar,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
            ),
            SizedBox(height: screenWidth * 0.04),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (servicio != null && _validPackages)
                    ? () async {
                        await _createServiceRecord();
                        widget.goRouter.push(AppStrings.userCanWorkCountryStateScreenRoute);
                      }
                    : () {
                        if (servicio == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crea primero un servicio.')));
                        } else if (!_validPackages) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa todos los paquetes con precio, imagen e información.')));
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: (servicio != null && _validPackages)
                      ? colorScheme[AppStrings.essentialColor]
                      : Colors.grey,
                  foregroundColor: colorScheme[AppStrings.primaryColor],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
                  elevation: 4,
                ),
                child: Text(
                  'Continuar',
                  style: TextStyle(
                    fontSize: baseFont * 1.1,
                    fontWeight: FontWeight.bold,
                    color: colorScheme[AppStrings.primaryColor],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}