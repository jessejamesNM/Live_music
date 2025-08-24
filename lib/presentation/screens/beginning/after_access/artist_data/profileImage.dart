import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  const ProfileImageScreen({required this.goRouter, Key? key})
      : super(key: key);

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
    }
  }

  Future<void> _loadProfileImageUrl() async {
    String? url =
        await context.read<BeginningProvider>().loadProfileImageUrl(currentUserID);
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
      String? url =
          await context.read<BeginningProvider>().uploadProfileImage(context, file, currentUserID);
      if (url != null) {
        await context.read<BeginningProvider>().saveProfileImageUrl(currentUserID, url);
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

  Future<void> _onContinuePressed() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(currentUserID).get();
    final userType = doc.data()?['userType'];

    final isArtistType = [
      'artist',
      'bakery',
      'place',
      'decoration',
      'furniture',
      'entertainment',
    ].contains(userType);

    if (mounted) {
      if (isArtistType) {
        if (userType == 'artist') {
          widget.goRouter.go(AppStrings.musicGenresScreenRoute);
        } else {
          widget.goRouter.go(AppStrings.eventSpecializationScreenRoute);
        }
      } else if (userType == 'contractor') {
        widget.goRouter.go(AppStrings.welcomeScreenRoute);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipo de usuario no válido')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final titleFontSize = screenWidth * 0.06;
    final buttonFontSize = screenWidth * 0.045;
    final imageSize = screenWidth * 0.5; // círculo de imagen responsivo

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            AppStrings.profilePhoto,
            style: TextStyle(
              color: colorScheme[AppStrings.secondaryColor],
              fontWeight: FontWeight.bold,
              fontSize: titleFontSize,
            ),
          ),
        ),
        backgroundColor: colorScheme[AppStrings.primaryColor],
        iconTheme: IconThemeData(color: colorScheme[AppStrings.secondaryColor]),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.06),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppStrings.addProfilePhoto,
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.04),

              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  width: imageSize,
                  height: imageSize,
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
                                colorScheme[AppStrings.secondaryColor]!),
                          ),
                        )
                      : _profileImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                _profileImageUrl!,
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          colorScheme[AppStrings.secondaryColor]!),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: imageSize * 0.4,
                                    color: colorScheme[AppStrings.secondaryColor],
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.add_a_photo,
                              size: imageSize * 0.25,
                              color: colorScheme[AppStrings.secondaryColor],
                            ),
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

              if (_profileImageUrl != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onContinuePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme[AppStrings.essentialColor],
                      foregroundColor: colorScheme[AppStrings.primaryColor],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.04),
                      ),
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      elevation: 4,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppStrings.myContinue,
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.bold,
                          color: colorScheme[AppStrings.primaryColor],
                        ),
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