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


class VerificationSuccessScreen extends StatefulWidget {
  // Se puede pasar un deep link como parámetro (por ejemplo, desde un correo)
  final Uri? deepLinkUri;

  const VerificationSuccessScreen({Key? key, this.deepLinkUri})
    : super(key: key);

  @override
  _VerificationSuccessScreenState createState() =>
      _VerificationSuccessScreenState();
}

class _VerificationSuccessScreenState extends State<VerificationSuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Se obtiene la URI ya sea desde el deep link o desde la ruta actual
    final uri = widget.deepLinkUri ?? _getUriFromRoute();
    if (uri != null) {
      // Inicializa el usuario con la URI obtenida (asincrónicamente)
      Future.microtask(
        () => Provider.of<UserProvider>(context, listen: false).initialize(uri),
      );
    }
  }

  // Intenta recuperar la URI desde el nombre de la ruta actual
  Uri? _getUriFromRoute() {
    try {
      final route = ModalRoute.of(context)?.settings.name;
      return route != null ? Uri.tryParse(route) : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Devuelve directamente el contenido visual sin más lógica
    return const VerificationSuccessContent();
  }
}

// Contenido visual y funcional de la pantalla de verificación exitosa
class VerificationSuccessContent extends StatelessWidget {
  const VerificationSuccessContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se accede al UserProvider y colores personalizados
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = ColorPalette.getPalette(context);

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      body: Stack(
        children: [
          // Fondo con gradiente del color principal
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

          // Botón de regreso en la parte superior de la pantalla
          SafeArea(
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: colorScheme[AppStrings.secondaryColor],
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Contenido centrado con scroll para pantallas pequeñas
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono de éxito (círculo verde con check)
                  const Icon(Icons.check_circle, color: Colors.green, size: 80),
                  const SizedBox(height: 24),

                  // Título de éxito en la verificación
                  Text(
                    AppStrings.accountVerified,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme[AppStrings.secondaryColor],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Texto indicando que ahora puede continuar el registro
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

                  // Botón para continuar con el flujo de registro
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
                          // Marca el campo 'isVerified' como true en Firebase Firestore
                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser != null) {
                            // Obtiene el tipo de usuario (userType)
                            DocumentSnapshot userDoc =
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUser.uid)
                                    .get();

                            if (userDoc.exists) {
                              String userType = userDoc.get(
                                'userType',
                              ); // Asume que el campo se llama 'userType'

                              // Marca el campo 'isVerified' como true en Firestore
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser.uid)
                                  .set({
                                    'isVerified': true,
                                  }, SetOptions(merge: true));

                              // Marca también como verificado desde el provider
                              await userProvider.verifyEmail();

                              // Si el widget sigue montado, navega según el tipo de usuario
                              if (context.mounted) {
                                if (userType == 'artist') {
                                  context.go(
                                    AppStrings.ageTermsScreenRoute,
                                  ); // Navega a la pantalla de artista
                                } else if (userType == 'contractor') {
                                  context.go(
                                   AppStrings.ageTermsScreenRoute,
                                  ); // Navega a la pantalla de contractor
                                } else {
                                  // Puedes manejar el caso de un userType no reconocido, si es necesario
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Tipo de usuario no válido',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }
                            }
                          }
                        } catch (e) {
                          // Si hay un error, muestra un mensaje en pantalla
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