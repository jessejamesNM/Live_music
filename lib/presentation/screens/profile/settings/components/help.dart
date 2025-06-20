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
    // Obtención del tipo de usuario para determinar si es un artista o no
    final userType = userProvider.userType;
    final isArtist = userType == AppStrings.artist;

    // Definir la paleta de colores
    final colorScheme = ColorPalette.getPalette(context);

    // Obtener el usuario actual de Firebase
    final currentUser = FirebaseAuth.instance.currentUser;

    // Variable para almacenar la descripción del problema
    var problemDescription = "";

    // Instanciación del proveedor del perfil
    final ProfileProvider profileProvider = ProfileProvider();

    return Scaffold(
      // Fondo con color primario
      backgroundColor: colorScheme[AppStrings.primaryColor],

      // Barra de navegación inferior con configuración de navegación según tipo de usuario
      bottomNavigationBar: BottomNavigationBarWidget(
        goRouter: goRouter,
        isArtist: isArtist,
      ),

      // Cuerpo principal con padding y contenido organizado en columnas
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila con el botón de retroceso y el título de la pantalla
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                  onPressed: () {
                    context.pop();
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.help,
                  style: TextStyle(
                    fontSize: 25,
                    color: colorScheme[AppStrings.secondaryColor],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sección con el título de la descripción del problema
            Text(
              AppStrings.describeYourProblem,
              style: TextStyle(
                fontSize: 20,
                color: colorScheme[AppStrings.secondaryColor],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.describeProblemInstructions,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),

            // Campo de texto para ingresar la descripción del problema
            TextField(
              decoration: InputDecoration(
                hintText: AppStrings.writeProblemHere,
                hintStyle: TextStyle(
                  color: colorScheme[AppStrings.secondaryColor]?.withOpacity(
                    0.5,
                  ),
                ),
                filled: true,
                fillColor: colorScheme[AppStrings.primaryColor],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme[AppStrings.secondaryColor]!,
                    width: 1.5,
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
              style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
              maxLines: 4,
              onChanged:
                  (value) =>
                      problemDescription = value, // Actualiza la descripción
            ),
            const SizedBox(height: 24),

            // Botón de enviar la descripción
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Verifica si la descripción no está vacía y si hay un usuario autenticado
                  if (problemDescription.isNotEmpty && currentUser != null) {
                    // Envía la descripción al Firestore
                    profileProvider.sendProblemDescriptionToFirestore(
                      problemDescription,
                      currentUser.email ?? AppStrings.noEmail,
                      currentUser.displayName ?? AppStrings.anonymous,
                    );
                    // Muestra un mensaje de éxito
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppStrings.descriptionSent,
                          style: TextStyle(
                            color: colorScheme[AppStrings.primaryColor],
                          ),
                        ),
                        backgroundColor: colorScheme[AppStrings.secondaryColor],
                      ),
                    );
                    problemDescription =
                        ""; // Limpia la descripción después de enviarla
                  } else {
                    // Muestra un mensaje de error si la descripción está vacía
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppStrings.completeDescription,
                          style: TextStyle(
                            color: colorScheme[AppStrings.primaryColor],
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                ),
                child: Text(
                  AppStrings.sendDescription,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme[AppStrings.primaryColor],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Información de contacto alternativa
            Text(
              AppStrings.contactAlternative,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.supportPhoneNumber,
              style: TextStyle(
                fontSize: 18,
                color: colorScheme[AppStrings.secondaryColor],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
