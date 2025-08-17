// -----------------------------------------------------------------------------
// Archivo: username_screen.dart
// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
//
// Descripción:
// Pantalla para que el usuario cree su nombre de usuario al iniciar la app.
// Se usa Flutter Hooks para manejar estados locales y Provider para acceder
// a lógica de negocio como validaciones y navegación.
//
// Características:
// - Ingreso y validación de nombre de usuario en tiempo real.
// - Botón de continuar habilitado solo si el nombre es válido.
// - Estilos dinámicos basados en el tema de colores de la app.
//
// Recomendaciones:
// - Agregar un indicador de carga si la validación o guardado toma tiempo.
// - Validar que el nombre de usuario sea único en el servidor (actualmente
//   solo se hace validación de formato).
// - Mejorar accesibilidad (por ejemplo, agregar soporte para lectores de pantalla).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/data/provider_logics/beginning/beginning_provider.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';

class UsernameScreen extends HookWidget {
  final GoRouter goRouter;

  UsernameScreen({required this.goRouter});

  @override
  Widget build(BuildContext context) {
    // Hook para manejar el valor del nombre de usuario localmente
    final username = useState('');
    // Hook para manejar el mensaje de error
    final errorMessage = useState('');

    // Acceso a los providers necesarios
    final beginningProvider = Provider.of<BeginningProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    // Acceso a la paleta de colores de la app
    final colorScheme = ColorPalette.getPalette(context);

    // Efecto que se ejecuta una sola vez: verifica la localización del usuario
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
            // Título principal de la pantalla
            Text(
              AppStrings.createUsernameTitle,
              style: TextStyle(
                color: colorScheme[AppStrings.secondaryColor],
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),

            // Campo de texto para ingresar el nombre de usuario
            TextField(
              onChanged: (value) {
                // Actualiza el nombre de usuario ingresado
                username.value = value;
                // Valida en tiempo real el nombre ingresado
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
                hintText: AppStrings.usernameHint,
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

            // Botón de continuar, visible solo si no hay errores
            if (username.value.isNotEmpty && errorMessage.value.isEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Guarda la ruta a la que se debe redirigir en caso necesario
                    beginningProvider.setRouteToGo(
                      AppStrings.welcomeScreenRoute,
                    );

                    // Guarda el nombre de usuario y avanza a la siguiente pantalla
                    beginningProvider.saveName(
                      username.value,
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
