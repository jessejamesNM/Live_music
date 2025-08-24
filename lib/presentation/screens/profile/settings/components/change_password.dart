// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
// Descripción: Esta pantalla permite al usuario cambiar su contraseña en la aplicación.
// El usuario debe ingresar su contraseña actual, una nueva y repetirla. Si la contraseña nueva cumple con los requisitos,
// el cambio se realiza correctamente, de lo contrario se muestran mensajes de error.
// Recomendaciones: Asegurarse de que el campo de la contraseña actual sea correcto antes de proceder con el cambio.
// También, que la nueva contraseña cumpla con los requisitos de seguridad establecidos (mayúsculas, minúsculas, números, caracteres especiales).
// Características: Verificación de la contraseña mediante expresión regular, visibilidad de las contraseñas,
// mensaje de confirmación de restablecimiento de contraseña y cambio de contraseña con retroalimentación al usuario.

// Importación de paquetes necesarios
import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:live_music/presentation/resources/colors.dart';
import '../../../../../data/provider_logics/nav_buttom_bar_components/profile/profile_provider.dart';
import '../../../../../data/provider_logics/user/user_provider.dart';
import '../../../buttom_navigation_bar.dart';

class ChangePassword extends StatelessWidget {
  final GoRouter goRouter;

  const ChangePassword({Key? key, required this.goRouter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final db = FirebaseFirestore.instance;
    final usersRef = db.collection("users");
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final userProvider = Provider.of<UserProvider>(context);
    final profileProvider = ProfileProvider();
    final userType = userProvider.userType;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      bottomNavigationBar: BottomNavigationBarWidget(
        goRouter: goRouter,
        userType: userType,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final widthFactor = constraints.maxWidth / 400;
            final heightFactor = constraints.maxHeight / 800;
            final scaleFactor = widthFactor < heightFactor ? widthFactor : heightFactor;

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 20 * scaleFactor, horizontal: 16 * scaleFactor),
              child: ChangePasswordContent(
                isArtist: userType == AppStrings.artist,
                usersRef: usersRef,
                currentUserId: currentUserId,
                userProvider: userProvider,
                profileProvider: profileProvider,
                scaleFactor: scaleFactor,
              ),
            );
          },
        ),
      ),
    );
  }
}

class ChangePasswordContent extends StatefulWidget {
  final bool isArtist;
  final CollectionReference usersRef;
  final String? currentUserId;
  final UserProvider userProvider;
  final ProfileProvider profileProvider;
  final double scaleFactor;

  const ChangePasswordContent({
    Key? key,
    required this.isArtist,
    required this.usersRef,
    required this.currentUserId,
    required this.userProvider,
    required this.profileProvider,
    required this.scaleFactor,
  }) : super(key: key);

  @override
  _ChangePasswordContentState createState() => _ChangePasswordContentState();
}

class _ChangePasswordContentState extends State<ChangePasswordContent> {
  String currentPassword = "";
  String newPassword = "";
  String repeatNewPassword = "";
  String? errorMessage;
  bool isCurrentPasswordVisible = false;
  bool isNewPasswordVisible = false;
  bool isRepeatPasswordVisible = false;
  String userEmail = "";
  bool showMessage = false;
  Color? colorMessage;

