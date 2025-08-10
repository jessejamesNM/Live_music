import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
import 'package:live_music/data/repositories/render_http_client/images/upload_service_services.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:live_music/presentation/widgets/services/service_card.dart';

class ServicesProfileScreen extends StatefulWidget {
  final String userId;
  final UserProvider userProvider;
  final GoRouter goRouter;

  const ServicesProfileScreen({
    super.key,
    required this.userId,
    required this.userProvider,
    required this.goRouter,
  });

  @override
  State<ServicesProfileScreen> createState() => _ServicesProfileScreenState();
}

class _ServicesProfileScreenState extends State<ServicesProfileScreen> {
  Map<String, dynamic>? servicio;
  bool _isLoading = true;
  bool _validPackages = false;
  late final Stream<QuerySnapshot<Map<String, dynamic>>>?
  _servicePackagesStream;

  @override
  void initState() {
    super.initState();
    _cargarServicioExistente();
    _initServicePackagesStream();
  }

  void _initServicePackagesStream() {
    _servicePackagesStream =
        FirebaseFirestore.instance
            .collection('services')
            .doc(widget.userId)
            .collection('service')
            .snapshots();
  }

  Future<void> _refreshServiceData() async {
    setState(() => _isLoading = true);
    await _cargarServicioExistente();
  }

