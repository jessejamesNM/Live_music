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

// Pantalla para ingresar el nombre del grupo. Utiliza Flutter Hooks y Provider.
class GroupNameScreen extends HookWidget {
  final GoRouter goRouter;

  GroupNameScreen({required this.goRouter});

  @override
  Widget build(BuildContext context) {
    // Hook para almacenar el nombre del grupo que el usuario escribe.
    final groupName = useState('');

    // Hook para almacenar mensajes de error en la validación del nombre.
    final errorMessage = useState('');

    // Se obtienen instancias de los providers necesarios.
    final beginningProvider = Provider.of<BeginningProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    // Se obtiene el esquema de colores personalizado.
    final colorScheme = ColorPalette.getPalette(context);

    // Hook de efecto: se ejecuta una vez al iniciar la pantalla.
    // Verifica la ubicación del usuario como parte del flujo de inicio.
    useEffect(() {
   
      return;
    }, []);

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16.0),
        color: colorScheme[AppStrings.primaryColor],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Título de la pantalla (pregunta sobre el nombre del grupo).
            Text(
              AppStrings.groupNameQuestion,
              style: TextStyle(
                color: colorScheme[AppStrings.secondaryColor],
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),

            // Campo de texto para ingresar el nombre del grupo.
            TextField(
              onChanged: (value) {
                // Se actualiza el valor del nombre y se valida.
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

            // Botón "Continuar" solo se muestra si hay un nombre válido sin errores.
            if (groupName.value.isNotEmpty && errorMessage.value.isEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    beginningProvider.setRouteToGo(
                      AppStrings.profileImageScreenRoute,
                    );
                    // Guarda el nombre del grupo y navega al siguiente paso.
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
