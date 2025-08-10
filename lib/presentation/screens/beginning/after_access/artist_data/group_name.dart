/// -----------------------------------------------------------------------------
/// Fecha de creación: 2025-04-22
/// Autor: KingdomOfJames
///
/// Descripción:
/// Pantalla destinada a capturar el nombre del grupo del usuario como parte del flujo de onboarding.
/// Valida en tiempo real la entrada del usuario y habilita el botón de continuar solo si el nombre es válido.
/// También ejecuta una verificación inicial de localización del usuario.
///
/// Recomendaciones:
/// - Mantener las validaciones sincronizadas con las reglas de negocio en `BeginningProvider`.
/// - Considerar deshabilitar el botón mientras se guarda el nombre para evitar múltiples envíos.
/// - Usar lógica de debounce si se piensa añadir validación asíncrona.
///
/// Características:
/// - Campo de texto con validación en vivo.
/// - Mensaje de error dinámico si el nombre es inválido.
/// - Uso de `HookWidget` para manejar estado reactivo de forma concisa.
/// - Botón de continuar que guarda el nombre y navega al siguiente paso.
/// - Integración con `ColorPalette` y `AppStrings` para consistencia visual y textual.
/// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../../data/provider_logics/beginning/beginning_provider.dart';
import '../../../../../data/provider_logics/user/user_provider.dart';
import 'package:live_music/presentation/resources/colors.dart';

class GroupNameScreen extends HookWidget {
  final GoRouter goRouter;

  GroupNameScreen({required this.goRouter});

  @override
  Widget build(BuildContext context) {
    final groupName = useState('');
    final errorMessage = useState('');

    final beginningProvider = Provider.of<BeginningProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    final colorScheme = ColorPalette.getPalette(context);

    // Determinar el texto según el tipo de usuario
    String getQuestionByUserType(String? userType) {
      switch (userType) {
        case 'artist':
          return '¿Cuál es el nombre del grupo?';
        case 'bakery':
        case 'decoration':
        case 'decorator':
          return '¿Cómo se llama tu negocio?';
        case 'place':
          return '¿Cómo se llama su local?';
        case 'furniture':
          return '¿Cómo se llama su negocio?';
        case 'entertainment':
          return '¿Cómo se llama su negocio?';
        case 'contractor':
          return '¿Cuál es su nombre?';
        default:
          return '¿Cuál es el nombre del grupo?';
      }
    }

    // Determinar la ruta siguiente según el tipo de usuario
    String getNextRouteByUserType(String? userType) {
      return userType == 'contractor'
          ? AppStrings.welcomeScreenRoute
          : AppStrings.profileImageScreenRoute;
    }

    final questionText = getQuestionByUserType(userProvider.userType);
    final nextRoute = getNextRouteByUserType(userProvider.userType);

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16.0),
        color: colorScheme[AppStrings.primaryColor],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              questionText,
              style: TextStyle(
                color: colorScheme[AppStrings.secondaryColor],
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),

            TextField(
              onChanged: (value) {
                groupName.value = value;
                errorMessage.value = beginningProvider.validateName(value);
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme[AppStrings.primaryColor],
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color:
                        colorScheme[AppStrings.secondaryColor] ?? Colors.grey,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color:
                        colorScheme[AppStrings.secondaryColor] ?? Colors.blue,
                    width: 2.0,
                  ),
                ),
                errorText:
                    errorMessage.value.isNotEmpty ? errorMessage.value : null,
                errorBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                hintText: AppStrings.groupName,
                hintStyle: TextStyle(
                  color: colorScheme[AppStrings.secondaryColor]?.withOpacity(
                    0.5,
                  ),
                ),
              ),
              style: TextStyle(
                color: colorScheme[AppStrings.secondaryColor],
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 16.0),

            if (groupName.value.isNotEmpty && errorMessage.value.isEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    beginningProvider.setRouteToGo(nextRoute);
                    beginningProvider.saveName(
                      groupName.value,
                      context,
                      goRouter,
                      AppStrings.nicknameScreenRoute,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme[AppStrings.essentialColor],
                    foregroundColor: colorScheme[AppStrings.primaryColor],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    elevation: 4.0,
                  ),
                  child: Text(
                    AppStrings.myContinue,
                    style: TextStyle(
                      color: colorScheme[AppStrings.primaryColor],
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
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
