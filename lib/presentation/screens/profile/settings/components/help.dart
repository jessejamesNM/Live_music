// Fecha de creación: 26 de abril de 2025
// Autor: KingdomOfJames
// Descripción: Esta pantalla está diseñada para permitir a los usuarios describir un problema o incidencia que estén enfrentando. Está orientada a artistas y usuarios generales, y facilita el envío de la descripción del problema a Firebase para su posterior revisión. La interfaz incluye un campo de texto para ingresar la descripción y un botón para enviar la información.
// Recomendaciones: Es importante manejar adecuadamente los estados de los botones y los mensajes de error. Asegúrate de que el diseño sea accesible y funcional en diferentes tamaños de pantalla.
// Características:
// - Campo para ingresar la descripción del problema
// - Botón de envío que valida si el campo está vacío
// - Mensajes de retroalimentación al usuario
// - Navegación a la pantalla anterior con un botón de retroceso
// - Estilos personalizables usando el esquema de colores

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:live_music/presentation/resources/colors.dart';
import '../../../../../data/provider_logics/nav_buttom_bar_components/profile/profile_provider.dart';
import '../../../../../data/provider_logics/user/user_provider.dart';
import '../../../buttom_navigation_bar.dart';

class Help extends StatelessWidget {
  final GoRouter goRouter;
  final UserProvider userProvider;

  const Help({Key? key, required this.goRouter, required this.userProvider})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userType = userProvider.userType;
    final isArtist = userType == AppStrings.artist;

    final colorScheme = ColorPalette.getPalette(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    var problemDescription = "";
    final ProfileProvider profileProvider = ProfileProvider();

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      bottomNavigationBar: BottomNavigationBarWidget(
        goRouter: goRouter,
        userType: userType,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final widthFactor = constraints.maxWidth / 400; // base width
          final heightFactor = constraints.maxHeight / 800; // base height
          final scaleFactor = widthFactor < heightFactor ? widthFactor : heightFactor;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16 * scaleFactor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: colorScheme[AppStrings.secondaryColor],
                        size: 24 * scaleFactor,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    SizedBox(width: 8 * scaleFactor),
                    Flexible(
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppStrings.help,
                          style: TextStyle(
                            fontSize: 25 * scaleFactor,
                            color: colorScheme[AppStrings.secondaryColor],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16 * scaleFactor),
                FittedBox(
                  child: Text(
                    AppStrings.describeYourProblem,
                    style: TextStyle(
                      fontSize: 20 * scaleFactor,
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                  ),
                ),
                SizedBox(height: 8 * scaleFactor),
                FittedBox(
                  child: Text(
                    AppStrings.describeProblemInstructions,
                    style: TextStyle(
                      fontSize: 14 * scaleFactor,
                      color: colorScheme[AppStrings.secondaryColor]
                          ?.withOpacity(0.7),
                    ),
                  ),
                ),
                SizedBox(height: 24 * scaleFactor),
                TextField(
                  decoration: InputDecoration(
                    hintText: AppStrings.writeProblemHere,
                    hintStyle: TextStyle(
                      color: colorScheme[AppStrings.secondaryColor]
                          ?.withOpacity(0.5),
                      fontSize: 14 * scaleFactor,
                    ),
                    filled: true,
                    fillColor: colorScheme[AppStrings.primaryColor],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12 * scaleFactor),
                      borderSide: BorderSide(
                        color: colorScheme[AppStrings.secondaryColor]!,
                        width: 1.5 * scaleFactor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12 * scaleFactor),
                      borderSide: BorderSide(
                        color: colorScheme[AppStrings.secondaryColor]!,
                        width: 1.5 * scaleFactor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12 * scaleFactor),
                      borderSide: BorderSide(
                        color: colorScheme[AppStrings.secondaryColor]!,
                        width: 1.5 * scaleFactor,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                    fontSize: 16 * scaleFactor,
                  ),
                  maxLines: 4,
                  onChanged: (value) => problemDescription = value,
                ),
                SizedBox(height: 24 * scaleFactor),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (problemDescription.isNotEmpty && currentUser != null) {
                        profileProvider.sendProblemDescriptionToFirestore(
                          problemDescription,
                          currentUser.email ?? AppStrings.noEmail,
                          currentUser.displayName ?? AppStrings.anonymous,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppStrings.descriptionSent,
                              style: TextStyle(
                                color: colorScheme[AppStrings.primaryColor],
                                fontSize: 14 * scaleFactor,
                              ),
                            ),
                            backgroundColor: colorScheme[AppStrings.secondaryColor],
                          ),
                        );
                        problemDescription = "";
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppStrings.completeDescription,
                              style: TextStyle(
                                color: colorScheme[AppStrings.primaryColor],
                                fontSize: 14 * scaleFactor,
                              ),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme[AppStrings.essentialColor],
                      foregroundColor: colorScheme[AppStrings.primaryColor],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 16 * scaleFactor,
                      ),
                      elevation: 4,
                    ),
                    child: FittedBox(
                      child: Text(
                        AppStrings.sendDescription,
                        style: TextStyle(
                          fontSize: 16 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: colorScheme[AppStrings.primaryColor],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32 * scaleFactor),
                FittedBox(
                  child: Text(
                    AppStrings.contactAlternative,
                    style: TextStyle(
                      fontSize: 16 * scaleFactor,
                      color: colorScheme[AppStrings.secondaryColor]
                          ?.withOpacity(0.7),
                    ),
                  ),
                ),
                SizedBox(height: 8 * scaleFactor),
                FittedBox(
                  child: Text(
                    AppStrings.supportPhoneNumber,
                    style: TextStyle(
                      fontSize: 18 * scaleFactor,
                      color: colorScheme[AppStrings.secondaryColor],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}