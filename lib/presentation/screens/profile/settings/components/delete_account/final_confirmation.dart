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
        userType: userType,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final widthFactor = constraints.maxWidth / 400;
            final heightFactor = constraints.maxHeight / 800;
            final scale = widthFactor < heightFactor ? widthFactor : heightFactor;

            return SingleChildScrollView(
              padding: EdgeInsets.all(16 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botón de retroceso
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: colorScheme[AppStrings.secondaryColor],
                        size: 28 * scale,
                      ),
                      onPressed: () {
                        try {
                          context.pop();
                        } catch (e) {
                          goRouter.go(AppStrings.deleteAccountRoute);
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  // Título centrado
                  Center(
                    child: FittedBox(
                      child: Text(
                        AppStrings.deleteTitle,
                        style: TextStyle(
                          fontSize: 25 * scale,
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  // Advertencia sobre eliminación
                  Container(
                    width: double.infinity,
                    child: Text(
                      AppStrings.deleteWarning,
                      style: TextStyle(
                        fontSize: 14 * scale,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  // Indicador de carga
                  if (isLoading.value)
                    Center(
                      child: CircularProgressIndicator(
                        color: colorScheme[AppStrings.essentialColor],
                      ),
                    ),
                  if (errorMessage.value != null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8 * scale),
                      child: Text(
                        errorMessage.value!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14 * scale,
                        ),
                      ),
                    ),
                  SizedBox(height: 16 * scale),
                  // Botón de confirmar eliminación
                  SizedBox(
                    width: double.infinity,
                    height: 50 * scale,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme[AppStrings.essentialColor],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (reason != null) {
                          isLoading.value = true;
                          errorMessage.value = null;

                          await profileProvider.saveDeletionRequest(
                            userId: currentUserId ?? '',
                            reason: reason,
                            currentDay: DateFormat(AppStrings.dateFormat)
                                .format(DateTime.now()),
                            eliminationDay: DateFormat(AppStrings.dateFormat)
                                .format(DateTime.now().add(Duration(days: 30))),
                            onSuccess: () async {
                              isLoading.value = false;
                              await profileProvider.signOutAndNavigate(context);
                            },
                            onFailure: (message) {
                              isLoading.value = false;
                              errorMessage.value = message;
                            },
                          );
                        } else {
                          errorMessage.value = AppStrings.deletionRequestError;
                        }
                      },
                      child: FittedBox(
                        child: Text(
                          AppStrings.deleteAccountButton,
                          style: TextStyle(
                            fontSize: 16 * scale,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}