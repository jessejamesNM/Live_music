// Fecha de creación: 2025-04-26
// Autor: KingdomOfJames
//
// Descripción: Pantalla de configuración de cuenta de usuario, donde se puede editar el nombre de usuario,
// visualizar la dirección de correo electrónico, cambiar la contraseña, eliminar la cuenta o cerrar sesión.
// También incluye un botón para guardar los cambios en el nombre de usuario, si es necesario.
// Se implementa con Firebase Authentication y Firestore para gestionar la información del usuario.
//
// Recomendaciones:
// - Asegúrate de tener configurado Firebase en tu proyecto.
// - Es importante manejar correctamente los errores en los cambios de datos para una mejor experiencia de usuario.
// - El límite de modificación de nombre es de 14 días entre cambios, lo cual está implementado en la lógica.
//
// Características:
// - Modificación de nombre de usuario, con restricción de 14 días entre cambios.
// - Visualización de email del usuario, pero no editable.
// - Opción para cerrar sesión, eliminar cuenta o cambiar contraseña.
// - Funciones que interactúan con Firebase para obtener y actualizar los datos del usuario.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:live_music/presentation/resources/strings.dart';
import '../../../buttom_navigation_bar.dart';

class MyAccountScreen extends StatefulWidget {
  final GoRouter goRouter;
  final UserProvider userProvider;

  const MyAccountScreen({
    Key? key,
    required this.goRouter,
    required this.userProvider,
  }) : super(key: key);

