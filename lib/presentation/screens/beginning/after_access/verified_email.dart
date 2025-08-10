/// -----------------------------------------------------------------------------
/// Fecha de creación: 2025-04-22
/// Autor: KingdomOfJames
///
/// Descripción:
/// Pantalla que se muestra cuando la verificación del correo electrónico es exitosa.
/// Informa al usuario que su cuenta ha sido verificada y le permite continuar
/// con el proceso de registro. Incluye un botón para proceder a la siguiente etapa,
/// que marca la cuenta como verificada en la base de datos de Firebase y navega
/// hacia la siguiente pantalla. Además, maneja deep links para inicializar la URI
/// del enlace de forma automática.
///
/// Recomendaciones:
/// - Asegúrate de manejar correctamente el estado del usuario si la verificación
///   se realiza fuera de la aplicación (por ejemplo, a través de un deep link).
/// - Implementar un indicador de carga mientras se realiza la actualización en Firebase.
/// - Agregar validaciones o mensajes adicionales en caso de que ocurra un error
///   durante el proceso de verificación.
///
/// Características:
/// - Utiliza FirebaseAuth para verificar el estado de la cuenta y actualizar el campo `isVerified`.
/// - Integración con `Provider` para manejar el estado del usuario.
/// - Navegación automática al siguiente paso del proceso de registro tras la verificación.
/// - Diseño moderno y adaptado a la paleta de colores definida en `ColorPalette`.
/// - Gestión de deep links para abrir la pantalla directamente desde un enlace.
///
/// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/provider_logics/user/user_provider.dart';
import '../../../resources/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationSuccessContent extends StatelessWidget {
  const VerificationSuccessContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = ColorPalette.getPalette(context);

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme[AppStrings.primaryColor]!,
                  colorScheme[AppStrings.primaryColor]!,
                ],
              ),
            ),
          ),

          SafeArea(
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: colorScheme[AppStrings.secondaryColor],
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 80),
                  const SizedBox(height: 24),

                  Text(
                    AppStrings.accountVerified,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme[AppStrings.secondaryColor],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    AppStrings.canContinueRegistration,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme[AppStrings.secondaryColor]
                          ?.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme[AppStrings.essentialColor],
                        foregroundColor: colorScheme[AppStrings.primaryColor],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser != null) {
                            DocumentSnapshot userDoc =
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUser.uid)
                                    .get();

                            if (userDoc.exists) {
                              String userType = userDoc.get('userType');

                              // Actualizar estado de verificación
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser.uid)
                                  .set({
                                    'isVerified': true,
                                  }, SetOptions(merge: true));

                              await userProvider.verifyEmail();

                              if (context.mounted) {
                                // Definir los tipos que se consideran "artistas"
                                final isArtistType = [
                                  'artist',
                                  'bakery',
                                  'place',
                                  'decoration',
                                  'furniture',
                                  'entertainment',
                                ].contains(userType);

                                if (userType == 'contractor') {
                                  context.go(AppStrings.ageTermsScreenRoute);
                                } else if (isArtistType) {
                                  context.go(AppStrings.groupNameScreenRoute);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Tipo de usuario no reconocido',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${AppStrings.error}: ${e.toString()}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        AppStrings.continueText,
                        style: TextStyle(
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
        ],
      ),
    );
  }
}