  Future<void> _cargarServicioExistente() async {
    try {
      final docSnap =
          await FirebaseFirestore.instance
              .collection('services')
              .doc(widget.userId)
              .get();

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar servicio: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      // Removed cropStyle parameter since it is not defined.
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
    if (servicio == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.userId)
          .delete();

      final subcollections =
          await FirebaseFirestore.instance
              .collection('services')
              .doc(widget.userId)
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
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar servicio'),
            content: const Text(
              '¿Estás seguro de que quieres eliminar este servicio? Esta acción no se puede deshacer.',
            ),
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
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
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
    final TextEditingController nombreServicioController =
        TextEditingController(text: nombreServicio);

    showDialog(
      context: context,
      barrierDismissible: !isUploading,
      builder: (BuildContext context) {
        final colorScheme = ColorPalette.getPalette(context);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            nombreServicioController
                .value = nombreServicioController.value.copyWith(
              text: nombreServicio,
              selection: TextSelection.collapsed(offset: nombreServicio.length),
            );

            final bool hasChanges =
                serviceImageFile != null ||
                (nombreServicio != servicio?['name'] &&
                    nombreServicio.length >= 8);

            Future<void> pickImage() async {
              final pickedFile = await imagePicker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 85,
              );
              if (pickedFile != null) {
                // Add dynamic cropping before setting the image file.
                final croppedFile = await _cropImage(File(pickedFile.path));
                if (croppedFile != null) {
                  setDialogState(() => serviceImageFile = croppedFile);
                }
              }
            }

            Future<void> handleSave() async {
              setDialogState(() => isUploading = true);

              String? imageUrl = currentImageUrl;
              if (serviceImageFile != null) {
                final uploadResponse = await RetrofitClientServices()
                    .apiServiceServices
                    .uploadServiceImage(serviceImageFile!, widget.userId);
                if (uploadResponse.url == null) {
                  final errorMessage =
                      uploadResponse.error ?? "Error al subir la imagen.";
                  final errorDetails =
                      uploadResponse.details != null
                          ? '\n${uploadResponse.details}'
                          : '';
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$errorMessage$errorDetails'),
                        backgroundColor: Colors.red,
                      ),
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
                    .doc(widget.userId)
                    .update({
                      'service': {'name': nombreServicio, 'imageUrl': imageUrl},
                    });

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: colorScheme[AppStrings.primaryColorLight],
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: isUploading ? null : pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: colorScheme[AppStrings.primaryColorLight],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme[AppStrings.secondaryColor]!
                                .withOpacity(0.3),
                          ),
                        ),
                        child:
                            serviceImageFile != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.file(
                                    serviceImageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : currentImageUrl != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.network(
                                    currentImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Icon(
                                          Icons.broken_image_rounded,
                                          size: 60,
                                          color:
                                              colorScheme[AppStrings
                                                  .primaryColor],
                                        ),
                                  ),
                                )
                                : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 60,
                                      color:
                                          colorScheme[AppStrings.primaryColor],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Añadir imagen del servicio',
                                      style: TextStyle(
                                        color:
                                            colorScheme[AppStrings
                                                .primaryColor],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Nombre del servicio',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nombreServicioController,
                      onChanged: (value) {
                        setDialogState(() {
                          nombreServicio = value;
                        });
                      },
                      maxLength: 50,
                      decoration: InputDecoration(
                        hintText: 'Mínimo 8 caracteres',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme[AppStrings.secondaryColor]!,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            hasChanges && !isUploading ? handleSave : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              colorScheme[AppStrings.essentialColor],
                          disabledBackgroundColor: colorScheme[AppStrings
                                  .essentialColor]
                              ?.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child:
                            isUploading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  'Guardar cambios',
                                  style: TextStyle(
                                    color: colorScheme[AppStrings.primaryColor],
                                    fontWeight: FontWeight.bold,
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
    String nombreServicio = '';
    bool isUploading = false;
    final imagePicker = ImagePicker();
    final TextEditingController nombreServicioController =
        TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !isUploading,
      builder: (BuildContext context) {
        final colorScheme = ColorPalette.getPalette(context);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool canContinue =
                serviceImageFile != null && nombreServicio.length >= 8;

            Future<void> pickImage() async {
              final pickedFile = await imagePicker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 85,
              );
              if (pickedFile != null) {
                // Perform cropping before setting file.
                final croppedFile = await _cropImage(File(pickedFile.path));
                if (croppedFile != null) {
                  setDialogState(() => serviceImageFile = croppedFile);
                }
              }
            }

            Future<void> handleContinue() async {
              if (!canContinue) return;

              setDialogState(() => isUploading = true);
              final uploadResponse = await RetrofitClientServices()
                  .apiServiceServices
                  .uploadServiceImage(serviceImageFile!, widget.userId);

              if (uploadResponse.url != null) {
                final now = DateTime.now();
                final serviceMainData = {
                  'name': nombreServicio,
                  'imageUrl': uploadResponse.url!,
                };

                final serviceCollectionData = {
                  'default': 'default',
                  'imageList': [],
                  'price': 0,
                  'information': '',
                  'createdAt': now.toIso8601String(),
                };

                try {
                  await FirebaseFirestore.instance
                      .collection('services')
                      .doc(widget.userId)
                      .set({
                        'service': serviceMainData,
                      }, SetOptions(merge: true));
                  await FirebaseFirestore.instance
                      .collection('services')
                      .doc(widget.userId)
                      .collection('service')
                      .doc('service0')
                      .set(serviceCollectionData);

                  if (mounted) {
                    await _refreshServiceData();
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al guardar servicio: $e')),
                    );
                  }
                }
              } else {
                final errorMessage =
                    uploadResponse.error ?? "Error al subir la imagen.";
                final errorDetails =
                    uploadResponse.details != null
                        ? '\n${uploadResponse.details}'
                        : '';
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$errorMessage$errorDetails'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }

              if (mounted) setDialogState(() => isUploading = false);
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: colorScheme[AppStrings.primaryColorLight],
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: isUploading ? null : pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: colorScheme[AppStrings.primaryColorLight],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme[AppStrings.secondaryColor]!
                                .withOpacity(0.3),
                          ),
                        ),
                        child:
                            serviceImageFile != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.file(
                                    serviceImageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 60,
                                      color:
                                          colorScheme[AppStrings.primaryColor],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Añadir imagen del servicio',
                                      style: TextStyle(
                                        color:
                                            colorScheme[AppStrings
                                                .primaryColor],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Nombre del servicio',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nombreServicioController,
                      onChanged: (value) {
                        setDialogState(() {
                          nombreServicio = value;
                        });
                      },
                      maxLength: 50,
                      decoration: InputDecoration(
                        hintText: 'Mínimo 8 caracteres',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme[AppStrings.secondaryColor]!,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            canContinue && !isUploading ? handleContinue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              colorScheme[AppStrings.essentialColor],
                          disabledBackgroundColor: colorScheme[AppStrings
                                  .essentialColor]
                              ?.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child:
                            isUploading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  'Continuar',
                                  style: TextStyle(
                                    color: colorScheme[AppStrings.primaryColor],
                                    fontWeight: FontWeight.bold,
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

  void _checkValidPackages(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return Container(
      color: colorScheme[AppStrings.primaryColor],
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  servicio == null ? 'Cree un nuevo servicio' : 'Servicios',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : servicio == null
                        ? Center(
                          child: GestureDetector(
                            onTap: _mostrarDialogoCrearServicio,
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 500),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme[AppStrings.primaryColorLight]
                                    ?.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme[AppStrings.secondaryColor]!
                                      .withOpacity(0.2),
                                ),
                              ),
                              height: 90,
                              child: Center(
                                child: Icon(
                                  Icons.add,
                                  color: colorScheme[AppStrings.secondaryColor],
                                  size: 40,
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
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme[AppStrings
                                            .primaryColorLight]
                                        ?.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme[AppStrings
                                              .secondaryColor]!
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          widget.userProvider.loadServiceData(
                                            widget.userId,
                                            'service',
                                          );
                                          widget.goRouter.push(
                                            '/service_screen',
                                          );
                                        },
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (servicio!['imageUrls']
                                                .isNotEmpty)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  right: 16,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    servicio!['imageUrls'][0],
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          _,
                                                          __,
                                                          ___,
                                                        ) => const Icon(
                                                          Icons
                                                              .broken_image_rounded,
                                                          size: 50,
                                                        ),
                                                    loadingBuilder:
                                                        (_, child, progress) =>
                                                            progress == null
                                                                ? child
                                                                : const SizedBox(
                                                                  width: 100,
                                                                  height: 100,
                                                                  child: Center(
                                                                    child: CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2,
                                                                    ),
                                                                  ),
                                                                ),
                                                  ),
                                                ),
                                              ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: Text(
                                                  servicio!['name'] ??
                                                      'Servicio',
                                                  style: TextStyle(
                                                    color:
                                                        colorScheme[AppStrings
                                                            .secondaryColor],
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                  ),
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
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 24,
                                              ),
                                              onPressed:
                                                  _mostrarDialogoEditarServicio,
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                size: 24,
                                                color: Colors.red,
                                              ),
                                              onPressed:
                                                  _mostrarDialogoEliminar,
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
            ],
          ),
        ),
      ),
    );
  }
}
