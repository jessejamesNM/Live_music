// Fecha de creación: 2025-04-26
// Author: KingdomOfJames
//
// Descripción:
// Este widget muestra una pantalla de confirmación final antes de proceder con la eliminación de cuenta de un usuario.
// Se informa al usuario sobre las implicaciones de la eliminación y se le solicita confirmar la acción.
// Además, maneja la interacción con el `ProfileProvider` para guardar la solicitud de eliminación y realizar el cierre de sesión.
// Características:
// - Muestra una advertencia sobre la eliminación de cuenta.
// - Permite al usuario confirmar la eliminación de cuenta.
// - Se gestiona el estado de carga mientras se procesa la solicitud.
// - Muestra mensajes de error si la solicitud falla.
// - Proporciona un botón para confirmar la eliminación de la cuenta.
//
// Recomendaciones:
// - Se podría agregar una verificación adicional para asegurarse de que el usuario está seguro antes de continuar con la eliminación.
// - Es recomendable mostrar un mensaje de éxito o feedback después de que la eliminación se haya completado con éxito.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:live_music/data/provider_logics/nav_buttom_bar_components/profile/profile_provider.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import '../../../../../../data/provider_logics/user/user_provider.dart';
import '../../../../buttom_navigation_bar.dart';
import 'package:live_music/presentation/resources/colors.dart';
class FinalConfirmation extends HookWidget {
  final GoRouter goRouter;

  const FinalConfirmation({Key? key, required this.goRouter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final ProfileProvider profileProvider = ProfileProvider();
    final userType = userProvider.userType;
    final isArtist = userType == AppStrings.artist;
    final reason = userProvider.deletionRequest;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      bottomNavigationBar: BottomNavigationBarWidget(
        goRouter: goRouter,
        isArtist: isArtist,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botón para volver a la pantalla anterior
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                  onPressed: () {
                    try {
                      context.pop(); // Vuelve a la pantalla anterior
                    } catch (e) {
                      goRouter.go(
                        AppStrings.deleteAccountRoute,
                      ); // En caso de error, va a la ruta de eliminación
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Título de la pantalla
              Center(
                child: Text(
                  AppStrings.deleteTitle,
                  style: TextStyle(
                    fontSize: 25,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Advertencia sobre la eliminación de cuenta
              Container(
                width: double.infinity,
                child: Text(
                  AppStrings.deleteWarning,
                  style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 16),
              // Indicador de carga si está procesando la solicitud
              if (isLoading.value)
                CircularProgressIndicator(
                  color: colorScheme[AppStrings.essentialColor],
                ),
              // Mostrar mensaje de error si ocurre
              if (errorMessage.value != null)
                Text(
                  errorMessage.value!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              // Botón para confirmar la eliminación de la cuenta
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: colorScheme[AppStrings.essentialColor],
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  if (reason != null) {
                    isLoading.value = true;
                    errorMessage.value = null;

                    // Realiza la solicitud de eliminación
                    await profileProvider.saveDeletionRequest(
                      userId: currentUserId ?? '',
                      reason: reason,
                      currentDay: DateFormat(
                        AppStrings.dateFormat,
                      ).format(DateTime.now()),
                      eliminationDay: DateFormat(
                        AppStrings.dateFormat,
                      ).format(DateTime.now().add(const Duration(days: 30))),
                      onSuccess: () async {
                        isLoading.value = false;
                        // Cierra sesión y navega
                        await profileProvider.signOutAndNavigate(context);
                      },
                      onFailure: (message) {
                        isLoading.value = false;
                        errorMessage.value = message; // Muestra mensaje de error
                      },
                    );
                  } else {
                    errorMessage.value =
                        AppStrings
                            .deletionRequestError; // Error si no hay razón de eliminación
                  }
                },
                child: Text(AppStrings.deleteAccountButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}