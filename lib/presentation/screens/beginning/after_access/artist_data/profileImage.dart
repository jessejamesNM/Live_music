import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../data/provider_logics/beginning/beginning_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
class ProfileImageScreen extends StatefulWidget {
  final GoRouter goRouter;

  const ProfileImageScreen({required this.goRouter, Key? key}) : super(key: key);

  @override
  _ProfileImageScreenState createState() => _ProfileImageScreenState();
}

class _ProfileImageScreenState extends State<ProfileImageScreen> {
  File? _selectedImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  late String currentUserID;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserID = user.uid;
      _loadProfileImageUrl();
    } else {
      // Manejar el caso cuando no hay usuario autenticado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop(); // O cualquier otra acción apropiada
      });
    }
  }

  Future<void> _loadProfileImageUrl() async {
    String? url = await context.read<BeginningProvider>().loadProfileImageUrl(
      currentUserID,
    );
    if (mounted) {
      setState(() {
        _profileImageUrl = url;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isUploading = true;
      });
      await _uploadImage(_selectedImage!);
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadImage(File file) async {
    try {
      String? url = await context.read<BeginningProvider>().uploadProfileImage(
        context,
        file,
        currentUserID,
      );
      if (url != null) {
        await context.read<BeginningProvider>().saveProfileImageUrl(
          currentUserID,
          url,
        );
        if (mounted) {
          setState(() {
            _profileImageUrl = url;
          });
        }
      }
    } catch (e) {
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
    );

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      appBar: AppBar(
        title: Text(
          AppStrings.profilePhoto,
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
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
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
                  child: _isUploading
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
                                      value: loadingProgress.expectedTotalBytes !=
                                              null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
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
              if (_profileImageUrl != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.goRouter.go(
                        AppStrings.musicGenresScreenRoute,
                      );
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
                      AppStrings.myContinue,
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