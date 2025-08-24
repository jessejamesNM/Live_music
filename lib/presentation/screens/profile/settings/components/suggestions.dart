/*
 * Fecha de creación: 2025-04-26
 * Autor: KingdomOfJames
 * Descripción: Esta pantalla permite a los usuarios enviar sugerencias relacionadas con la aplicación. Dependiendo del tipo de usuario (artista o no), se muestra la interfaz correspondiente. El usuario puede ingresar sugerencias, que luego se envían a Firestore si se completan correctamente. La pantalla incluye un campo de texto para la sugerencia, un botón de envío y una barra de navegación en la parte inferior.
 * Características:
 * - Campo de texto para ingresar sugerencias.
 * - Validación de entrada antes de enviar la sugerencia.
 * - Retroalimentación visual con SnackBars.
 * - Barra de navegación personalizada según el tipo de usuario.
 * Recomendaciones:
 * - Asegúrese de que la conexión a Firebase esté correctamente configurada para enviar sugerencias.
 * - Verifique la validación de las sugerencias para evitar entradas vacías.
 */
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:live_music/presentation/resources/colors.dart';
import '../../../../../data/provider_logics/nav_buttom_bar_components/profile/profile_provider.dart';
import '../../../../../data/provider_logics/user/user_provider.dart';
import '../../../buttom_navigation_bar.dart';

class Suggestions extends StatelessWidget {
  final GoRouter goRouter;
  final UserProvider userProvider;

  const Suggestions({
    Key? key,
    required this.goRouter,
    required this.userProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final profileProvider = ProfileProvider();
    final currentUser = FirebaseAuth.instance.currentUser;
    var suggestionText = '';
    final userType = userProvider.userType;
    final isArtist = userType == AppStrings.artist;

    // Adaptativos según tamaño de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double iconSize = screenWidth * 0.08; // ~32 en 400px
    double titleFontSize = screenWidth * 0.06; // ~24 en 400px
    double sectionTitleFontSize = screenWidth * 0.052; // ~20 en 400px
    double descFontSize = screenWidth * 0.038; // ~15 en 400px
    double fieldFontSize = screenWidth * 0.045; // ~18 en 400px
    double buttonFontSize = screenWidth * 0.05; // ~20 en 400px
    double verticalSpacing = screenHeight * 0.02;
    double fieldBorderRadius = screenWidth * 0.03; // ~12 en 400px
    double buttonPadding = screenHeight * 0.02; // ~16 en 750px

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      bottomNavigationBar: BottomNavigationBarWidget(
        goRouter: goRouter,
        userType: userType,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04), // ~16 en 400px
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con botón de retroceso y título
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: colorScheme[AppStrings.secondaryColor],
                    size: iconSize,
                  ),
                  onPressed: () {
                    goRouter.pop();
                  },
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  AppStrings.suggestionsTitle,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    color: colorScheme[AppStrings.secondaryColor],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: verticalSpacing),
            // Título y descripción
            Text(
              AppStrings.feedbackTitle,
              style: TextStyle(
                fontSize: sectionTitleFontSize,
                color: colorScheme[AppStrings.secondaryColor],
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: verticalSpacing * 0.5),
            Text(
              AppStrings.feedbackDescription,
              style: TextStyle(
                fontSize: descFontSize,
                color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.7),
              ),
            ),
            SizedBox(height: verticalSpacing * 1.2),
            // Campo de texto para la sugerencia
            TextField(
              onChanged: (value) => suggestionText = value,
              decoration: InputDecoration(
                hintText: AppStrings.suggestionHint,
                hintStyle: TextStyle(
                  color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.5),
                  fontSize: fieldFontSize,
                ),
                filled: true,
                fillColor: colorScheme[AppStrings.primaryColor],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                  borderSide: BorderSide(
                    color: colorScheme[AppStrings.secondaryColor]!,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                  borderSide: BorderSide(
                    color: colorScheme[AppStrings.secondaryColor]!,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                  borderSide: BorderSide(
                    color: colorScheme[AppStrings.secondaryColor]!,
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.all(screenWidth * 0.04),
              ),
              style: TextStyle(
                fontSize: fieldFontSize,
                color: colorScheme[AppStrings.secondaryColor],
              ),
              maxLines: 4,
            ),
            SizedBox(height: verticalSpacing * 1.2),
            // Botón de envío
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (suggestionText.isNotEmpty && currentUser != null) {
                    profileProvider.sendSuggestionToFirestore(
                      suggestionText,
                      currentUser.email ?? AppStrings.noEmail,
                      currentUser.displayName ?? AppStrings.anonymous,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppStrings.suggestionSent,
                          style: TextStyle(
                            color: colorScheme[AppStrings.primaryColor],
                            fontSize: fieldFontSize,
                          ),
                        ),
                        backgroundColor: colorScheme[AppStrings.secondaryColor],
                      ),
                    );
                    suggestionText = '';
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppStrings.completeSuggestion,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fieldFontSize,
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
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                  ),
                  padding: EdgeInsets.symmetric(vertical: buttonPadding),
                  elevation: 4,
                ),
                child: Text(
                  AppStrings.sendButton,
                  style: TextStyle(
                    fontSize: buttonFontSize,
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