  bool isValidPassword(String password) {
    final passwordRegex =
        r"^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@\$!%*?&.,])[A-Za-z\d@\$!%*?&.,]{8,}$";
    return RegExp(passwordRegex).hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final scale = widget.scaleFactor;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header con icono de regresar y título
          SizedBox(
            height: 60 * scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: colorScheme[AppStrings.secondaryColor],
                      size: 30 * scale,
                    ),
                    onPressed: () => context.go(AppStrings.homeScreenRoute),
                  ),
                ),
                FittedBox(
                  child: Text(
                    AppStrings.changePassword,
                    style: TextStyle(
                      fontSize: 25 * scale,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16 * scale),
          FittedBox(
            child: Text(
              AppStrings.changePasswordInstructions,
              style: TextStyle(color: colorScheme[AppStrings.secondaryColor], fontSize: 16 * scale),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16 * scale),
          _buildPasswordField(
            label: AppStrings.currentPassword,
            value: currentPassword,
            onChanged: (value) => setState(() => currentPassword = value),
            isVisible: isCurrentPasswordVisible,
            onVisibilityChanged: () => setState(() => isCurrentPasswordVisible = !isCurrentPasswordVisible),
            colorScheme: colorScheme,
            scaleFactor: scale,
          ),
          SizedBox(height: 8 * scale),
          _buildPasswordField(
            label: AppStrings.newPassword,
            value: newPassword,
            onChanged: (value) => setState(() => newPassword = value),
            isVisible: isNewPasswordVisible,
            onVisibilityChanged: () => setState(() => isNewPasswordVisible = !isNewPasswordVisible),
            colorScheme: colorScheme,
            scaleFactor: scale,
          ),
          SizedBox(height: 8 * scale),
          _buildPasswordField(
            label: AppStrings.repeatNewPassword,
            value: repeatNewPassword,
            onChanged: (value) => setState(() => repeatNewPassword = value),
            isVisible: isRepeatPasswordVisible,
            onVisibilityChanged: () => setState(() => isRepeatPasswordVisible = !isRepeatPasswordVisible),
            colorScheme: colorScheme,
            scaleFactor: scale,
          ),
          SizedBox(height: 16 * scale),
          if (widget.currentUserId != null)
            FutureBuilder<DocumentSnapshot>(
              future: widget.usersRef.doc(widget.currentUserId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  userEmail = snapshot.data!['email'];
                }
                return Container();
              },
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                widget.profileProvider.sendPasswordResetEmail(userEmail);
                setState(() => showMessage = true);
              },
              child: FittedBox(
                child: Text(
                  AppStrings.forgotPassword,
                  style: TextStyle(color: colorScheme[AppStrings.secondaryColor], fontSize: 16 * scale),
                ),
              ),
            ),
          ),
          if (showMessage)
            FutureBuilder(
              future: Future.delayed(Duration(seconds: 3)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  setState(() => showMessage = false);
                }
                return _buildMessageCard(colorScheme, scale);
              },
            ),
          if (errorMessage != null && colorMessage != null)
            Column(
              children: [
                FittedBox(
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: colorMessage, fontSize: 16 * scale),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 8 * scale),
              ],
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: colorScheme[AppStrings.essentialColor],
                padding: EdgeInsets.symmetric(vertical: 12 * scale),
              ),
              onPressed: () {
                if (newPassword != repeatNewPassword) {
                  setState(() {
                    errorMessage = AppStrings.passwordsDontMatch;
                    colorMessage = Colors.red;
                  });
                  return;
                }
                if (!isValidPassword(newPassword)) {
                  setState(() {
                    errorMessage = AppStrings.passwordRequirements;
                    colorMessage = Colors.red;
                  });
                  return;
                }
                widget.profileProvider.changePassword(
                  currentPassword,
                  newPassword,
                  (success, message) {
                    setState(() {
                      if (success) {
                        errorMessage = AppStrings.passwordChangedSuccessfully;
                        currentPassword = "";
                        newPassword = "";
                        repeatNewPassword = "";
                        colorMessage = Colors.green;
                      } else {
                        errorMessage = message;
                        colorMessage = Colors.red;
                      }
                    });
                  },
                );
              },
              child: FittedBox(
                child: Text(
                  AppStrings.changePasswordButton,
                  style: TextStyle(fontSize: 16 * scale, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    required bool isVisible,
    required VoidCallback onVisibilityChanged,
    required Map<String, Color> colorScheme,
    required double scaleFactor,
  }) {
    return TextField(
      obscureText: !isVisible,
      style: TextStyle(color: colorScheme[AppStrings.secondaryColor], fontSize: 16 * scaleFactor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorScheme[AppStrings.secondaryColor], fontSize: 16 * scaleFactor),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: colorScheme[AppStrings.essentialColor],
            size: 24 * scaleFactor,
          ),
          onPressed: onVisibilityChanged,
        ),
        border: OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme[AppStrings.secondaryColor]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme[AppStrings.essentialColor]!),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildMessageCard(Map<String, Color> colorScheme, double scale) {
    return Card(
      elevation: 4,
      color: colorScheme[AppStrings.primaryColor],
      child: Padding(
        padding: EdgeInsets.all(16 * scale),
        child: Row(
          children: [
            Expanded(
              child: FittedBox(
                child: Text(
                  AppStrings.passwordResetSent,
                  style: TextStyle(color: colorScheme[AppStrings.secondaryColor], fontSize: 16 * scale),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: colorScheme[AppStrings.essentialColor],
                size: 24 * scale,
              ),
              onPressed: () => setState(() => showMessage = false),
            ),
          ],
        ),
      ),
    );
  }
}