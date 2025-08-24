import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
import 'package:live_music/data/repositories/render_http_client/images/upload_service_services.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'package:image_cropper/image_cropper.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  late List<String> _localImageUrls;
  late PageController _pageController;
  int _currentPageIndex = 0;
  bool _isSaving = false;
  final ImagePicker _imagePicker = ImagePicker();
  late UserProvider _userProvider;
  bool _isGalleryExpanded = true;
  bool _isPackagesExpanded = true;
  bool _isPriceExpanded = true;
  bool _isInformationExpanded = true;
  List<Map<String, dynamic>> _packages = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _priceController;
  late TextEditingController _informationController;
  bool _pendingPackageChanges = false;
  bool _pendingInformationChanges = false;
  int _selectedPackageIndex = 0;
  bool _isLoadingImages = false;

  // For drag & drop autoscroll
  final ScrollController _galleryScrollController = ScrollController();
  bool _isDragging = false;

  // New: editing mode
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _localImageUrls = [];
    _priceController = TextEditingController();
    _informationController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _userProvider = Provider.of<UserProvider>(context, listen: false);
      await _loadServiceData();
      setState(() {});
    });

    _pageController.addListener(() {
      if (_pageController.page != null &&
          _pageController.page!.round() != _currentPageIndex) {
        setState(() {
          _currentPageIndex = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _priceController.dispose();
    _informationController.dispose();
    _galleryScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceData() async {
    await _loadPackages();
    if (_packages.isNotEmpty) {
      _selectedPackageIndex = _packages.first['index'];
      _priceController.text = _packages.first['price']?.toString() ?? '0';
      _informationController.text = _packages.first['information'] ?? '';
      await _loadImagesForSelectedPackage();
    } else {
      setState(() {
        _localImageUrls = [];
        _currentPageIndex = 0;
        _priceController.text = '0';
        _informationController.text = '';
      });
    }
  }

  Future<void> _loadPackages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final servicesRef = _firestore
        .collection('services')
        .doc(user.uid)
        .collection('service')
        .orderBy('index');

    final snapshot = await servicesRef.get();

    setState(() {
      _packages =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              ...data,
              'id': doc.id,
              'index':
                  data['index'] ?? int.parse(doc.id.replaceAll('service', '')),
            };
          }).toList();

      if (_packages.isNotEmpty) {
        final currentSelectedPackage = _packages.firstWhere(
          (pkg) => pkg['index'] == _selectedPackageIndex,
          orElse: () => _packages.first,
        );
        _priceController.text =
            currentSelectedPackage['price']?.toString() ?? '0';
        _informationController.text =
            currentSelectedPackage['information'] ?? '';
      } else {
        _selectedPackageIndex = 0;
        _priceController.text = '0';
        _informationController.text = '';
      }
    });
  }

  Future<void> _loadImagesForSelectedPackage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingImages = true;
      _localImageUrls = [];
      _currentPageIndex = 0;
    });

    final docRef = _firestore
        .collection('services')
        .doc(user.uid)
        .collection('service')
        .doc('service$_selectedPackageIndex');

    final snapshot = await docRef.get();

    setState(() {
      if (snapshot.exists) {
        _localImageUrls = List.from(snapshot.data()?['imageList'] ?? []);
        if (_localImageUrls.isNotEmpty) {
          if (_currentPageIndex >= _localImageUrls.length) {
            _currentPageIndex = 0;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(_currentPageIndex);
            }
          });
        } else {
          _currentPageIndex = 0;
        }
      } else {
        _localImageUrls = [];
        _currentPageIndex = 0;
      }
      _isLoadingImages = false;
    });
  }

  Future<void> _saveAllPackages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final servicesRef = _firestore
          .collection('services')
          .doc(user.uid)
          .collection('service');

      final int priceValue = int.tryParse(_priceController.text) ?? 0;
      final String informationValue = _informationController.text.trim();

      final int packageToUpdateIndex = _packages.indexWhere(
        (pkg) => pkg['index'] == _selectedPackageIndex,
      );
      if (packageToUpdateIndex != -1) {
        _packages[packageToUpdateIndex]['price'] = priceValue;
        _packages[packageToUpdateIndex]['information'] = informationValue;
      }

      final packageData = {
        'price': priceValue,
        'information': informationValue,
        'index': _selectedPackageIndex,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await servicesRef
          .doc('service$_selectedPackageIndex')
          .set(packageData, SetOptions(merge: true));

      await _loadPackages();

      setState(() {
        _pendingPackageChanges = false;
        _pendingInformationChanges = false;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paquete guardado exitosamente!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar paquete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showSaveDialog() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Guardar cambios'),
                content: const Text(
                  '¿Quiere guardar los cambios anteriores del paquete?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      'No',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      'Sí',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _selectPackage(int index) async {
    if (_pendingPackageChanges || _pendingInformationChanges) {
      final shouldSave = await _showSaveDialog();
      if (shouldSave) {
        await _saveAllPackages();
      }
    }

    setState(() {
      _selectedPackageIndex = index;
      _pendingPackageChanges = false;
      _pendingInformationChanges = false;
      final selectedPkg = _packages.firstWhere(
        (pkg) => pkg['index'] == index,
        orElse: () => {'price': 0, 'information': ''},
      );
      _priceController.text = selectedPkg['price']?.toString() ?? '0';
      _informationController.text = selectedPkg['information'] ?? '';
    });

    await _loadImagesForSelectedPackage();
  }

  Future<void> _addNewPackage() async {
    if (_pendingPackageChanges || _pendingInformationChanges) {
      final shouldSave = await _showSaveDialog();
      if (shouldSave) {
        await _saveAllPackages();
      }
    }
    if (_packages.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya has alcanzado el máximo de 8 paquetes.'),
        ),
      );
      return;
    }

    int maxIndex = -1;
    if (_packages.isNotEmpty) {
      for (var pkg in _packages) {
        if (pkg['index'] is int && pkg['index'] > maxIndex) {
          maxIndex = pkg['index'];
        }
      }
    }
    final newIndex = maxIndex + 1;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = _firestore
          .collection('services')
          .doc(user.uid)
          .collection('service')
          .doc('service$newIndex');

      await docRef.set({
        'index': newIndex,
        'price': 0,
        'information': '',
        'imageList': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _loadPackages();
      await _selectPackage(newIndex);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paquete ${newIndex + 1} creado exitosamente!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear nuevo paquete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePackage(int index) async {
    final bool confirmDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Confirmar eliminación'),
                content: Text(
                  '¿Estás seguro de que quieres eliminar el Paquete ${index + 1}?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      'No',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      'Sí',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmDelete) return;

    if (_pendingPackageChanges || _pendingInformationChanges) {
      final shouldSave = await _showSaveDialog();
      if (shouldSave) {
        await _saveAllPackages();
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('services')
          .doc(user.uid)
          .collection('service')
          .doc('service$index')
          .delete();

      setState(() {
        _packages.removeWhere((pkg) => pkg['index'] == index);
        _pendingPackageChanges = false;
        _pendingInformationChanges = false;

        if (_selectedPackageIndex == index) {
          _selectedPackageIndex =
              _packages.isNotEmpty ? _packages.first['index'] : 0;
          _priceController.text =
              _packages.isNotEmpty
                  ? _packages.first['price']?.toString() ?? '0'
                  : '0';
          _informationController.text =
              _packages.isNotEmpty ? _packages.first['information'] ?? '' : '';
          _loadImagesForSelectedPackage();
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paquete eliminado exitosamente!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar paquete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar imagen',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          showCropGrid: true,
          cropFrameStrokeWidth: 2,
          cropGridStrokeWidth: 1,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(title: 'Recortar imagen', aspectRatioLockEnabled: false),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  Future<void> _pickAndUploadImage({int? indexToReplace}) async {
    if (!_isEditing) return;

    if (_localImageUrls.length >= 5 && indexToReplace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya has subido el máximo de 5 imágenes.')),
      );
      return;
    }

    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    setState(() => _isSaving = true);
    File imageFile = File(pickedFile.path);

    // Mostrar opción de recorte
    final croppedFile = await _cropImage(imageFile);
    if (croppedFile == null) {
      setState(() => _isSaving = false);
      return;
    }

    imageFile = croppedFile;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      final uploadResponse = await RetrofitClientServices().apiServiceServices
          .uploadServiceImage(imageFile, user.uid);
      if (uploadResponse.url != null) {
        setState(() {
          if (indexToReplace != null &&
              indexToReplace < _localImageUrls.length) {
            _localImageUrls[indexToReplace] = uploadResponse.url!;
          } else {
            _localImageUrls.add(uploadResponse.url!);
          }
        });
        await _saveImagesToPackage();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al subir imagen: ${uploadResponse.error ?? "Desconocido"}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado al subir imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveImagesToPackage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('services')
          .doc(user.uid)
          .collection('service')
          .doc('service$_selectedPackageIndex')
          .update({
            'imageList': _localImageUrls,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imágenes guardadas exitosamente!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar imágenes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (!_isEditing) return;
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String item = _localImageUrls.removeAt(oldIndex);
      _localImageUrls.insert(newIndex, item);

      if (_currentPageIndex == oldIndex) {
        _currentPageIndex = newIndex;
      } else if (_currentPageIndex > oldIndex &&
          _currentPageIndex <= newIndex) {
        _currentPageIndex--;
      } else if (_currentPageIndex < oldIndex &&
          _currentPageIndex >= newIndex) {
        _currentPageIndex++;
      }

      _pageController.jumpToPage(_currentPageIndex);
    });
    _saveImagesToPackage();
  }

  void _toggleGalleryVisibility() {
    setState(() {
      _isGalleryExpanded = !_isGalleryExpanded;
    });
  }

  void _togglePackagesVisibility() {
    setState(() {
      _isPackagesExpanded = !_isPackagesExpanded;
    });
  }

  void _togglePriceVisibility() {
    setState(() {
      _isPriceExpanded = !_isPriceExpanded;
    });
  }

  void _toggleInformationVisibility() {
    setState(() {
      _isInformationExpanded = !_isInformationExpanded;
    });
  }

  void _onPriceChanged(String value) {
    if (!_isEditing) return;
    setState(() {
      _pendingPackageChanges = true;
    });
  }

  void _onInformationChanged(String value) {
    if (!_isEditing) return;
    setState(() {
      _pendingInformationChanges = true;
    });
  }

  void _maybeAutoScroll(Offset pointer, double listWidth) {
    if (!_isDragging) return;
    const edgeMargin = 40.0;
    const scrollSpeed = 15.0;

    final dx = pointer.dx;
    if (dx < edgeMargin) {
      _galleryScrollController.animateTo(
        (_galleryScrollController.offset - scrollSpeed).clamp(
          0.0,
          _galleryScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 50),
        curve: Curves.linear,
      );
    } else if (dx > listWidth - edgeMargin) {
      _galleryScrollController.animateTo(
        (_galleryScrollController.offset + scrollSpeed).clamp(
          0.0,
          _galleryScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 50),
        curve: Curves.linear,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          backgroundColor: colorScheme[AppStrings.primaryColor],
          body: SafeArea(
            top: true,
            child: Stack(
              children: [
                Column(
                  children: [
                    _ServiceTopBarEditSave(
                      serviceName:
                          userProvider.currentServiceName ?? 'Servicio',
                      onBackPressed: () => context.pop(),
                      isSaving: _isSaving,
                      isEditing: _isEditing,
                      colorScheme: colorScheme,
                      onEditPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      onSavePressed:
                          _isSaving
                              ? null
                              : () async {
                                await _saveAllPackages();
                              },
                    ),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: AspectRatio(
                              aspectRatio: 1 / 1,
                              child: Container(
                                width: double.infinity,
                                color: colorScheme[AppStrings.primaryColorLight]
                                    ?.withOpacity(0.1),
                                child: Stack(
                                  children: [
                                    if (_isLoadingImages)
                                      Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                colorScheme[AppStrings
                                                    .secondaryColor]!,
                                              ),
                                        ),
                                      )
                                    else if (_localImageUrls.isNotEmpty)
                                      PageView.builder(
                                        controller: _pageController,
                                        itemCount: _localImageUrls.length,
                                        itemBuilder: (context, index) {
                                          return Hero(
                                            tag:
                                                'serviceImage_${userProvider.currentServiceId}_${_selectedPackageIndex}_$index',
                                            child: Image.network(
                                              _localImageUrls[index],
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (_, __, ___) => Center(
                                                    child: Icon(
                                                      Icons
                                                          .broken_image_rounded,
                                                      size: 100,
                                                      color:
                                                          colorScheme[AppStrings
                                                              .secondaryColor],
                                                    ),
                                                  ),
                                              loadingBuilder:
                                                  (_, child, progress) =>
                                                      progress == null
                                                          ? child
                                                          : Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          ),
                                            ),
                                          );
                                        },
                                      )
                                    else
                                      GestureDetector(
                                        onTap:
                                            _isEditing
                                                ? () => _pickAndUploadImage()
                                                : null,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.image_not_supported,
                                                size: 80,
                                                color: colorScheme[AppStrings
                                                        .secondaryColor]
                                                    ?.withOpacity(0.5),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'No hay imágenes para este paquete. Toca para subir una.',
                                                style: TextStyle(
                                                  color: colorScheme[AppStrings
                                                          .secondaryColor]
                                                      ?.withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (_localImageUrls.isNotEmpty &&
                                        !_isLoadingImages)
                                      Positioned(
                                        bottom: 16,
                                        right: 16,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            '${_currentPageIndex + 1}/${_localImageUrls.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PackagesLazyRowSection(
                                  packages: _packages,
                                  selectedPackageIndex: _selectedPackageIndex,
                                  onSelectPackage:
                                      _isEditing ? _selectPackage : (_) {},
                                  onAddNewPackage:
                                      _isEditing ? _addNewPackage : () {},
                                  onDeletePackage:
                                      _isEditing ? _deletePackage : (_) {},
                                  packageCount: _packages.length,
                                  colorScheme: colorScheme,
                                  isExpanded: _isPackagesExpanded,
                                  onToggle: _togglePackagesVisibility,
                                  onSaveAll:
                                      _isEditing ? _saveAllPackages : () {},
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Precio',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  colorScheme[AppStrings
                                                      .secondaryColor],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              _isPriceExpanded
                                                  ? Icons.expand_less
                                                  : Icons.expand_more,
                                              color:
                                                  colorScheme[AppStrings
                                                      .secondaryColor],
                                            ),
                                            onPressed: _togglePriceVisibility,
                                          ),
                                        ],
                                      ),
                                      if (_isPriceExpanded)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: TextField(
                                            controller: _priceController,
                                            enabled: _isEditing,
                                            keyboardType: TextInputType.number,
                                            style: TextStyle(
                                              color:
                                                  colorScheme[AppStrings
                                                      .secondaryColor],
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'Precio del Paquete',
                                              hintText: 'Ingrese el precio',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              prefixIcon: Icon(
                                                Icons.attach_money,
                                                color:
                                                    colorScheme[AppStrings
                                                        .secondaryColor],
                                              ),
                                              floatingLabelStyle: TextStyle(
                                                color:
                                                    colorScheme[AppStrings
                                                        .secondaryColor],
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color:
                                                      colorScheme[AppStrings
                                                          .secondaryColor]!,
                                                  width: 2.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: colorScheme[AppStrings
                                                          .secondaryColor]!
                                                      .withOpacity(0.5),
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                            ),
                                            onChanged: _onPriceChanged,
                                          ),
                                        ),
                                      if (_pendingPackageChanges &&
                                          _isPriceExpanded)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: Text(
                                            'Cambios pendientes en el precio. Pulsa Guardar para aplicar.',
                                            style: TextStyle(
                                              color:
                                                  colorScheme[AppStrings
                                                      .essentialColor],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Información',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  colorScheme[AppStrings
                                                      .secondaryColor],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              _isInformationExpanded
                                                  ? Icons.expand_less
                                                  : Icons.expand_more,
                                              color:
                                                  colorScheme[AppStrings
                                                      .secondaryColor],
                                            ),
                                            onPressed:
                                                _toggleInformationVisibility,
                                          ),
                                        ],
                                      ),
                                      if (_isInformationExpanded)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              TextSelectionTheme(
                                                data: TextSelectionThemeData(
                                                  selectionColor:
                                                      colorScheme[AppStrings
                                                              .secondaryColor]!
                                                          .withOpacity(
                                                            0.3,
                                                          ), // Color de fondo al seleccionar texto
                                                  cursorColor:
                                                      colorScheme[AppStrings
                                                          .secondaryColor], // Color del cursor
                                                  selectionHandleColor:
                                                      colorScheme[AppStrings
                                                          .secondaryColor], // Color de los controles de selección (iOS/Android)
                                                ),
                                                child: TextField(
                                                  controller:
                                                      _informationController,
                                                  enabled: _isEditing,
                                                  maxLines: 5,
                                                  minLines: 3,
                                                  maxLength: 800,
                                                  maxLengthEnforcement:
                                                      MaxLengthEnforcement
                                                          .enforced,
                                                  keyboardType:
                                                      TextInputType.multiline,
                                                  style: TextStyle(
                                                    color:
                                                        colorScheme[AppStrings
                                                            .secondaryColor],
                                                  ),
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        '¿Qué incluye tu Paquete?',
                                                    hintText:
                                                        'Cuenta de que es tu paquete y que incluye',
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.0,
                                                          ),
                                                    ),
                                                    floatingLabelStyle: TextStyle(
                                                      color:
                                                          colorScheme[AppStrings
                                                              .secondaryColor],
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            colorScheme[AppStrings
                                                                .secondaryColor]!,
                                                        width: 2.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.0,
                                                          ),
                                                    ),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: colorScheme[AppStrings
                                                                .secondaryColor]!
                                                            .withOpacity(0.5),
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.0,
                                                          ),
                                                    ),
                                                  ),
                                                  onChanged:
                                                      _onInformationChanged,
                                                ),
                                              ),
                                              Text(
                                                '${_informationController.text.length}/800',
                                                style: TextStyle(
                                                  color: colorScheme[AppStrings
                                                          .secondaryColor]!
                                                      .withOpacity(0.6),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (_pendingInformationChanges &&
                                          _isInformationExpanded)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: Text(
                                            'Cambios pendientes en la información. Pulsa Guardar para aplicar.',
                                            style: TextStyle(
                                              color:
                                                  colorScheme[AppStrings
                                                      .essentialColor],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Galería de Imágenes',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  colorScheme[AppStrings
                                                      .secondaryColor],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              _isGalleryExpanded
                                                  ? Icons.expand_less
                                                  : Icons.expand_more,
                                              color:
                                                  colorScheme[AppStrings
                                                      .secondaryColor],
                                            ),
                                            onPressed: _toggleGalleryVisibility,
                                          ),
                                        ],
                                      ),
                                      if (_isGalleryExpanded)
                                        SizedBox(
                                          height: 100,
                                          child: Listener(
                                            onPointerMove: (event) {
                                              if (_isDragging) {
                                                final box =
                                                    context.findRenderObject()
                                                        as RenderBox?;
                                                if (box != null) {
                                                  final local = box
                                                      .globalToLocal(
                                                        event.position,
                                                      );
                                                  _maybeAutoScroll(
                                                    local,
                                                    box.size.width,
                                                  );
                                                }
                                              }
                                            },
                                            child: ReorderableListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount:
                                                  _localImageUrls.length +
                                                  (_isEditing &&
                                                          _localImageUrls
                                                                  .length <
                                                              5
                                                      ? 1
                                                      : 0),
                                              onReorderStart: (_) {
                                                if (_isEditing) {
                                                  setState(() {
                                                    _isDragging = true;
                                                  });
                                                }
                                              },
                                              onReorderEnd: (_) {
                                                setState(() {
                                                  _isDragging = false;
                                                });
                                              },
                                              onReorder:
                                                  _isEditing
                                                      ? _handleReorder
                                                      : (a, b) {},
                                              itemBuilder: (context, index) {
                                                if (index ==
                                                        _localImageUrls
                                                            .length &&
                                                    _isEditing &&
                                                    _localImageUrls.length <
                                                        5) {
                                                  return _buildAddImageButton(
                                                    colorScheme,
                                                  );
                                                }
                                                return _buildImageThumbnail(
                                                  _localImageUrls[index],
                                                  index,
                                                  colorScheme,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
       
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageThumbnail(
    String imageUrl,
    int index,
    Map<String, Color> colorScheme,
  ) {
    return Padding(
      key: ValueKey(imageUrl),
      padding: const EdgeInsets.all(4.0),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              _pageController.jumpToPage(index);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                loadingBuilder:
                    (_, child, progress) =>
                        progress == null
                            ? child
                            : Center(child: CircularProgressIndicator()),
                errorBuilder:
                    (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image, color: Colors.red),
                    ),
              ),
            ),
          ),
          if (_isEditing)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () async {
                  final bool confirmDelete =
                      await showDialog<bool>(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: const Text('Eliminar imagen'),
                              content: const Text(
                                '¿Estás seguro de que quieres eliminar esta imagen?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Sí'),
                                ),
                              ],
                            ),
                      ) ??
                      false;

                  if (confirmDelete) {
                    setState(() {
                      _localImageUrls.removeAt(index);
                    });
                    await _saveImagesToPackage();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton(Map<String, Color> colorScheme) {
    return Padding(
      key: const ValueKey('add_image_button'),
      padding: const EdgeInsets.all(4.0),
      child: GestureDetector(
        onTap: _isEditing ? () => _pickAndUploadImage() : null,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme[AppStrings.primaryColorLight]?.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: colorScheme[AppStrings.secondaryColor]!.withOpacity(0.5),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo,
                color: colorScheme[AppStrings.secondaryColor],
                size: 30,
              ),
              Text(
                'Añadir',
                style: TextStyle(
                  color: colorScheme[AppStrings.secondaryColor],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTopBarEditSave extends StatelessWidget {
  final String serviceName;
  final VoidCallback onBackPressed;
  final VoidCallback? onSavePressed;
  final VoidCallback? onEditPressed;
  final bool isSaving;
  final bool isEditing;
  final Map<String, Color?> colorScheme;

  const _ServiceTopBarEditSave({
    required this.serviceName,
    required this.onBackPressed,
    required this.onSavePressed,
    required this.onEditPressed,
    required this.isSaving,
    required this.isEditing,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 60,
        color: colorScheme[AppStrings.primaryColor],
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                serviceName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme[AppStrings.secondaryColor],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Positioned(
              left: 16,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: colorScheme[AppStrings.secondaryColor],
                  size: 30,
                ),
                onPressed: onBackPressed,
              ),
            ),
            Positioned(
              right: 16,
              child: SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed:
                      isSaving
                          ? null
                          : (isEditing ? onSavePressed : onEditPressed),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme[AppStrings.essentialColor],
                    foregroundColor: colorScheme[AppStrings.primaryColor],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 0,
                    ),
                    elevation: 2,
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child:
                      isSaving
                          ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            isEditing ? 'Guardar' : 'Editar',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
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

class PackagesLazyRowSection extends StatelessWidget {
  final List<Map<String, dynamic>> packages;
  final int selectedPackageIndex;
  final Function(int) onSelectPackage;
  final VoidCallback onAddNewPackage;
  final Function(int) onDeletePackage;
  final int packageCount;
  final Map<String, Color> colorScheme;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onSaveAll;

  const PackagesLazyRowSection({
    super.key,
    required this.packages,
    required this.selectedPackageIndex,
    required this.onSelectPackage,
    required this.onAddNewPackage,
    required this.onDeletePackage,
    required this.packageCount,
    required this.colorScheme,
    required this.isExpanded,
    required this.onToggle,
    required this.onSaveAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paquetes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme[AppStrings.secondaryColor],
                ),
              ),
              IconButton(
                icon: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: colorScheme[AppStrings.secondaryColor],
                ),
                onPressed: onToggle,
              ),
            ],
          ),
        ),
        if (isExpanded)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: packages.length + 1,
              itemBuilder: (context, index) {
                if (index == packages.length) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: onAddNewPackage,
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: colorScheme[AppStrings.primaryColorLight],
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: colorScheme[AppStrings.secondaryColor]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: colorScheme[AppStrings.secondaryColor],
                              size: 30,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Añadir',
                              style: TextStyle(
                                color: colorScheme[AppStrings.secondaryColor],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final package = packages[index];
                final bool isSelected =
                    package['index'] == selectedPackageIndex;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => onSelectPackage(package['index']),
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? colorScheme[AppStrings.essentialColor]
                                : colorScheme[AppStrings.primaryColorLight],
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color:
                              isSelected
                                  ? colorScheme[AppStrings.secondaryColor]!
                                  : colorScheme[AppStrings.secondaryColor]!
                                      .withOpacity(0.5),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Paquete ${index + 1}', // ← aquí usamos el índice visible, no el interno
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : colorScheme[AppStrings
                                                .secondaryColor],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (packages.length > 1)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: Icon(
                                  Icons.cancel,
                                  color:
                                      isSelected
                                          ? Colors.white.withOpacity(0.8)
                                          : Colors.red.withOpacity(0.8),
                                  size: 20,
                                ),
                                onPressed:
                                    () => onDeletePackage(package['index']),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
