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
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtiene los colores del tema
    final profileProvider =
        ProfileProvider(); // Instancia del proveedor para interactuar con el perfil del usuario
    final currentUser =
        FirebaseAuth
            .instance
            .currentUser; // Obtiene el usuario actual de Firebase
    var suggestionText =
        ''; // Variable para almacenar el texto de la sugerencia
    final userType =
        userProvider.userType; // Obtiene el tipo de usuario (Artista o no)
    final isArtist =
        userType == AppStrings.artist; // Verifica si el usuario es artista

    return Scaffold(
      backgroundColor:
          colorScheme[AppStrings.primaryColor], // Fondo con el color primario
      bottomNavigationBar: BottomNavigationBarWidget(
        goRouter: goRouter,
        isArtist: isArtist,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Padding para la pantalla
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start, // Alineación de los elementos en la columna
          children: [
            // Cabecera con botón de retroceso y título
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color:
                        colorScheme[AppStrings
                            .secondaryColor], // Color del ícono
                  ),
                  onPressed: () {
                    goRouter
                        .pop(); // Navega hacia atrás cuando se presiona el botón
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.suggestionsTitle, // Título de la pantalla
                  style: TextStyle(
                    fontSize: 25,
                    color:
                        colorScheme[AppStrings
                            .secondaryColor], // Color del texto
                    fontWeight: FontWeight.bold, // Estilo del texto
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Espacio entre elementos
            // Título y descripción
            Text(
              AppStrings.feedbackTitle, // Título de la sección de sugerencias
              style: TextStyle(
                fontSize: 20,
                color:
                    colorScheme[AppStrings.secondaryColor], // Color del texto
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings
                  .feedbackDescription, // Descripción de la sección de sugerencias
              style: TextStyle(
                fontSize: 15,
                color: colorScheme[AppStrings.secondaryColor]?.withOpacity(
                  0.7,
                ), // Color del texto con opacidad
              ),
            ),
            const SizedBox(height: 24), // Espacio entre elementos
            // Campo de texto para la sugerencia
            TextField(
              onChanged:
                  (value) =>
                      suggestionText =
                          value, // Actualiza el texto de la sugerencia
              decoration: InputDecoration(
                hintText: AppStrings.suggestionHint, // Texto de sugerencia
                hintStyle: TextStyle(
                  color: colorScheme[AppStrings.secondaryColor]?.withOpacity(
                    0.5,
                  ), // Color del texto del hint
                ),
                filled: true,
                fillColor:
                    colorScheme[AppStrings.primaryColor], // Color de fondo
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // Bordes redondeados
                  borderSide: BorderSide(
                    color:
                        colorScheme[AppStrings
                            .secondaryColor]!, // Color del borde
                    width: 1.5, // Ancho del borde
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme[AppStrings.secondaryColor]!,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme[AppStrings.secondaryColor]!,
                    width: 1.5,
                  ),
                ),
              ),
              style: TextStyle(
                color: colorScheme[AppStrings.secondaryColor],
              ), // Estilo del texto
              maxLines: 4, // Permite múltiples líneas
            ),
            const SizedBox(height: 24), // Espacio entre elementos
            // Botón de envío
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Lógica para enviar la sugerencia
                  if (suggestionText.isNotEmpty && currentUser != null) {
                    profileProvider.sendSuggestionToFirestore(
                      suggestionText, // Texto de la sugerencia
                      currentUser.email ??
                          AppStrings.noEmail, // Correo del usuario
                      currentUser.displayName ??
                          AppStrings.anonymous, // Nombre del usuario
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppStrings.suggestionSent, // Mensaje de éxito
                          style: TextStyle(
                            color:
                                colorScheme[AppStrings
                                    .primaryColor], // Color del texto
                          ),
                        ),
                        backgroundColor:
                            colorScheme[AppStrings
                                .secondaryColor], // Color de fondo del Snackbar
                      ),
                    );
                    suggestionText = ''; // Limpia el campo de texto
                  } else {
                    // Si la sugerencia está vacía o el usuario no está autenticado
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          AppStrings.completeSuggestion, // Mensaje de error
                          style: TextStyle(
                            color: Colors.white,
                          ), // Color del texto
                        ),
                        backgroundColor:
                            Colors.red, // Color de fondo del Snackbar de error
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      colorScheme[AppStrings
                          .essentialColor], // Color de fondo del botón
                  foregroundColor:
                      colorScheme[AppStrings
                          .primaryColor], // Color del texto del botón
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // Bordes redondeados del botón
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ), // Padding dentro del botón
                  elevation: 4, // Elevación para darle sombra
                ),
                child: Text(
                  AppStrings.sendButton, // Texto del botón
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold, // Estilo del texto
                    color:
                        colorScheme[AppStrings.primaryColor], // Color del texto
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