  @override
  _MyAccountScreenState createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  late String _userName = '';
  late String _initialName = '';
  bool _isNameEditable = false;
  bool _showSaveButton = false;
  String _errorMessage = '';
  DateTime _lastModifiedDate = DateTime(0);
  bool _isSaving = false;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc['name'] ?? '';
            _initialName = _userName;
            _userEmail = userDoc['email'] ?? '';
            if (userDoc.data()?.containsKey('nameModified') ?? false) {
              _lastModifiedDate =
                  (userDoc['nameModified'] as Timestamp?)?.toDate() ??
                  DateTime(0);
            } else {
              _lastModifiedDate = DateTime(0);
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${AppStrings.loadDataError} ${e.toString()}';
      });
    }
  }

  Future<void> _saveChanges() async {
    final now = DateTime.now();
    final differenceInDays = now.difference(_lastModifiedDate).inDays;

    if (differenceInDays < 14) {
      setState(() {
        _errorMessage = AppStrings.nameChangeLimit.replaceFirst(
          '%d',
          (14 - differenceInDays).toString(),
        );
      });
    } else {
      setState(() => _isSaving = true);
      try {
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          await _firestore.collection('users').doc(currentUser.uid).update({
            'name': _userName,
            'nameModified': now,
          });
          setState(() {
            _lastModifiedDate = now;
            _initialName = _userName;
            _showSaveButton = false;
            _isNameEditable = false;
            _errorMessage = '';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = '${AppStrings.saveChangesError} ${e.toString()}';
        });
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userType = widget.userProvider.userType;
    final isArtist = userType == AppStrings.artist;
    final colors = ColorPalette.getPalette(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final inputDecoration = InputDecoration(
      labelStyle: TextStyle(color: colors[AppStrings.secondaryColor]),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: colors[AppStrings.secondaryColor]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: colors[AppStrings.secondaryColorLittleDark]!,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors[AppStrings.secondaryColor]!),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: colors[AppStrings.secondaryColorLittleDark]!,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: colors[AppStrings.primaryColor],
      bottomNavigationBar: BottomNavigationBarWidget(
        goRouter: widget.goRouter,
        userType: userType,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: screenHeight * 0.08,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: colors[AppStrings.secondaryColor],
                          size: screenWidth * 0.08,
                        ),
                        onPressed: () {
                          widget.goRouter.pop();
                        },
                      ),
                    ),
                    Center(
                      child: Text(
                        AppStrings.myAccountTitle,
                        style: TextStyle(
                          color: colors[AppStrings.secondaryColor],
                          fontSize: screenWidth * 0.07,
                          fontFamily: 'CustomFont',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                AppStrings.informationSection,
                style: TextStyle(
                  color: colors[AppStrings.secondaryColor],
                  fontSize: screenWidth * 0.06,
                  fontFamily: 'CustomFont',
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              TextField(
                decoration: inputDecoration.copyWith(
                  labelText: AppStrings.nameLabel,
                  enabled: _isNameEditable,
                ),
                style: TextStyle(color: colors[AppStrings.secondaryColor]),
                controller: TextEditingController(text: _userName),
                onChanged: (newName) {
                  setState(() {
                    _userName = newName;
                    _showSaveButton = newName != _initialName;
                  });
                },
              ),
              SizedBox(height: screenHeight * 0.02),
              TextField(
                decoration: inputDecoration.copyWith(
                  labelText: AppStrings.emailLabel,
                ),
                style: TextStyle(color: colors[AppStrings.secondaryColor]),
                controller: TextEditingController(text: _userEmail),
                enabled: false,
              ),
              SizedBox(height: screenHeight * 0.01),
              if (_showSaveButton)
                Center(
                  child: CustomElevatedButton(
                    text:
                        _isSaving
                            ? AppStrings.savingChanges
                            : AppStrings.saveChanges,
                    onPressed:
                        _isSaving || _userName.isEmpty ? null : _saveChanges,
                    colors: colors,
                  ),
                ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.005),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: colors[AppStrings.redColor],
                      fontSize: 15,
                    ),
                  ),
                ),
              SizedBox(height: screenHeight * 0.005),
              Center(
                child: CustomElevatedButton(
                  text:
                      _isNameEditable ? AppStrings.cancel : AppStrings.editName,
                  onPressed: () {
                    setState(() {
                      _isNameEditable = !_isNameEditable;
                      _userName = _initialName;
                      _showSaveButton = false;
                    });
                  },
                  colors: colors,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              // Texto "Opciones" alineado a la izquierda
              Text(
                AppStrings.optionsSection,
                style: TextStyle(
                  color: colors[AppStrings.secondaryColor],
                  fontSize: screenWidth * 0.06,
                  fontFamily: 'CustomFont',
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              // Botones centrados debajo del texto alineado a la izquierda
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AccountOptionButton(
                      label: AppStrings.changePassword,
                      onTap:
                          () => widget.goRouter.go(
                            AppStrings.changePasswordRoute,
                          ),
                      colors: colors,
                      screenHeight: screenHeight,
                      screenWidth: screenWidth,
                    ),
                    Divider(
                      color: colors[AppStrings.selectedButtonColor],
                      thickness: 0.63,
                    ),
                    AccountOptionButton(
                      label: AppStrings.deleteAccount,
                      onTap:
                          () =>
                              widget.goRouter.go(AppStrings.deleteAccountRoute),
                      colors: colors,
                      screenHeight: screenHeight,
                      screenWidth: screenWidth,
                    ),
                    Divider(
                      color: colors[AppStrings.selectedButtonColor],
                      thickness: 0.63,
                    ),
                    AccountOptionButton(
                      label: AppStrings.logOut,
                      onTap: () async {
                        await _auth.signOut();
                        await _googleSignIn.signOut();
                        widget.goRouter.go(AppStrings.selectionScreenRoute);
                      },
                      colors: colors,
                      screenHeight: screenHeight,
                      screenWidth: screenWidth,
                      isDestructive: true,
                    ),
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

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Map<String, Color?> colors;

  const CustomElevatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors[AppStrings.primaryColorLight],
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(color: colors[AppStrings.secondaryColor]),
        ),
      ),
    );
  }
}

class AccountOptionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Map<String, Color?> colors;
  final double screenHeight;
  final double screenWidth;
  final bool isDestructive;

  const AccountOptionButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.colors,
    required this.screenHeight,
    required this.screenWidth,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color:
                    isDestructive
                        ? colors[AppStrings.redColor]
                        : colors[AppStrings.secondaryColor],
                fontSize: screenWidth * 0.05,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
